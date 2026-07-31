# ebs_snapshot

List EBS volumes and their existing snapshots, flag unattached (`available` state) volumes, and optionally create a new snapshot.

## Purpose

Spot orphaned/unattached EBS volumes that are quietly costing money, see snapshot coverage per volume, and kick off an ad-hoc snapshot without opening the console.

## Requirements

- Python 3.8+
- [`boto3`](https://pypi.org/project/boto3/) (see `../requirements.txt`)
- AWS credentials available via boto3's default credential chain (environment variables, `~/.aws/credentials`, an instance profile, or an assumed role)
- IAM permissions:
  - `ec2:DescribeVolumes`
  - `ec2:DescribeSnapshots`
  - `ec2:CreateSnapshot` (only required for `--create`)

## Usage

```bash
python ebs_snapshot.py [options]
```

| Option | Description |
|---|---|
| `--region REGION` | AWS region to inspect. Repeatable. Defaults to the region configured in the current AWS profile/session. |
| `--create VOLUME_ID` | Create a new snapshot of the given volume ID. Uses the first `--region` given (or the default region). When set, no listing is performed. |
| `--description TEXT` | Description to attach to the snapshot created with `--create`. |
| `--unattached-only` | Only list volumes that are unattached (state `available`). |
| `--output FILE` | Write the volume list to `FILE`. Extension (`.json` or `.csv`) selects the format. Repeatable. |
| `-h`, `--help` | Show usage and exit |

## Examples

See [example.md](example.md).

## Output

- Prints a table with columns: Region, VolumeId, State, SizeGiB, VolumeType, AvailabilityZone, Unattached, SnapshotCount.
- Prints a one-line summary of how many unattached volumes were found (if any).
- `--create` prints the new snapshot ID and its initial state instead of listing volumes.
- With `--output`, also writes the volume list to `.json`/`.csv` (only owned snapshots, via `OwnerIds=["self"]`, are counted per volume).

## Troubleshooting

| Symptom | Cause | Fix |
|---|---|---|
| `No AWS credentials found` | boto3 could not find any credentials | Run `aws configure`, set env vars, or attach an IAM role |
| `Access denied` | Missing `ec2:DescribeVolumes`/`ec2:DescribeSnapshots`/`ec2:CreateSnapshot` | Grant the relevant EC2 permission(s) |
| `Volume not found` | `--create` given an invalid/nonexistent volume ID | Verify the volume ID with `ebs_snapshot.py` (no `--create`) first |
| `No region specified and no default region configured` | No `--region` given, no default region set | Pass `--region us-east-1` or set `AWS_DEFAULT_REGION` |

## References

- [`describe_volumes` (boto3 EC2 client)](https://boto3.amazonaws.com/v1/documentation/api/latest/reference/services/ec2/client/describe_volumes.html)
- [`create_snapshot` (boto3 EC2 client)](https://boto3.amazonaws.com/v1/documentation/api/latest/reference/services/ec2/client/create_snapshot.html)
- [Amazon EBS snapshots](https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/EBSSnapshots.html)
