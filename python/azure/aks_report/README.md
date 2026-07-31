# aks_report

List AKS clusters: name, Kubernetes version, node pool count/sizes, provisioning state.

## Purpose

A quick overview of every AKS cluster in a subscription — versions, node pool shapes, and whether any are mid-provisioning or failed.

## Requirements

- Python 3.9+, `azure-identity`, `azure-mgmt-containerservice` (see [requirements.txt](../requirements.txt))
- Azure credentials via `DefaultAzureCredential`
- RBAC: `Reader` role (or equivalent) on the subscription/resource group

## Usage

```bash
python3 aks_report.py [options]
```

| Option | Description |
|---|---|
| `--subscription-id ID` | Azure subscription ID (default: `AZURE_SUBSCRIPTION_ID` env var) |
| `--resource-group NAME` | Only list clusters in this resource group (default: whole subscription) |
| `--output FILE` | Write results to FILE (`.json` or `.csv`), repeatable |

## Examples

See [example.md](example.md).

## Output

A table of Name, ResourceGroup, KubernetesVersion, ProvisioningState, NodePools (`name:size xcount` per pool), Location.

## Troubleshooting

| Symptom | Cause | Fix |
|---|---|---|
| `Azure authentication failed` | Not logged in / no credential source available | Run `az login`, or set up a service principal / managed identity |
| `No subscription ID given` | Neither `--subscription-id` nor `AZURE_SUBSCRIPTION_ID` set | Pass `--subscription-id`, or `export AZURE_SUBSCRIPTION_ID=...` |
| `ProvisioningState` shows `Failed` | The last cluster operation (create/update/scale) failed | Check the cluster's activity log in the Azure portal |

## References

- [`azure-mgmt-containerservice`](https://learn.microsoft.com/en-us/python/api/overview/azure/mgmt-containerservice-readme)
