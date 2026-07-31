#!/usr/bin/env python3
"""
keyvault_audit.py - List Key Vaults, and for each, secrets/certificates
expiring within --days, and whether the vault uses access policies or
RBAC authorization.

Authenticates via azure-identity's DefaultAzureCredential. The
subscription is taken from --subscription-id, or falls back to the
AZURE_SUBSCRIPTION_ID environment variable.

Vault enumeration and the RBAC/access-policy flag use the ARM
(management-plane) API (azure-mgmt-keyvault). Secret/certificate expiry
requires the data-plane SDKs (azure-keyvault-secrets,
azure-keyvault-certificates) and the caller having read access to each
vault's secrets/certificates metadata.
"""
import argparse
import csv
import datetime
import json
import os
import sys

from azure.core.exceptions import ClientAuthenticationError, HttpResponseError
from azure.identity import DefaultAzureCredential
from azure.mgmt.keyvault import KeyVaultManagementClient

try:
    from azure.keyvault.certificates import CertificateClient
    from azure.keyvault.secrets import SecretClient

    DATA_PLANE_AVAILABLE = True
except ImportError:
    DATA_PLANE_AVAILABLE = False

VAULT_FIELDNAMES = ["Name", "ResourceGroup", "AuthorizationModel", "Location"]
EXPIRY_FIELDNAMES = ["Vault", "Kind", "Name", "ExpiresOn", "DaysUntilExpiry"]


def resource_group_from_id(resource_id):
    parts = resource_id.split("/")
    try:
        return parts[parts.index("resourceGroups") + 1]
    except (ValueError, IndexError):
        return ""


def extract_vault_row(vault):
    """Turn one Vault into a flat dict row."""
    props = getattr(vault, "properties", None)
    rbac = bool(getattr(props, "enable_rbac_authorization", False)) if props else False
    return {
        "Name": vault.name,
        "ResourceGroup": resource_group_from_id(vault.id),
        "AuthorizationModel": "RBAC" if rbac else "Access policies",
        "Location": vault.location,
    }


def collect_vaults(kv_mgmt_client):
    return [extract_vault_row(v) for v in kv_mgmt_client.vaults.list()]


def days_until(expires_on, now=None):
    now = now or datetime.datetime.now(datetime.timezone.utc)
    return (expires_on - now).days


def find_expiring_in_vault(vault_name, credential, days, now=None):
    """Return rows for secrets/certs in one vault expiring within `days`."""
    if not DATA_PLANE_AVAILABLE:
        return []

    rows = []
    vault_url = f"https://{vault_name}.vault.azure.net"

    try:
        secret_client = SecretClient(vault_url=vault_url, credential=credential)
        for props in secret_client.list_properties_of_secrets():
            if props.expires_on:
                d = days_until(props.expires_on, now=now)
                if d <= days:
                    rows.append(
                        {
                            "Vault": vault_name,
                            "Kind": "secret",
                            "Name": props.name,
                            "ExpiresOn": str(props.expires_on),
                            "DaysUntilExpiry": d,
                        }
                    )
    except HttpResponseError as e:
        print(f"WARNING: could not list secrets for vault '{vault_name}': {e}", file=sys.stderr)

    try:
        cert_client = CertificateClient(vault_url=vault_url, credential=credential)
        for props in cert_client.list_properties_of_certificates():
            if props.expires_on:
                d = days_until(props.expires_on, now=now)
                if d <= days:
                    rows.append(
                        {
                            "Vault": vault_name,
                            "Kind": "certificate",
                            "Name": props.name,
                            "ExpiresOn": str(props.expires_on),
                            "DaysUntilExpiry": d,
                        }
                    )
    except HttpResponseError as e:
        print(f"WARNING: could not list certificates for vault '{vault_name}': {e}", file=sys.stderr)

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
        description="List Key Vaults, secrets/certs expiring within --days, and RBAC vs access-policy authorization."
    )
    parser.add_argument(
        "--subscription-id",
        help="Azure subscription ID. Defaults to the AZURE_SUBSCRIPTION_ID environment variable.",
    )
    parser.add_argument(
        "--days",
        type=int,
        default=30,
        help="Report secrets/certificates expiring within this many days (default: 30).",
    )
    parser.add_argument(
        "--skip-expiry-check",
        action="store_true",
        help="Only report vault-level info (name, RBAC/access-policy), skip the secret/cert expiry check.",
    )
    parser.add_argument(
        "--output",
        action="append",
        dest="outputs",
        metavar="FILE",
        help="Write vault results to FILE. Extension (.json or .csv) selects the "
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
        mgmt_client = KeyVaultManagementClient(credential, subscription_id)
        vaults = collect_vaults(mgmt_client)
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

    rows_as_lists = [[r[f] for f in VAULT_FIELDNAMES] for r in vaults]
    print_table(VAULT_FIELDNAMES, rows_as_lists)
    write_outputs(vaults, VAULT_FIELDNAMES, args.outputs)

    if not args.skip_expiry_check:
        print()
        if not DATA_PLANE_AVAILABLE:
            print(
                "WARNING: azure-keyvault-secrets / azure-keyvault-certificates not "
                "installed; skipping expiry check. Install them to enable it.",
                file=sys.stderr,
            )
        else:
            print(f"Secrets/certificates expiring within {args.days} day(s):")
            expiring = []
            for vault_row in vaults:
                expiring.extend(find_expiring_in_vault(vault_row["Name"], credential, args.days))
            expiring_as_lists = [[r[f] for f in EXPIRY_FIELDNAMES] for r in expiring]
            print_table(EXPIRY_FIELDNAMES, expiring_as_lists)

    return 0


if __name__ == "__main__":
    sys.exit(main())
