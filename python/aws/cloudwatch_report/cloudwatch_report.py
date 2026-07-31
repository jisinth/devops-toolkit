#!/usr/bin/env python3
"""
cloudwatch_report.py - Report CloudWatch alarm states (OK/ALARM/
INSUFFICIENT_DATA), optionally with recent datapoints for a specific
metric.

Authenticates via boto3's default credential chain (environment variables,
shared config/credentials file, or an IAM role) - no credentials are read
from the command line or hardcoded.
"""
import argparse
import csv
import datetime
import json
import sys

import boto3
from botocore.exceptions import (
    BotoCoreError,
    ClientError,
    NoCredentialsError,
    NoRegionError,
)

ALARM_FIELDNAMES = ["AlarmName", "StateValue", "MetricName", "Namespace", "StateUpdatedTimestamp"]
DATAPOINT_FIELDNAMES = ["Timestamp", "Average", "Minimum", "Maximum", "Sum", "Unit"]


def extract_alarm_row(alarm):
    """Turn one describe_alarms 'MetricAlarms' entry into a flat dict row."""
    return {
        "AlarmName": alarm.get("AlarmName", ""),
        "StateValue": alarm.get("StateValue", ""),
        "MetricName": alarm.get("MetricName", ""),
        "Namespace": alarm.get("Namespace", ""),
        "StateUpdatedTimestamp": str(alarm.get("StateUpdatedTimestamp", "")),
    }


def collect_alarms(cw_client, state_filter=None):
    """Page through describe_alarms and return a flat list of alarm rows."""
    rows = []
    kwargs = {}
    if state_filter:
        kwargs["StateValue"] = state_filter
    paginator = cw_client.get_paginator("describe_alarms")
    for page in paginator.paginate(**kwargs):
        for alarm in page.get("MetricAlarms", []):
            rows.append(extract_alarm_row(alarm))
    return rows


def collect_datapoints(cw_client, namespace, metric_name, hours):
    """Fetch recent Average/Minimum/Maximum/Sum datapoints for one metric."""
    end = datetime.datetime.now(datetime.timezone.utc)
    start = end - datetime.timedelta(hours=hours)
    response = cw_client.get_metric_statistics(
        Namespace=namespace,
        MetricName=metric_name,
        StartTime=start,
        EndTime=end,
        Period=300,
        Statistics=["Average", "Minimum", "Maximum", "Sum"],
    )
    datapoints = sorted(response.get("Datapoints", []), key=lambda d: d["Timestamp"])
    rows = []
    for dp in datapoints:
        rows.append(
            {
                "Timestamp": str(dp.get("Timestamp", "")),
                "Average": dp.get("Average", ""),
                "Minimum": dp.get("Minimum", ""),
                "Maximum": dp.get("Maximum", ""),
                "Sum": dp.get("Sum", ""),
                "Unit": dp.get("Unit", ""),
            }
        )
    return rows


def print_table(headers, rows):
    if not rows:
        print("No results found.")
        return
    widths = [len(h) for h in headers]
    for row in rows:
        for i, cell in enumerate(row):
            widths[i] = max(widths[i], len(str(cell)))
    fmt = "  ".join(f"{{:<{w}}}" for w in widths)
    print(fmt.format(*headers))
    print(fmt.format(*("-" * w for w in widths)))
    for row in rows:
        print(fmt.format(*(str(c) for c in row)))


def write_json(path, rows):
    with open(path, "w", encoding="utf-8") as f:
        json.dump(rows, f, indent=2, default=str)


def write_csv(path, fieldnames, rows):
    with open(path, "w", encoding="utf-8", newline="") as f:
        writer = csv.DictWriter(f, fieldnames=fieldnames)
        writer.writeheader()
        writer.writerows(rows)


def write_outputs(rows, fieldnames, output_paths):
    for path in output_paths or []:
        lower = path.lower()
        if lower.endswith(".json"):
            write_json(path, rows)
            print(f"Wrote {path}")
        elif lower.endswith(".csv"):
            write_csv(path, fieldnames, rows)
            print(f"Wrote {path}")
        else:
            print(
                f"WARNING: unrecognized output extension for '{path}' "
                "(use .json or .csv), skipping",
                file=sys.stderr,
            )


def parse_args(argv=None):
    parser = argparse.ArgumentParser(
        description=(
            "Report CloudWatch alarm states, optionally with recent datapoints "
            "for a specific metric."
        )
    )
    parser.add_argument("--region", help="AWS region to inspect. Defaults to the configured profile/session region.")
    parser.add_argument(
        "--state",
        choices=["OK", "ALARM", "INSUFFICIENT_DATA"],
        help="Only report alarms in this state (default: all states).",
    )
    parser.add_argument("--namespace", help="CloudWatch namespace to pull datapoints from, e.g. AWS/EC2.")
    parser.add_argument("--metric-name", help="Metric name to pull datapoints for (requires --namespace).")
    parser.add_argument(
        "--hours",
        type=int,
        default=3,
        help="How many hours of recent datapoints to fetch (default: 3).",
    )
    parser.add_argument(
        "--output",
        action="append",
        dest="outputs",
        metavar="FILE",
        help="Write results to FILE. Extension (.json or .csv) selects the "
        "format. Repeat to write multiple files.",
    )
    args = parser.parse_args(argv)
    if args.metric_name and not args.namespace:
        parser.error("--metric-name requires --namespace")
    return args


def main(argv=None):
    args = parse_args(argv)

    try:
        client = boto3.client("cloudwatch", region_name=args.region)

        alarm_rows = collect_alarms(client, state_filter=args.state)
        rows_as_lists = [[r[f] for f in ALARM_FIELDNAMES] for r in alarm_rows]
        print_table(ALARM_FIELDNAMES, rows_as_lists)
        write_outputs(alarm_rows, ALARM_FIELDNAMES, args.outputs)

        if args.namespace and args.metric_name:
            print()
            print(f"Recent datapoints for {args.namespace} / {args.metric_name} (last {args.hours}h):")
            dp_rows = collect_datapoints(client, args.namespace, args.metric_name, args.hours)
            dp_rows_as_lists = [[r[f] for f in DATAPOINT_FIELDNAMES] for r in dp_rows]
            print_table(DATAPOINT_FIELDNAMES, dp_rows_as_lists)

    except NoRegionError:
        print(
            "ERROR: No AWS region configured. Pass --region or set AWS_DEFAULT_REGION.",
            file=sys.stderr,
        )
        return 1
    except NoCredentialsError:
        print(
            "ERROR: No AWS credentials found. Configure credentials via "
            "`aws configure`, environment variables, or an IAM role.",
            file=sys.stderr,
        )
        return 1
    except ClientError as e:
        code = e.response.get("Error", {}).get("Code", "Unknown")
        if code in ("AccessDenied", "AccessDeniedException"):
            print(
                f"ERROR: Access denied ({code}). Ensure the caller has "
                "cloudwatch:DescribeAlarms / cloudwatch:GetMetricStatistics permission.",
                file=sys.stderr,
            )
        else:
            print(f"ERROR: AWS API error: {e}", file=sys.stderr)
        return 1
    except BotoCoreError as e:
        print(f"ERROR: {e}", file=sys.stderr)
        return 1

    return 0


if __name__ == "__main__":
    sys.exit(main())
