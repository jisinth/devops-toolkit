#!/usr/bin/env python3
"""
iam_audit.py - Audit IAM users via the IAM credential report: access keys
older than --max-key-age-days, users without MFA enabled, and credentials
unused for longer than --unused-threshold-days.

Authenticates via boto3's default credential chain - no credentials are
read from the command line or hardcoded.
"""
import argparse
import csv
import datetime
import io
import json
import sys
import time

import boto3
from botocore.exceptions import BotoCoreError, ClientError, NoCredentialsError

ISSUE_FIELDNAMES = ["User", "IssueType", "Detail"]

ROOT_USER = "<root_account>"


def parse_iam_date(value):
    """
    Parse a credential-report date field. Returns a timezone-aware datetime,
    or None for missing/unsupported values ('N/A', 'not_supported',
    'no_information', or empty).
    """
    if not value or value in ("N/A", "not_supported", "no_information"):
        return None
    try:
        return datetime.datetime.strptime(value, "%Y-%m-%dT%H:%M:%S%z")
    except ValueError:
        try:
            return datetime.datetime.fromisoformat(value)
        except ValueError:
            return None


def days_since(date, now):
    """Whole days between `date` and `now`. Returns None if date is None."""
    if date is None:
        return None
    if date.tzinfo is not None and now.tzinfo is None:
        now = now.replace(tzinfo=datetime.timezone.utc)
    elif date.tzinfo is None and now.tzinfo is not None:
        date = date.replace(tzinfo=datetime.timezone.utc)
    return (now - date).days


def parse_credential_report(csv_text):
    """Parse the raw IAM credential report CSV text into a list of dict rows."""
    reader = csv.DictReader(io.StringIO(csv_text))
    return list(reader)


def find_old_access_keys(rows, max_age_days, now):
    """Return active access keys last rotated more than max_age_days ago."""
    results = []
    for row in rows:
        if row.get("user") == ROOT_USER:
            continue
        user = row.get("user", "")
        for key_num in (1, 2):
            if row.get(f"access_key_{key_num}_active") != "true":
                continue
            rotated = parse_iam_date(row.get(f"access_key_{key_num}_last_rotated"))
            age = days_since(rotated, now)
            if age is not None and age > max_age_days:
                results.append({"User": user, "AccessKeyNumber": key_num, "AgeDays": age})
    return results


def find_users_without_mfa(rows):
    """Return usernames with console password login enabled but no active MFA device."""
    results = []
    for row in rows:
        if row.get("user") == ROOT_USER:
            continue
        if row.get("password_enabled") == "true" and row.get("mfa_active") != "true":
            results.append(row.get("user", ""))
    return results


def find_unused_credentials(rows, unused_threshold_days, now):
    """
    Return active credentials (password or access keys) that have never been
    used, or not used within unused_threshold_days.
    """
    results = []
    for row in rows:
        if row.get("user") == ROOT_USER:
            continue
        user = row.get("user", "")

        if row.get("password_enabled") == "true":
            last_used = parse_iam_date(row.get("password_last_used"))
            age = days_since(last_used, now)
            if last_used is None or age > unused_threshold_days:
                results.append(
                    {
                        "User": user,
                        "CredentialType": "password",
                        "LastUsedDaysAgo": age if age is not None else "never",
                    }
                )

        for key_num in (1, 2):
            if row.get(f"access_key_{key_num}_active") != "true":
                continue
            last_used = parse_iam_date(row.get(f"access_key_{key_num}_last_used_date"))
            age = days_since(last_used, now)
            if last_used is None or age > unused_threshold_days:
                results.append(
                    {
                        "User": user,
                        "CredentialType": f"access_key_{key_num}",
                        "LastUsedDaysAgo": age if age is not None else "never",
                    }
                )
    return results


def build_issue_rows(old_keys, no_mfa_users, unused_creds):
    """Flatten the three finding lists into one table of {User, IssueType, Detail}."""
    issues = []
    for k in old_keys:
        issues.append(
            {
                "User": k["User"],
                "IssueType": "OldAccessKey",
                "Detail": f"access_key_{k['AccessKeyNumber']} is {k['AgeDays']} days old",
            }
        )
    for user in no_mfa_users:
        issues.append(
            {"User": user, "IssueType": "NoMFA", "Detail": "password login enabled without MFA"}
        )
    for c in unused_creds:
        days_ago = c["LastUsedDaysAgo"]
        detail = f"{c['CredentialType']} last used {days_ago} days ago" if days_ago != "never" else f"{c['CredentialType']} never used"
        issues.append({"User": c["User"], "IssueType": "UnusedCredential", "Detail": detail})
    return issues


