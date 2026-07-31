# keyvault_audit

List Key Vaults, secrets/certificates expiring soon, and whether each vault uses RBAC or access-policy authorization.

## Purpose

Catch an expiring secret or certificate before it causes an outage, and see at a glance which vaults still use legacy access policies instead of RBAC.

## Requirements

- Python 3.9+, `azure-identity`, `azure-mgmt-keyvault` (vault enumeration), `azure-keyvault-secrets` + `azure-keyvault-certificates` (expiry check — optional, see below)
- Azure credentials via `DefaultAzureCredential`
- RBAC/access policy: `Reader` on the subscription for vault enumeration; `Key Vault Secrets User` + `Key Vault Certificates User` (or an equivalent access policy) on each vault for the expiry check

## Usage

```bash
python3 keyvault_audit.py [options]
```

| Option | Description |
|---|---|
| `--subscription-id ID` | Azure subscription ID (default: `AZURE_SUBSCRIPTION_ID` env var) |
| `--days N` | Report secrets/certs expiring within this many days (default: 30) |
| `--skip-expiry-check` | Only report vault-level info (name, RBAC vs access policies) |
| `--output FILE` | Write vault results to FILE (`.json` or `.csv`), repeatable |

## Examples

See [example.md](example.md).

## Output

A table of vaults (Name, ResourceGroup, AuthorizationModel, Location), and — unless `--skip-expiry-check` — a table of secrets/certificates expiring within `--days` (Vault, Kind, Name, ExpiresOn, DaysUntilExpiry).

## Troubleshooting

| Symptom | Cause | Fix |
|---|---|---|
| `azure-keyvault-secrets / azure-keyvault-certificates not installed` (warning) | Optional data-plane packages not installed | `pip install -r ../requirements.txt`, or pass `--skip-expiry-check` |
| `could not list secrets for vault '<name>'` (warning) | Caller lacks data-plane access to that specific vault | Grant `Key Vault Secrets User` (RBAC) or an access policy with `list` permission |
| `Azure authentication failed` | Not logged in / no credential source available | Run `az login`, or set up a service principal / managed identity |

## References

- [`azure-mgmt-keyvault`](https://learn.microsoft.com/en-us/python/api/overview/azure/mgmt-keyvault-readme)
- [`azure-keyvault-secrets`](https://learn.microsoft.com/en-us/python/api/overview/azure/keyvault-secrets-readme)
