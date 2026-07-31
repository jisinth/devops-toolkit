# cost_report

Cost Explorer monthly cost summary grouped by service, for a date range (default: current month-to-date).

## Purpose

A fast "what's costing money this month, by service" summary without opening the Cost Explorer console.

## Requirements

- Python 3.9+, `boto3` (see [requirements.txt](../requirements.txt))
- AWS credentials via the default boto3 chain (`aws configure`, environment variables, or an IAM role)
- IAM permission: `ce:GetCostAndUsage`
- Cost Explorer must be enabled on the account (one-time setup in the AWS Console/Billing settings)

## Usage

```bash
python3 cost_report.py [options]
```

| Option | Description |
|---|---|
| `--start DATE` | Start date, `YYYY-MM-DD` (default: 1st of the current month) |
| `--end DATE` | End date, `YYYY-MM-DD`, exclusive (default: today) |
| `--output FILE` | Write results to FILE (`.json` or `.csv`), repeatable |

## Examples

See [example.md](example.md).

## Output

A table of service → total unblended cost (summed across the date range) and currency unit, sorted highest cost first.

## Troubleshooting

| Symptom | Cause | Fix |
|---|---|---|
| `No AWS credentials found` | No credentials configured | Run `aws configure`, or set env vars, or attach an IAM role |
| `Access denied` | Caller lacks Cost Explorer permissions | Grant `ce:GetCostAndUsage` |
| API error mentioning Cost Explorer not enabled | Cost Explorer hasn't been activated on this account | Enable it once in the Billing console (may take up to 24h to populate) |

## References

- [`get_cost_and_usage`](https://boto3.amazonaws.com/v1/documentation/api/latest/reference/services/ce/client/get_cost_and_usage.html)
