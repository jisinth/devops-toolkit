#!/usr/bin/env python3
"""
vm_inventory.py - List VMs across a subscription (or one resource group):
name, size, power state, region, OS type.

Authenticates via azure-identity's DefaultAzureCredential (environment
variables, managed identity, Azure CLI login, etc.) - no credentials are
read from the command line or hardcoded. The subscription is taken from
--subscription-id, or falls back to the AZURE_SUBSCRIPTION_ID environment
variable.
"""
import argparse
import csv
import json
import os
import sys

from azure.core.exceptions import ClientAuthenticationError, HttpResponseError
from azure.identity import DefaultAzureCredential
from azure.mgmt.compute import ComputeManagementClient

FIELDNAMES = ["Name", "ResourceGroup", "Size", "PowerState", "Location", "OsType"]


def get_power_state(instance_view):
    """Extract the 'PowerState/...' code from a VM instance view's statuses."""
    if not instance_view:
        return "unknown"
    for status in instance_view.statuses or []:
        code = getattr(status, "code", "") or ""
        if code.startswith("PowerState/"):
            return code.split("/", 1)[1]
    return "unknown"


def extract_vm_row(vm, resource_group):
    """Turn one VirtualMachine (with instanceView expanded) into a flat dict row."""
    os_profile = getattr(vm, "storage_profile", None)
    os_type = ""
    if os_profile and getattr(os_profile, "os_disk", None):
        os_type = str(getattr(os_profile.os_disk, "os_type", "") or "")
    return {
        "Name": vm.name,
        "ResourceGroup": resource_group,
        "Size": getattr(vm.hardware_profile, "vm_size", "") if vm.hardware_profile else "",
        "PowerState": get_power_state(getattr(vm, "instance_view", None)),
        "Location": vm.location,
        "OsType": os_type,
    }


def resource_group_from_id(resource_id):
    """Extract the resource group name out of an ARM resource ID."""
    parts = resource_id.split("/")
    try:
        return parts[parts.index("resourceGroups") + 1]
    except (ValueError, IndexError):
        return ""


def collect_vms(compute_client, resource_group=None):
    """List VMs (subscription-wide, or scoped to one resource group), with power state."""
    rows = []
    if resource_group:
        vms = compute_client.virtual_machines.list(resource_group)
    else:
        vms = compute_client.virtual_machines.list_all()

    for vm in vms:
        rg = resource_group or resource_group_from_id(vm.id)
        detailed = compute_client.virtual_machines.get(rg, vm.name, expand="instanceView")
        rows.append(extract_vm_row(detailed, rg))
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
        description="List VMs across a subscription (or one resource group): name, size, power state, region, OS type."
    )
    parser.add_argument(
        "--subscription-id",
        help="Azure subscription ID. Defaults to the AZURE_SUBSCRIPTION_ID environment variable.",
    )
    parser.add_argument("--resource-group", help="Only list VMs in this resource group (default: whole subscription).")
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
        client = ComputeManagementClient(credential, subscription_id)
        rows = collect_vms(client, resource_group=args.resource_group)
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

    rows_as_lists = [[r[f] for f in FIELDNAMES] for r in rows]
    print_table(FIELDNAMES, rows_as_lists)
    write_outputs(rows, FIELDNAMES, args.outputs)
    return 0


if __name__ == "__main__":
    sys.exit(main())
