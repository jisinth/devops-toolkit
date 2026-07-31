# ec2_inventory

List EC2 instances (instance ID, `Name` tag, instance type, state, availability zone, private/public IP) across one or more AWS regions.

## Purpose

Get a quick, scriptable inventory of running (and stopped/terminated) EC2 instances without clicking through the console region by region.

## Requirements

- Python 3.8+
- [`boto3`](https://pypi.org/project/boto3/) (see `../requirements.txt`)
- AWS credentials available via boto3's default credential chain (environment variables, `~/.aws/credentials`, an instance profile, or an assumed role) - no credentials are read from the command line
- IAM permissions:
  - `ec2:DescribeInstances`

## Usage

```bash
python ec2_inventory.py [options]
```

| Option | Description |
|---|---|
| `--region REGION` | AWS region to inspect. Repeatable. Defaults to the region configured in the current AWS profile/session. |
| `--output FILE` | Write results to `FILE`. Extension (`.json` or `.csv`) selects the format. Repeatable to write multiple files. |
| `-h`, `--help` | Show usage and exit |

## Examples

See [example.md](example.md).

## Output

- Prints a plain-text table of all discovered instances to stdout.
- With `--output report.json` / `--output report.csv`, also writes the full result set to a file in that format.
- Exits non-zero (with a message on stderr, no stack trace) if credentials are missing/invalid, a permission is denied, or no region can be determined.

## Troubleshooting

| Symptom | Cause | Fix |
|---|---|---|
| `No AWS credentials found` | boto3 could not find any credentials | Run `aws configure`, set `AWS_ACCESS_KEY_ID`/`AWS_SECRET_ACCESS_KEY`, or attach an IAM role |
| `Access denied` | Caller's IAM policy lacks `ec2:DescribeInstances` | Attach a policy granting `ec2:DescribeInstances` for the target region(s) |
| `No region specified and no default region configured` | No `--region` given and no default region in the profile/environment | Pass `--region us-east-1` (etc.) or set `AWS_DEFAULT_REGION` |
| `unrecognized output extension` warning | `--output` file doesn't end in `.json` or `.csv` | Rename the output file with a supported extension |

## References

- [`describe_instances` (boto3 EC2 client)](https://boto3.amazonaws.com/v1/documentation/api/latest/reference/services/ec2/client/describe_instances.html)
- [boto3 credential configuration](https://boto3.amazonaws.com/v1/documentation/api/latest/guide/credentials.html)
