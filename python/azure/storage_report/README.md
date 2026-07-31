# storage_report

List storage accounts and their containers with access tier.

## Purpose

An inventory of storage accounts and blob containers across a subscription, including public-access flags worth reviewing.

## Requirements

- Python 3.9+, `azure-identity`, `azure-mgmt-storage` (see [requirements.txt](../requirements.txt))
- Azure credentials via `DefaultAzureCredential`
- RBAC: `Reader` role (or equivalent) on the subscription — container listing uses the ARM management-plane API (`blob_containers`), so no separate storage account key or data-plane role is needed

## Usage

```bash
python3 storage_report.py [options]
```

| Option | Description |
|---|---|
| `--subscription-id ID` | Azure subscription ID (default: `AZURE_SUBSCRIPTION_ID` env var) |
| `--skip-containers` | Only report storage accounts, skip listing containers (faster) |
| `--output FILE` | Write account results to FILE (`.json` or `.csv`), repeatable |

## Examples

See [example.md](example.md).

## Output

A table of storage accounts (Name, ResourceGroup, Location, Sku, Kind, AccessTier), followed by a table of containers (Account, Container, PublicAccess, LastModifiedTime) unless `--skip-containers` is given.

## Troubleshooting

| Symptom | Cause | Fix |
|---|---|---|
| `Azure authentication failed` | Not logged in / no credential source available | Run `az login`, or set up a service principal / managed identity |
| `could not list containers for '<account>'` (warning) | Account has data-plane-only access, network rules blocking ARM, or insufficient permission | Check the account's network/firewall rules and the caller's RBAC role |
| Slow on large subscriptions | One container-list call per storage account | Use `--skip-containers` for a faster account-only report |

## References

- [`azure-mgmt-storage`](https://learn.microsoft.com/en-us/python/api/overview/azure/mgmt-storage-readme)
