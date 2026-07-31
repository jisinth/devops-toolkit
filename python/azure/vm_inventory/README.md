# vm_inventory

List VMs across a subscription (or one resource group): name, size, power state, region, OS type.

## Purpose

A fast inventory of running/stopped VMs across a subscription, without opening the Azure portal.

## Requirements

- Python 3.9+, `azure-identity`, `azure-mgmt-compute` (see [requirements.txt](../requirements.txt))
- Azure credentials via `DefaultAzureCredential` (Azure CLI login, environment variables, or managed identity)
- RBAC: `Reader` role (or equivalent) on the subscription/resource group

## Usage

```bash
python3 vm_inventory.py [options]
```

| Option | Description |
|---|---|
| `--subscription-id ID` | Azure subscription ID (default: `AZURE_SUBSCRIPTION_ID` env var) |
| `--resource-group NAME` | Only list VMs in this resource group (default: whole subscription) |
| `--output FILE` | Write results to FILE (`.json` or `.csv`), repeatable |

## Examples

See [example.md](example.md).

## Output

A table of Name, ResourceGroup, Size, PowerState, Location, OsType. Power state requires one extra API call per VM (`instanceView` expand), so this is slower on subscriptions with many VMs.

## Troubleshooting

| Symptom | Cause | Fix |
|---|---|---|
| `Azure authentication failed` | Not logged in / no credential source available | Run `az login`, or set up a service principal / managed identity |
| `No subscription ID given` | Neither `--subscription-id` nor `AZURE_SUBSCRIPTION_ID` set | Pass `--subscription-id`, or `export AZURE_SUBSCRIPTION_ID=...` |
| Slow on large subscriptions | One extra API call per VM for power state | Scope with `--resource-group` |

## References

- [`azure-mgmt-compute`](https://learn.microsoft.com/en-us/python/api/overview/azure/mgmt-compute-readme)
- [`DefaultAzureCredential`](https://learn.microsoft.com/en-us/python/api/azure-identity/azure.identity.defaultazurecredential)
