# iam_audit

Audit IAM users using the IAM credential report: access keys older than `--max-key-age-days`, users without MFA enabled, and credentials that haven't been used recently (or ever).

## Purpose

Surface the IAM hygiene issues that matter for a security review - stale access keys, console users without MFA, and dormant credentials - in one pass, using a single IAM API (the credential report) rather than iterating every user individually.

## Requirements

- Python 3.8+
- [`boto3`](https://pypi.org/project/boto3/) (see `../requirements.txt`)
- AWS credentials available via boto3's default credential chain (environment variables, `~/.aws/credentials`, an instance profile, or an assumed role)
- IAM permissions:
  - `iam:GenerateCredentialReport`
  - `iam:GetCredentialReport`

IAM is a global service, so no `--region` is needed.

## Usage

```bash
python iam_audit.py [options]
```

| Option | Description |
|---|---|
| `--max-key-age-days N` | Flag active access keys last rotated more than `N` days ago. Default: `90`. |
| `--unused-threshold-days N` | Flag credentials (password or access key) not used within `N` days, or never used. Default: `90`. |
| `--output FILE` | Write the findings table to `FILE`. Extension (`.json` or `.csv`) selects the format. Repeatable. |
| `-h`, `--help` | Show usage and exit |

The AWS account's root user (`<root_account>`) is excluded from all three checks - audit root credentials separately.

## Examples

See [example.md](example.md).

## Output

- Requests a fresh IAM credential report (`generate_credential_report` + polling `get_credential_report`) and parses it.
- Prints one flat findings table with columns: User, IssueType (`OldAccessKey`, `NoMFA`, `UnusedCredential`), Detail.
- Prints a one-line summary count of users audited and issues found.
- With `--output`, also writes the findings table to `.json`/`.csv`.
- Exits non-zero (clear message, no stack trace) on missing credentials, denied permissions, or report generation timeout.

## Troubleshooting

| Symptom | Cause | Fix |
|---|---|---|
| `No AWS credentials found` | boto3 could not find any credentials | Run `aws configure`, set env vars, or attach an IAM role |
| `Access denied` | Caller's IAM policy lacks `iam:GenerateCredentialReport`/`iam:GetCredentialReport` | Grant both actions (they're commonly bundled in `IAMReadOnlyAccess`) |
| `Timed out waiting for IAM credential report to generate` | Report generation took longer than the poll budget (rare, large accounts) | Re-run the script; the report is often cached and ready on retry |
| No findings printed | Account genuinely has no old keys / MFA gaps / unused creds within thresholds | Expected - tighten `--max-key-age-days`/`--unused-threshold-days` to audit more aggressively |

## References

- [`generate_credential_report` / `get_credential_report` (boto3 IAM client)](https://boto3.amazonaws.com/v1/documentation/api/latest/reference/services/iam/client/get_credential_report.html)
- [Getting credential reports for your AWS account](https://docs.aws.amazon.com/IAM/latest/UserGuide/id_credentials_getting-report.html)
