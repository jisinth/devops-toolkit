# cloudwatch_report

Report CloudWatch alarm states, optionally with recent datapoints for a specific metric.

## Purpose

A quick way to see which alarms are currently firing across a region, and optionally pull recent metric data for one of them — without opening the CloudWatch console.

## Requirements

- Python 3.9+, `boto3` (see [requirements.txt](../requirements.txt))
- AWS credentials via the default boto3 chain (`aws configure`, environment variables, or an IAM role)
- IAM permissions: `cloudwatch:DescribeAlarms`, and `cloudwatch:GetMetricStatistics` if using `--metric-name`

## Usage

```bash
python3 cloudwatch_report.py [options]
```

| Option | Description |
|---|---|
| `--region REGION` | AWS region (default: configured profile/session region) |
| `--state {OK,ALARM,INSUFFICIENT_DATA}` | Only report alarms in this state |
| `--namespace NAMESPACE` | CloudWatch namespace to pull datapoints from, e.g. `AWS/EC2` |
| `--metric-name NAME` | Metric name to pull datapoints for (requires `--namespace`) |
| `--hours N` | How many hours of recent datapoints to fetch (default: 3) |
| `--output FILE` | Write results to FILE (`.json` or `.csv`), repeatable |

## Examples

See [example.md](example.md).

## Output

A table of alarms (name, state, metric, namespace, last state change), and — if `--namespace`/`--metric-name` are given — a second table of recent datapoints for that metric.

## Troubleshooting

| Symptom | Cause | Fix |
|---|---|---|
| `No AWS credentials found` | No credentials configured | Run `aws configure`, or set env vars, or attach an IAM role |
| `Access denied` | Caller lacks CloudWatch read permissions | Grant `cloudwatch:DescribeAlarms` / `cloudwatch:GetMetricStatistics` |
| Empty datapoints table | No data in the metric/namespace for `--hours`, or wrong namespace/metric name | Verify the metric exists in the CloudWatch console first |

## References

- [`describe_alarms`](https://boto3.amazonaws.com/v1/documentation/api/latest/reference/services/cloudwatch/client/describe_alarms.html)
- [`get_metric_statistics`](https://boto3.amazonaws.com/v1/documentation/api/latest/reference/services/cloudwatch/client/get_metric_statistics.html)
