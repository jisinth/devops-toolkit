#!/usr/bin/env python3
"""
storage_report.py - List storage accounts and their containers with
approximate usage and access tier.

Authenticates via azure-identity's DefaultAzureCredential. The
subscription is taken from --subscription-id, or falls back to the
AZURE_SUBSCRIPTION_ID environment variable.

Container listing uses the ARM (management-plane) blob_containers API, so
no separate data-plane storage credential/key is required.
"""
import argparse
import csv
import json
import os
import sys

from azure.core.exceptions import ClientAuthenticationError, HttpResponseError
from azure.identity import DefaultAzureCredential
from azure.mgmt.storage import StorageManagementClient

ACCOUNT_FIELDNAMES = ["Name", "ResourceGroup", "Location", "Sku", "Kind", "AccessTier"]
CONTAINER_FIELDNAMES = ["Account", "Container", "PublicAccess", "LastModifiedTime"]


def resource_group_from_id(resource_id):
    parts = resource_id.split("/")
    try:
        return parts[parts.index("resourceGroups") + 1]
    except (ValueError, IndexError):
        return ""


def extract_account_row(account):
    """Turn one StorageAccount into a flat dict row."""
    return {
        "Name": account.name,
        "ResourceGroup": resource_group_from_id(account.id),
        "Location": account.location,
        "Sku": getattr(account.sku, "name", "") if account.sku else "",
        "Kind": str(getattr(account, "kind", "") or ""),
        "AccessTier": str(getattr(account, "access_tier", "") or ""),
    }


def collect_accounts(storage_client):
    return [extract_account_row(a) for a in storage_client.storage_accounts.list()]


def collect_containers(storage_client, account_row):
    """List containers for one storage account via the ARM blob_containers API."""
    rows = []
    try:
        containers = storage_client.blob_containers.list(
            account_row["ResourceGroup"], account_row["Name"]
        )
        for c in containers:
            rows.append(
                {
                    "Account": account_row["Name"],
                    "Container": c.name,
                    "PublicAccess": str(getattr(c, "public_access", "") or "None"),
                    "LastModifiedTime": str(getattr(c, "last_modified_time", "") or ""),
                }
            )
    except HttpResponseError as e:
        print(
            f"WARNING: could not list containers for '{account_row['Name']}': {e.message if hasattr(e, 'message') else e}",
            file=sys.stderr,
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
        description="List storage accounts and their containers with access tier."
    )
    parser.add_argument(
        "--subscription-id",
        help="Azure subscription ID. Defaults to the AZURE_SUBSCRIPTION_ID environment variable.",
    )
    parser.add_argument(
        "--skip-containers",
        action="store_true",
        help="Only report storage accounts, skip listing containers (faster for large subscriptions).",
    )
    parser.add_argument(
        "--output",
        action="append",
        dest="outputs",
        metavar="FILE",
        help="Write account results to FILE. Extension (.json or .csv) selects the "
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
        client = StorageManagementClient(credential, subscription_id)
        accounts = collect_accounts(client)
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

    rows_as_lists = [[r[f] for f in ACCOUNT_FIELDNAMES] for r in accounts]
    print_table(ACCOUNT_FIELDNAMES, rows_as_lists)
    write_outputs(accounts, ACCOUNT_FIELDNAMES, args.outputs)

    if not args.skip_containers:
        all_containers = []
        for account_row in accounts:
            all_containers.extend(collect_containers(client, account_row))
        print()
        print("Containers:")
        container_rows_as_lists = [[r[f] for f in CONTAINER_FIELDNAMES] for r in all_containers]
        print_table(CONTAINER_FIELDNAMES, container_rows_as_lists)

    return 0


if __name__ == "__main__":
    sys.exit(main())
