#!/usr/bin/env python3
"""
rds_report.py - List RDS instances: identifier, engine, engine version,
instance class, status, Multi-AZ, allocated storage.

Authenticates via boto3's default credential chain - no credentials are
read from the command line or hardcoded.
"""
import argparse
import csv
import json
import sys

import boto3
from botocore.exceptions import (
    BotoCoreError,
    ClientError,
    NoCredentialsError,
    NoRegionError,
)

FIELDNAMES = [
    "Region",
    "DBInstanceIdentifier",
    "Engine",
    "EngineVersion",
    "DBInstanceClass",
    "DBInstanceStatus",
    "MultiAZ",
    "AllocatedStorageGB",
]


def extract_db_instance_row(db_instance, region):
    """Turn one RDS describe_db_instances entry into a flat dict row."""
    return {
        "Region": region,
        "DBInstanceIdentifier": db_instance.get("DBInstanceIdentifier", ""),
        "Engine": db_instance.get("Engine", ""),
        "EngineVersion": db_instance.get("EngineVersion", ""),
        "DBInstanceClass": db_instance.get("DBInstanceClass", ""),
        "DBInstanceStatus": db_instance.get("DBInstanceStatus", ""),
        "MultiAZ": bool(db_instance.get("MultiAZ", False)),
        "AllocatedStorageGB": db_instance.get("AllocatedStorage", ""),
    }


def collect_db_instances(rds_client, region):
    """Page through describe_db_instances and return a flat list of rows."""
    rows = []
    paginator = rds_client.get_paginator("describe_db_instances")
    for page in paginator.paginate():
        for db_instance in page.get("DBInstances", []):
            rows.append(extract_db_instance_row(db_instance, region))
    return rows


def filter_non_multi_az(rows):
    """Return only rows where MultiAZ is False - useful for HA audits."""
    return [r for r in rows if not r["MultiAZ"]]


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
            "List RDS instances: identifier, engine, engine version, "
            "instance class, status, Multi-AZ, allocated storage."
        )
    )
    parser.add_argument(
        "--region",
        action="append",
        dest="regions",
        metavar="REGION",
        help="AWS region to inspect. Repeat for multiple regions. "
        "Defaults to the region configured in the current AWS profile/session.",
    )
    parser.add_argument(
        "--non-multi-az-only",
        action="store_true",
        help="Only show instances that are NOT configured for Multi-AZ.",
    )
    parser.add_argument(
        "--output",
        action="append",
        dest="outputs",
        metavar="FILE",
        help="Write results to FILE. Extension (.json or .csv) selects the "
        "format. Repeat to write multiple files.",
    )
    return parser.parse_args(argv)


def resolve_regions(regions):
    if regions:
        return regions
    session = boto3.Session()
    if session.region_name:
        return [session.region_name]
    return []


def main(argv=None):
    args = parse_args(argv)

    try:
        regions = resolve_regions(args.regions)
        if not regions:
            print(
                "ERROR: No region specified and no default region configured. "
                "Pass --region or set AWS_DEFAULT_REGION / a profile region.",
                file=sys.stderr,
            )
            return 1

        all_rows = []
        for region in regions:
            client = boto3.client("rds", region_name=region)
            all_rows.extend(collect_db_instances(client, region))

    except NoRegionError:
        print(
            "ERROR: No AWS region configured. Pass --region or set "
            "AWS_DEFAULT_REGION.",
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
                "rds:DescribeDBInstances permission.",
                file=sys.stderr,
            )
        else:
            print(f"ERROR: AWS API error: {e}", file=sys.stderr)
        return 1
    except BotoCoreError as e:
        print(f"ERROR: {e}", file=sys.stderr)
        return 1

    if args.non_multi_az_only:
        all_rows = filter_non_multi_az(all_rows)

    rows_as_lists = [[r[f] for f in FIELDNAMES] for r in all_rows]
    print_table(FIELDNAMES, rows_as_lists)
    write_outputs(all_rows, FIELDNAMES, args.outputs)
    return 0


if __name__ == "__main__":
    sys.exit(main())
