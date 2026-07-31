# iam_audit examples

## Default audit (90-day thresholds)

```bash
python iam_audit.py
```

```
User   IssueType         Detail
-----  ----------------  --------------------------------------------
bob    OldAccessKey      access_key_1 is 213 days old
bob    NoMFA             password login enabled without MFA
bob    UnusedCredential  password last used 213 days ago
bob    UnusedCredential  access_key_1 last used 61 days ago
carol  UnusedCredential  access_key_1 never used

4 IAM user(s) audited. 1 old key(s), 1 user(s) without MFA, 3 unused credential(s).
```

## Tighter key-age threshold

```bash
python iam_audit.py --max-key-age-days 30
```

```
User   IssueType     Detail
-----  ------------  ----------------------------
alice  OldAccessKey  access_key_1 is 30 days old
bob    OldAccessKey  access_key_1 is 213 days old

2 IAM user(s) audited. 2 old key(s), 1 user(s) without MFA, 3 unused credential(s).
```

## Write findings to a CSV report for a compliance ticket

```bash
python iam_audit.py --output iam-findings.csv
```

```
User   IssueType         Detail
-----  ----------------  --------------------------------------------
bob    OldAccessKey      access_key_1 is 213 days old
...
Wrote iam-findings.csv
```

## Access denied

```bash
python iam_audit.py
```

```
ERROR: Access denied (AccessDenied). Ensure the caller has iam:GenerateCredentialReport and iam:GetCredentialReport permission.
```

(exits with status 1)
