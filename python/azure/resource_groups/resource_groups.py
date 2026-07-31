#!/usr/bin/env python3
"""
resource_groups.py - List resource groups and a count of resources in
each (--detailed also breaks the count down by resource type).

Authenticates via azure-identity's DefaultAzureCredential. The
subscription is taken from --subscription-id, or falls back to the
AZURE_SUBSCRIPTION_ID environment variable.
"""
import argparse
import csv
import json
import os
import sys
from collections import Counter

from azure.core.exceptions import ClientAuthenticationError, HttpResponseError
from azure.identity import DefaultAzureCredential
from azure.mgmt.resource import ResourceManagementClient

FIELDNAMES = ["Name", "Location", "ResourceCount"]
DETAILED_FIELDNAMES = ["Name", "Location", "ResourceType", "Count"]


def count_resources_by_type(resource_client, resource_group_name):
    """Return a Counter of resource_type -> count for one resource group."""
    counts = Counter()
    for res in resource_client.resources.list_by_resource_group(resource_group_name):
        counts[res.type or "Unknown"] += 1
    return counts


def collect_resource_groups(resource_client, detailed=False):
    """List resource groups with a resource count (or a per-type breakdown)."""
    summary_rows = []
    detail_rows = []
    for rg in resource_client.resource_groups.list():
        counts = count_resources_by_type(resource_client, rg.name)
        total = sum(counts.values())
        summary_rows.append({"Name": rg.name, "Location": rg.location, "ResourceCount": total})
        if detailed:
            if counts:
                for rtype, count in sorted(counts.items()):
                    detail_rows.append(
                        {"Name": rg.name, "Location": rg.location, "ResourceType": rtype, "Count": count}
                    )
            else:
                detail_rows.append(
                    {"Name": rg.name, "Location": rg.location, "ResourceType": "(none)", "Count": 0}
                )
    return summary_rows, detail_rows


def print_table(headers, rows):
    if not rows:
        print("No results found.")
        return
    widths = [len(h) for h in headers]
    for row in rows:
        for i, cell in enumerate(row):
            widths[i] = max(widths[i], len(str(cell)))
    fmt = "  ".join("{:<%d}" % w for w in widths)
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
        description="List resource groups and a count of resources in each."
    )
    parser.add_argument(
        "--subscription-id",
        help="Azure subscription ID. Defaults to the AZURE_SUBSCRIPTION_ID environment variable.",
    )
    parser.add_argument(
        "--detailed",
        action="store_true",
        help="Also break the resource count down by resource type per group.",
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


def resolve_subscription_id(explicit):
    return explicit or os.environ.get("AZURE_SUBSCRIPTION_ID")


def main(argv=None):
    args = parse_args(argv)

    subscription_id = resolve_subscription_id(args.subscription_id)
    if not subscription_id:
        print(
            "ERROR: No subscription ID given. Pass --subscription-id or set "
            "AZURE_SUBSCRIPTION_ID.",
            file=sys.stderr,
        )
        return 1

    try:
        credential = DefaultAzureCredential()
        client = ResourceManagementClient(credential, subscription_id)
        summary_rows, detail_rows = collect_resource_groups(client, detailed=args.detailed)
    except ClientAuthenticationError as e:
        print(
            f"ERROR: Azure authentication failed: {e}. Run `az login`, or "
            "configure a service principal / managed identity.",
            file=sys.stderr,
        )
        return 1
    except HttpResponseError as e:
        print(f"ERROR: Azure API error: {e.message if hasattr(e, 'message') else e}", file=sys.stderr)
        return 1

    rows_as_lists = [[r[f] for f in FIELDNAMES] for r in summary_rows]
    print_table(FIELDNAMES, rows_as_lists)
    write_outputs(summary_rows, FIELDNAMES, args.outputs)

    if args.detailed:
        print()
        print("Resource type breakdown:")
        detail_rows_as_lists = [[r[f] for f in DETAILED_FIELDNAMES] for r in detail_rows]
        print_table(DETAILED_FIELDNAMES, detail_rows_as_lists)

    return 0


if __name__ == "__main__":
    sys.exit(main())
