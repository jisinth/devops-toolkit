# resource_groups

List resource groups and a count of resources in each.

## Purpose

A quick census of what's in each resource group — useful before deleting one, or just to see where sprawl is happening.

## Requirements

- Python 3.9+, `azure-identity`, `azure-mgmt-resource` (see [requirements.txt](../requirements.txt))
- Azure credentials via `DefaultAzureCredential`
- RBAC: `Reader` role (or equivalent) on the subscription

## Usage

```bash
python3 resource_groups.py [options]
```

| Option | Description |
|---|---|
| `--subscription-id ID` | Azure subscription ID (default: `AZURE_SUBSCRIPTION_ID` env var) |
| `--detailed` | Also break the resource count down by resource type per group |
| `--output FILE` | Write the summary results to FILE (`.json` or `.csv`), repeatable |

## Examples

See [example.md](example.md).

## Output

A summary table (Name, Location, ResourceCount), and with `--detailed`, a second table broken down by resource type per group.

## Troubleshooting

| Symptom | Cause | Fix |
|---|---|---|
| `Azure authentication failed` | Not logged in / no credential source available | Run `az login`, or set up a service principal / managed identity |
| `No subscription ID given` | Neither `--subscription-id` nor `AZURE_SUBSCRIPTION_ID` set | Pass `--subscription-id`, or `export AZURE_SUBSCRIPTION_ID=...` |
| Slow with `--detailed` on many groups | One list call per resource group | Expected for large subscriptions; omit `--detailed` for a faster summary |

## References

- [`azure-mgmt-resource`](https://learn.microsoft.com/en-us/python/api/overview/azure/mgmt-resource-readme)
