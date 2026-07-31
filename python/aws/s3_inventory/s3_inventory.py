#!/usr/bin/env python3
"""
s3_inventory.py - List S3 buckets with region, approximate size & object
count, and public-access-block status.

By default, size/object count come from CloudWatch daily bucket metrics
(fast, no bucket scan). Pass --deep to compute exact totals via a real
list_objects_v2 walk instead (slower, more accurate, costs API calls).

Authenticates via boto3's default credential chain - no credentials are
read from the command line or hardcoded.
"""
import argparse
import csv
import datetime
import json
import sys

import boto3
from botocore.exceptions import BotoCoreError, ClientError, NoCredentialsError

FIELDNAMES = [
    "Bucket",
    "Region",
    "SizeBytes",
    "SizeHuman",
    "ObjectCount",
    "PublicAccessBlock",
]


def format_size(num_bytes):
    """Human-readable byte size, e.g. 1536 -> '1.5 KB'."""
    if num_bytes is None:
        return "unknown"
    size = float(num_bytes)
    for unit in ("B", "KB", "MB", "GB", "TB", "PB"):
        if size < 1024.0 or unit == "PB":
            return f"{size:.1f} {unit}" if unit != "B" else f"{int(size)} {unit}"
        size /= 1024.0
    return f"{size:.1f} PB"


def summarize_public_access_block(config):
    """
    config is the 'PublicAccessBlockConfiguration' dict (or None if the
    bucket has no block configured / call failed). Returns a short label.
    """
    if not config:
        return "Not configured"
    keys = (
        "BlockPublicAcls",
        "IgnorePublicAcls",
        "BlockPublicPolicy",
        "RestrictPublicBuckets",
    )
    values = [bool(config.get(k)) for k in keys]
    if all(values):
        return "Fully blocked"
    if any(values):
        return "Partially blocked"
    return "Not blocked"


def get_bucket_region(s3_client, bucket_name):
    resp = s3_client.get_bucket_location(Bucket=bucket_name)
    location = resp.get("LocationConstraint")
    # AWS quirk: us-east-1 is returned as None/empty.
    return location or "us-east-1"


def get_public_access_block_status(s3_client, bucket_name):
    try:
        resp = s3_client.get_public_access_block(Bucket=bucket_name)
        return summarize_public_access_block(
            resp.get("PublicAccessBlockConfiguration")
        )
    except ClientError as e:
        code = e.response.get("Error", {}).get("Code", "")
        if code in ("NoSuchPublicAccessBlockConfiguration",):
            return "Not configured"
        return "Unknown"


def get_size_from_cloudwatch(cw_client, bucket_name, region, storage_type, metric_name):
    """Fetch the most recent CloudWatch S3 storage-metrics datapoint."""
    now = datetime.datetime.now(datetime.timezone.utc)
    resp = cw_client.get_metric_statistics(
        Namespace="AWS/S3",
        MetricName=metric_name,
        Dimensions=[
            {"Name": "BucketName", "Value": bucket_name},
            {"Name": "StorageType", "Value": storage_type},
        ],
        StartTime=now - datetime.timedelta(days=2),
        EndTime=now,
        Period=86400,
        Statistics=["Average"],
    )
    datapoints = resp.get("Datapoints", [])
    if not datapoints:
        return None
    latest = max(datapoints, key=lambda d: d["Timestamp"])
    return latest["Average"]


def deep_count_bucket(s3_client, bucket_name):
    """Walk the bucket with list_objects_v2 and sum exact size/object count."""
    total_size = 0
    total_count = 0
    paginator = s3_client.get_paginator("list_objects_v2")
    for page in paginator.paginate(Bucket=bucket_name):
        for obj in page.get("Contents", []):
            total_size += obj.get("Size", 0)
            total_count += 1
    return total_size, total_count


def build_bucket_row(bucket_name, region, size_bytes, object_count, access_block_status):
    return {
        "Bucket": bucket_name,
        "Region": region,
        "SizeBytes": int(size_bytes) if size_bytes is not None else "",
        "SizeHuman": format_size(size_bytes),
        "ObjectCount": int(object_count) if object_count is not None else "",
        "PublicAccessBlock": access_block_status,
    }


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
            "List S3 buckets with region, approximate size & object count, "
            "and public-access-block status."
        )
    )
    parser.add_argument(
        "--region",
        dest="region",
        metavar="REGION",
        help="Region to use for the S3 control-plane client (bucket listing "
        "itself is global). Defaults to the current profile/session region.",
    )
    parser.add_argument(
        "--deep",
        action="store_true",
        help="Compute exact size/object count via list_objects_v2 instead of "
        "reading CloudWatch bucket metrics. Slower, costs more API calls.",
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


def main(argv=None):
    args = parse_args(argv)

    try:
        session = boto3.Session(region_name=args.region)
        s3_client = session.client("s3")

        buckets = s3_client.list_buckets().get("Buckets", [])
        rows = []
        for bucket in buckets:
            name = bucket["Name"]
            try:
                region = get_bucket_region(s3_client, name)
            except ClientError:
                region = "unknown"

            access_status = get_public_access_block_status(s3_client, name)

            if args.deep:
                regional_client = session.client("s3", region_name=region)
                size_bytes, object_count = deep_count_bucket(regional_client, name)
            else:
                cw_client = session.client(
                    "cloudwatch", region_name=region if region != "unknown" else None
                )
                size_bytes = get_size_from_cloudwatch(
                    cw_client, name, region, "StandardStorage", "BucketSizeBytes"
                )
                object_count = get_size_from_cloudwatch(
                    cw_client, name, region, "AllStorageTypes", "NumberOfObjects"
                )

            rows.append(build_bucket_row(name, region, size_bytes, object_count, access_status))

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
                "s3:ListAllMyBuckets, s3:GetBucketLocation, "
                "s3:GetBucketPublicAccessBlock, cloudwatch:GetMetricStatistics "
                "(and s3:ListBucket for --deep) permissions.",
                file=sys.stderr,
            )
        else:
            print(f"ERROR: AWS API error: {e}", file=sys.stderr)
        return 1
    except BotoCoreError as e:
        print(f"ERROR: {e}", file=sys.stderr)
        return 1

    rows_as_lists = [[r[f] for f in FIELDNAMES] for r in rows]
    print_table(FIELDNAMES, rows_as_lists)
    write_outputs(rows, FIELDNAMES, args.outputs)
    return 0


if __name__ == "__main__":
    sys.exit(main())
