# s3_inventory

List S3 buckets with region, approximate size & object count, and public-access-block status.

## Purpose

Get a fast overview of every S3 bucket in the account - how big it is, how many objects it holds, and whether public access is blocked - without opening the console bucket by bucket.

## Requirements

- Python 3.8+
- [`boto3`](https://pypi.org/project/boto3/) (see `../requirements.txt`)
- AWS credentials available via boto3's default credential chain (environment variables, `~/.aws/credentials`, an instance profile, or an assumed role)
- IAM permissions:
  - `s3:ListAllMyBuckets`
  - `s3:GetBucketLocation`
  - `s3:GetBucketPublicAccessBlock`
  - `cloudwatch:GetMetricStatistics` (default mode - reads S3 daily storage metrics)
  - `s3:ListBucket` on each bucket (only required with `--deep`)

## Usage

```bash
python s3_inventory.py [options]
```

| Option | Description |
|---|---|
| `--region REGION` | Region for the S3/CloudWatch clients used to make the calls. Defaults to the current profile/session region. |
| `--deep` | Compute exact size/object count via a real `list_objects_v2` walk instead of reading CloudWatch bucket metrics. Slower and costs more API calls, but accurate as of "right now" rather than the last CloudWatch daily datapoint. |
| `--output FILE` | Write results to `FILE`. Extension (`.json` or `.csv`) selects the format. Repeatable. |
| `-h`, `--help` | Show usage and exit |

## Examples

See [example.md](example.md).

## Output

- Prints a table with columns: Bucket, Region, SizeBytes, SizeHuman, ObjectCount, PublicAccessBlock.
- By default, size/object counts come from the most recent CloudWatch `BucketSizeBytes`/`NumberOfObjects` datapoint (published once daily by S3) - a bucket younger than ~24-48h may show `unknown` until CloudWatch has data.
- `PublicAccessBlock` is one of: `Fully blocked`, `Partially blocked`, `Not blocked`, `Not configured`, `Unknown`.
- With `--output`, also writes the full result set to `.json`/`.csv`.

## Troubleshooting

| Symptom | Cause | Fix |
|---|---|---|
| `No AWS credentials found` | boto3 could not find any credentials | Run `aws configure`, set env vars, or attach an IAM role |
| `Access denied` | Missing one of the required IAM actions | Grant `s3:ListAllMyBuckets`, `s3:GetBucketLocation`, `s3:GetBucketPublicAccessBlock`, `cloudwatch:GetMetricStatistics`, and (for `--deep`) `s3:ListBucket` |
| `SizeBytes`/`ObjectCount` show blank/`unknown` | No CloudWatch datapoint yet (new or empty bucket, or metric not yet published) | Re-run later, or use `--deep` for an exact count |
| `--deep` is slow on large buckets | Full object listing, one API call per ~1000 objects | Expected; only use `--deep` when exact numbers matter |

## References

- [`list_buckets` / `get_bucket_location` (boto3 S3 client)](https://boto3.amazonaws.com/v1/documentation/api/latest/reference/services/s3.html)
- [Amazon S3 CloudWatch metrics](https://docs.aws.amazon.com/AmazonS3/latest/userguide/metrics-dimensions.html)
- [S3 Block Public Access](https://docs.aws.amazon.com/AmazonS3/latest/userguide/access-control-block-public-access.html)