def fetch_credential_report(iam_client, max_attempts=10, poll_interval=2):
    """
    Kick off (or reuse) the IAM credential report and poll until it's ready.
    Returns the decoded CSV text.
    """
    iam_client.generate_credential_report()
    for attempt in range(max_attempts):
        try:
            resp = iam_client.get_credential_report()
            return resp["Content"].decode("utf-8")
        except ClientError as e:
            if e.response.get("Error", {}).get("Code") == "ReportInProgress":
                if attempt == max_attempts - 1:
                    raise TimeoutError(
                        "Timed out waiting for IAM credential report to generate"
                    )
                time.sleep(poll_interval)
                continue
            raise


def print_table(headers, rows):
    if not rows:
        print("No results found.")
        return
    widths = [len(h) for h in headers]
    for row in rows:
        for i, cell in enumerate(row):
            widths[i] = max(widths[i], len(str(cell)))
    fmt = "  ".join("{:<%d}" % w for w in widths)
    print(fmt.format(*headers))
    print(fmt.format(*("-" * w for w in widths)))
    for row in rows:
        print(fmt.format(*(str(c) for c in row)))


def write_json(path, data):
    with open(path, "w", encoding="utf-8") as f:
        json.dump(data, f, indent=2, default=str)


def write_csv(path, fieldnames, rows):
    with open(path, "w", encoding="utf-8", newline="") as f:
        writer = csv.DictWriter(f, fieldnames=fieldnames)
        writer.writeheader()
        writer.writerows(rows)


def write_outputs(data, fieldnames, output_paths):
    for path in output_paths or []:
        lower = path.lower()
        if lower.endswith(".json"):
            write_json(path, data)
            print(f"Wrote {path}")
        elif lower.endswith(".csv"):
            write_csv(path, fieldnames, data)
            print(f"Wrote {path}")
        else:
            print(
                f"WARNING: unrecognized output extension for '{path}' "
                "(use .json or .csv), skipping",
                file=sys.stderr,
            )


def parse_args(argv=None):
    parser = argparse.ArgumentParser(
        description=(
            "Audit IAM users via the IAM credential report: old access keys, "
            "users without MFA, and unused credentials."
        )
    )
    parser.add_argument(
        "--max-key-age-days",
        type=int,
        default=90,
        help="Flag active access keys last rotated more than this many days ago. Default: 90.",
    )
    parser.add_argument(
        "--unused-threshold-days",
        type=int,
        default=90,
        help="Flag credentials not used within this many days (or never used). Default: 90.",
    )
    parser.add_argument(
        "--output",
        action="append",
        dest="outputs",
        metavar="FILE",
        help="Write the flattened findings table to FILE. Extension (.json or "
        ".csv) selects the format. Repeat to write multiple files.",
    )
    return parser.parse_args(argv)


def main(argv=None):
    args = parse_args(argv)

    try:
        iam_client = boto3.client("iam")
        csv_text = fetch_credential_report(iam_client)
    except NoCredentialsError:
        print(
            "ERROR: No AWS credentials found. Configure credentials via "
            "`aws configure`, environment variables, or an IAM role.",
            file=sys.stderr,
        )
        return 1
    except ClientError as e:
        code = e.response.get("Error", {}).get("Code", "Unknown")
        if code in ("AccessDenied", "AccessDeniedException"):
            print(
                f"ERROR: Access denied ({code}). Ensure the caller has "
                "iam:GenerateCredentialReport and iam:GetCredentialReport permission.",
                file=sys.stderr,
            )
        else:
            print(f"ERROR: AWS API error: {e}", file=sys.stderr)
        return 1
    except TimeoutError as e:
        print(f"ERROR: {e}", file=sys.stderr)
        return 1
    except BotoCoreError as e:
        print(f"ERROR: {e}", file=sys.stderr)
        return 1

    rows = parse_credential_report(csv_text)
    now = datetime.datetime.now(datetime.timezone.utc)

    old_keys = find_old_access_keys(rows, args.max_key_age_days, now)
    no_mfa_users = find_users_without_mfa(rows)
    unused_creds = find_unused_credentials(rows, args.unused_threshold_days, now)
    issues = build_issue_rows(old_keys, no_mfa_users, unused_creds)

    rows_as_lists = [[i[f] for f in ISSUE_FIELDNAMES] for i in issues]
    print_table(ISSUE_FIELDNAMES, rows_as_lists)
    print(
        f"\n{len(rows) - (1 if any(r.get('user') == ROOT_USER for r in rows) else 0)} "
        f"IAM user(s) audited. {len(old_keys)} old key(s), {len(no_mfa_users)} user(s) "
        f"without MFA, {len(unused_creds)} unused credential(s)."
    )

    write_outputs(issues, ISSUE_FIELDNAMES, args.outputs)
    return 0


if __name__ == "__main__":
    sys.exit(main())
