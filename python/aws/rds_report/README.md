# rds_report

List RDS instances: identifier, engine, engine version, instance class, status, Multi-AZ, allocated storage.

## Purpose

Get a quick inventory of RDS instances for capacity/version audits or to spot databases that aren't configured for Multi-AZ high availability.

## Requirements

- Python 3.8+
- [`boto3`](https://pypi.org/project/boto3/) (see `../requirements.txt`)
- AWS credentials available via boto3's default credential chain (environment variables, `~/.aws/credentials`, an instance profile, or an assumed role)
- IAM permissions:
  - `rds:DescribeDBInstances`

## Usage

```bash
python rds_report.py [options]
```

| Option | Description |
|---|---|
| `--region REGION` | AWS region to inspect. Repeatable. Defaults to the region configured in the current AWS profile/session. |
| `--non-multi-az-only` | Only show instances that are NOT configured for Multi-AZ. |
| `--output FILE` | Write results to `FILE`. Extension (`.json` or `.csv`) selects the format. Repeatable. |
| `-h`, `--help` | Show usage and exit |

## Examples

See [example.md](example.md).

## Output

- Prints a table with columns: Region, DBInstanceIdentifier, Engine, EngineVersion, DBInstanceClass, DBInstanceStatus, MultiAZ, AllocatedStorageGB.
- With `--output`, also writes the full result set to `.json`/`.csv`.
- Exits non-zero (with a clear message, no stack trace) on missing credentials, denied permissions, or unresolved region.

## Troubleshooting

| Symptom | Cause | Fix |
|---|---|---|
| `No AWS credentials found` | boto3 could not find any credentials | Run `aws configure`, set env vars, or attach an IAM role |
| `Access denied` | Caller's IAM policy lacks `rds:DescribeDBInstances` | Attach a policy granting `rds:DescribeDBInstances` |
| `No region specified and no default region configured` | No `--region` given, no default region set | Pass `--region us-east-1` or set `AWS_DEFAULT_REGION` |
| Empty table with `--non-multi-az-only` | All instances are Multi-AZ | Expected - nothing to flag |

## References

- [`describe_db_instances` (boto3 RDS client)](https://boto3.amazonaws.com/v1/documentation/api/latest/reference/services/rds/client/describe_db_instances.html)
- [Amazon RDS Multi-AZ deployments](https://docs.aws.amazon.com/AmazonRDS/latest/UserGuide/Concepts.MultiAZ.html)
