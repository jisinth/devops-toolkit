#!/usr/bin/env python3
"""
cost_report.py - Cost Explorer monthly cost summary grouped by service for
a date range (default: current month-to-date).

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
from botocore.exceptions import BotoCoreError, ClientError, NoCredentialsError

FIELDNAMES = ["Service", "Amount", "Unit"]


def month_to_date_range(today=None):
    """Return (start, end) ISO date strings for the current month-to-date."""
    today = today or datetime.datetime.now(tz=datetime.timezone.utc).date()
    start = today.replace(day=1)
    return start.isoformat(), today.isoformat()


def extract_service_rows(cost_and_usage_response):
    """Flatten a get_cost_and_usage response (grouped by service) into rows."""
    rows = []
    for result in cost_and_usage_response.get("ResultsByTime", []):
        for group in result.get("Groups", []):
            service = group.get("Keys", ["Unknown"])[0]
            amount_block = group.get("Metrics", {}).get("UnblendedCost", {})
            rows.append(
                {
                    "Service": service,
                    "Amount": amount_block.get("Amount", "0"),
                    "Unit": amount_block.get("Unit", ""),
                }
            )
    return rows


def merge_service_rows(rows):
    """Sum Amount per Service across multiple time periods into one row each."""
    totals = {}
    unit_by_service = {}
    for row in rows:
        service = row["Service"]
        totals[service] = totals.get(service, 0.0) + float(row["Amount"] or 0)
        unit_by_service[service] = row["Unit"]
    merged = [
        {"Service": service, "Amount": f"{amount:.2f}", "Unit": unit_by_service[service]}
        for service, amount in totals.items()
    ]
    merged.sort(key=lambda r: float(r["Amount"]), reverse=True)
    return merged


def collect_costs(ce_client, start, end):
    response = ce_client.get_cost_and_usage(
        TimePeriod={"Start": start, "End": end},
        Granularity="MONTHLY",
        Metrics=["UnblendedCost"],
        GroupBy=[{"Type": "DIMENSION", "Key": "SERVICE"}],
    )
    rows = extract_service_rows(response)
    return merge_service_rows(rows)


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
        description="Report AWS cost grouped by service, via Cost Explorer, for a date range."
    )
    parser.add_argument("--start", help="Start date (YYYY-MM-DD). Defaults to the 1st of the current month.")
    parser.add_argument("--end", help="End date (YYYY-MM-DD), exclusive. Defaults to today.")
    parser.add_argument(
        "--output",
        action="append",
        dest="outputs",
        metavar="FILE",
        help="Write results to FILE. Extension (.json or .csv) selects the "
        "format. Repeat to write multiple files.",
    )
    return parser.parse_args(argv)


def main(argv=None):
    args = parse_args(argv)

    default_start, default_end = month_to_date_range()
    start = args.start or default_start
    end = args.end or default_end

    try:
        # Cost Explorer is a global service reachable via us-east-1.
        client = boto3.client("ce", region_name="us-east-1")
        rows = collect_costs(client, start, end)

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
                "ce:GetCostAndUsage permission.",
                file=sys.stderr,
            )
        else:
            print(f"ERROR: AWS API error: {e}", file=sys.stderr)
        return 1
    except BotoCoreError as e:
        print(f"ERROR: {e}", file=sys.stderr)
        return 1

    print(f"Cost by service, {start} to {end}:")
    rows_as_lists = [[r[f] for f in FIELDNAMES] for r in rows]
    print_table(FIELDNAMES, rows_as_lists)
    write_outputs(rows, FIELDNAMES, args.outputs)
    return 0


if __name__ == "__main__":
    sys.exit(main())
