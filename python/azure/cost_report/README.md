# cost_report

Azure Cost Management query for cost grouped by service, for the current month (or a custom date range).

## Purpose

A fast "what's costing money this month, by service" summary without opening Cost Management + Billing in the portal.

## Requirements

- Python 3.9+, `azure-identity`, `azure-mgmt-costmanagement` (see [requirements.txt](../requirements.txt))
- Azure credentials via `DefaultAzureCredential`
- RBAC: `Cost Management Reader` (or `Reader`) on the subscription

## Usage

```bash
python3 cost_report.py [options]
```

| Option | Description |
|---|---|
| `--subscription-id ID` | Azure subscription ID (default: `AZURE_SUBSCRIPTION_ID` env var) |
| `--start DATE` | Start date, `YYYY-MM-DD` (requires `--end`; default: month-to-date) |
| `--end DATE` | End date, `YYYY-MM-DD` (requires `--start`) |
| `--output FILE` | Write results to FILE (`.json` or `.csv`), repeatable |

## Examples

See [example.md](example.md).

## Output

A table of Service, Amount, Currency, sorted highest cost first.

## Troubleshooting

| Symptom | Cause | Fix |
|---|---|---|
| `Azure authentication failed` | Not logged in / no credential source available | Run `az login`, or set up a service principal / managed identity |
| `--start and --end must be given together` | Only one of the two was passed | Pass both, or neither (to use month-to-date) |
| Empty results | No cost activity in the range, or too soon after resource creation (cost data can lag ~24h) | Try a wider or earlier range |

## References

- [`azure-mgmt-costmanagement`](https://learn.microsoft.com/en-us/python/api/overview/azure/mgmt-costmanagement-readme)
