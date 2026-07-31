#!/usr/bin/env python3
"""
ebs_snapshot.py - List EBS volumes and their existing snapshots, flag
unattached ('available' state) volumes, and optionally create a new
snapshot of a given volume.

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

VOLUME_FIELDNAMES = [
    "Region",
    "VolumeId",
    "State",
    "SizeGiB",
    "VolumeType",
    "AvailabilityZone",
    "Unattached",
    "SnapshotCount",
]

SNAPSHOT_FIELDNAMES = [
    "Region",
    "VolumeId",
    "SnapshotId",
    "State",
    "StartTime",
    "Progress",
    "Description",
]


def is_unattached(volume):
    """A volume with no attachments is in the 'available' state."""
    return volume.get("State") == "available"


def extract_volume_row(volume, region, snapshot_count=0):
    return {
        "Region": region,
        "VolumeId": volume.get("VolumeId", ""),
        "State": volume.get("State", ""),
        "SizeGiB": volume.get("Size", ""),
        "VolumeType": volume.get("VolumeType", ""),
        "AvailabilityZone": volume.get("AvailabilityZone", ""),
        "Unattached": is_unattached(volume),
        "SnapshotCount": snapshot_count,
    }


def extract_snapshot_row(snapshot, region):
    return {
        "Region": region,
        "VolumeId": snapshot.get("VolumeId", ""),
        "SnapshotId": snapshot.get("SnapshotId", ""),
        "State": snapshot.get("State", ""),
        "StartTime": snapshot.get("StartTime", ""),
        "Progress": snapshot.get("Progress", ""),
        "Description": snapshot.get("Description", ""),
    }


def group_snapshots_by_volume(snapshot_rows):
    """Return {volume_id: [snapshot_row, ...]}."""
    grouped = {}
    for row in snapshot_rows:
        grouped.setdefault(row["VolumeId"], []).append(row)
    return grouped


def filter_unattached(volume_rows):
    return [v for v in volume_rows if v["Unattached"]]


def collect_volumes(ec2_client, region):
    rows = []
    paginator = ec2_client.get_paginator("describe_volumes")
    for page in paginator.paginate():
        for volume in page.get("Volumes", []):
            rows.append(extract_volume_row(volume, region))
    return rows


def collect_snapshots(ec2_client, region):
    """Only snapshots owned by the calling account, to avoid scanning public ones."""
    rows = []
    paginator = ec2_client.get_paginator("describe_snapshots")
    for page in paginator.paginate(OwnerIds=["self"]):
        for snapshot in page.get("Snapshots", []):
            rows.append(extract_snapshot_row(snapshot, region))
    return rows


def create_snapshot(ec2_client, volume_id, description=None):
    kwargs = {"VolumeId": volume_id}
    if description:
        kwargs["Description"] = description
    resp = ec2_client.create_snapshot(**kwargs)
    return resp


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


def write_json(path, data):
    with open(path, "w", encoding="utf-8") as f:
        json.dump(data, f, indent=2, default=str)


def write_csv(path, fieldnames, rows):
    with open(path, "w", encoding="utf-8", newline="") as f:
        writer = csv.DictWriter(f, fieldnames=fieldnames)
        writer.writeheader()
        writer.writerows(rows)


def write_outputs(data, fieldnames, output_paths):
    for path in output_paths or []:
        lower = path.lower()
        if lower.endswith(".json"):
            write_json(path, data)
            print(f"Wrote {path}")
        elif lower.endswith(".csv"):
            write_csv(path, fieldnames, data)
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
            "List EBS volumes and their existing snapshots, flag unattached "
            "volumes, and optionally create a new snapshot."
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
        "--create",
        metavar="VOLUME_ID",
        help="Create a new snapshot of the given volume ID. Uses the first "
        "--region given (or the default region) as the target region.",
    )
    parser.add_argument(
        "--description",
        metavar="TEXT",
        help="Description to attach to the snapshot created with --create.",
    )
    parser.add_argument(
        "--unattached-only",
        action="store_true",
        help="Only list volumes that are unattached (state 'available').",
    )
    parser.add_argument(
        "--output",
        action="append",
        dest="outputs",
        metavar="FILE",
        help="Write the volume list to FILE. Extension (.json or .csv) "
        "selects the format. Repeat to write multiple files.",
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

        if args.create:
            client = boto3.client("ec2", region_name=regions[0])
            resp = create_snapshot(client, args.create, args.description)
            print(
                f"Created snapshot {resp.get('SnapshotId')} of volume "
                f"{args.create} in {regions[0]} (state: {resp.get('State')})"
            )
            return 0

        all_volume_rows = []
        all_snapshot_rows = []
        for region in regions:
            client = boto3.client("ec2", region_name=region)
            volume_rows = collect_volumes(client, region)
            snapshot_rows = collect_snapshots(client, region)
            grouped = group_snapshots_by_volume(snapshot_rows)
            for v in volume_rows:
                v["SnapshotCount"] = len(grouped.get(v["VolumeId"], []))
            all_volume_rows.extend(volume_rows)
            all_snapshot_rows.extend(snapshot_rows)

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
                "ec2:DescribeVolumes, ec2:DescribeSnapshots, and (for --create) "
                "ec2:CreateSnapshot permission.",
                file=sys.stderr,
            )
        elif code == "InvalidVolume.NotFound":
            print(f"ERROR: Volume not found: {e}", file=sys.stderr)
        else:
            print(f"ERROR: AWS API error: {e}", file=sys.stderr)
        return 1
    except BotoCoreError as e:
        print(f"ERROR: {e}", file=sys.stderr)
        return 1

    if args.unattached_only:
        all_volume_rows = filter_unattached(all_volume_rows)

    rows_as_lists = [[r[f] for f in VOLUME_FIELDNAMES] for r in all_volume_rows]
    print_table(VOLUME_FIELDNAMES, rows_as_lists)

    unattached_count = sum(1 for r in all_volume_rows if r["Unattached"])
    if unattached_count:
        print(f"\n{unattached_count} unattached (available) volume(s) found.")

    write_outputs(all_volume_rows, VOLUME_FIELDNAMES, args.outputs)
    return 0


if __name__ == "__main__":
    sys.exit(main())
