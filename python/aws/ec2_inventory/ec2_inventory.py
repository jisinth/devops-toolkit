#!/usr/bin/env python3
"""
ec2_inventory.py - List EC2 instances (id, Name tag, type, state, AZ,
private/public IP) across one or more AWS regions.

Authenticates via boto3's default credential chain (environment variables,
shared config/credentials file, or an IAM role) - no credentials are read
from the command line or hardcoded.
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
    "InstanceId",
    "Name",
    "InstanceType",
    "State",
    "AvailabilityZone",
    "PrivateIpAddress",
    "PublicIpAddress",
]


def get_name_tag(tags):
    """Return the value of the 'Name' tag, or '' if absent. tags may be None."""
    for tag in tags or []:
        if tag.get("Key") == "Name":
            return tag.get("Value", "")
    return ""


def extract_instance_row(instance, region):
    """Turn one EC2 describe_instances 'Instances' entry into a flat dict row."""
    return {
        "Region": region,
        "InstanceId": instance.get("InstanceId", ""),
        "Name": get_name_tag(instance.get("Tags")),
        "InstanceType": instance.get("InstanceType", ""),
        "State": instance.get("State", {}).get("Name", ""),
        "AvailabilityZone": instance.get("Placement", {}).get("AvailabilityZone", ""),
        "PrivateIpAddress": instance.get("PrivateIpAddress", ""),
        "PublicIpAddress": instance.get("PublicIpAddress", ""),
    }


def collect_instances(ec2_client, region):
    """Page through describe_instances and return a flat list of instance rows."""
    rows = []
    paginator = ec2_client.get_paginator("describe_instances")
    for page in paginator.paginate():
        for reservation in page.get("Reservations", []):
            for instance in reservation.get("Instances", []):
                rows.append(extract_instance_row(instance, region))
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
            "List EC2 instances (id, Name tag, type, state, AZ, private/public IP) "
            "across one or more AWS regions."
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
            client = boto3.client("ec2", region_name=region)
            all_rows.extend(collect_instances(client, region))

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
        if code in ("AccessDenied", "AccessDeniedException", "UnauthorizedOperation"):
            print(
                f"ERROR: Access denied ({code}). Ensure the caller has "
                "ec2:DescribeInstances permission.",
                file=sys.stderr,
            )
        else:
            print(f"ERROR: AWS API error: {e}", file=sys.stderr)
        return 1
    except BotoCoreError as e:
        print(f"ERROR: {e}", file=sys.stderr)
        return 1

    rows_as_lists = [[r[f] for f in FIELDNAMES] for r in all_rows]
    print_table(FIELDNAMES, rows_as_lists)
    write_outputs(all_rows, FIELDNAMES, args.outputs)
    return 0


if __name__ == "__main__":
    sys.exit(main())
