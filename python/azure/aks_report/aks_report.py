#!/usr/bin/env python3
"""
aks_report.py - List AKS clusters: name, Kubernetes version, node pool
count/sizes, provisioning state.

Authenticates via azure-identity's DefaultAzureCredential. The
subscription is taken from --subscription-id, or falls back to the
AZURE_SUBSCRIPTION_ID environment variable.
"""
import argparse
import csv
import json
import os
import sys

from azure.core.exceptions import ClientAuthenticationError, HttpResponseError
from azure.identity import DefaultAzureCredential
from azure.mgmt.containerservice import ContainerServiceClient

FIELDNAMES = ["Name", "ResourceGroup", "KubernetesVersion", "ProvisioningState", "NodePools", "Location"]


def resource_group_from_id(resource_id):
    parts = resource_id.split("/")
    try:
        return parts[parts.index("resourceGroups") + 1]
    except (ValueError, IndexError):
        return ""


def summarize_node_pools(agent_pool_profiles):
    """Turn agent pool profiles into a 'name:size x count, ...' summary string."""
    if not agent_pool_profiles:
        return ""
    parts = []
    for pool in agent_pool_profiles:
        name = getattr(pool, "name", "?")
        size = getattr(pool, "vm_size", "?")
        count = getattr(pool, "count", "?")
        parts.append(f"{name}:{size} x{count}")
    return ", ".join(parts)


def extract_cluster_row(cluster):
    """Turn one ManagedCluster into a flat dict row."""
    return {
        "Name": cluster.name,
        "ResourceGroup": resource_group_from_id(cluster.id),
        "KubernetesVersion": getattr(cluster, "kubernetes_version", "") or "",
        "ProvisioningState": getattr(cluster, "provisioning_state", "") or "",
        "NodePools": summarize_node_pools(getattr(cluster, "agent_pool_profiles", None)),
        "Location": cluster.location,
    }


def collect_clusters(aks_client, resource_group=None):
    """List AKS clusters (subscription-wide, or scoped to one resource group)."""
    if resource_group:
        clusters = aks_client.managed_clusters.list_by_resource_group(resource_group)
    else:
        clusters = aks_client.managed_clusters.list()
    return [extract_cluster_row(c) for c in clusters]


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
        description="List AKS clusters: name, Kubernetes version, node pool count/sizes, provisioning state."
    )
    parser.add_argument(
        "--subscription-id",
        help="Azure subscription ID. Defaults to the AZURE_SUBSCRIPTION_ID environment variable.",
    )
    parser.add_argument("--resource-group", help="Only list clusters in this resource group (default: whole subscription).")
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
        client = ContainerServiceClient(credential, subscription_id)
        rows = collect_clusters(client, resource_group=args.resource_group)
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
