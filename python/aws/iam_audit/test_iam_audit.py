#!/usr/bin/env python3
"""Unit tests for iam_audit.py. No AWS credentials or network access required."""
import csv
import datetime
import io
import json
import os
import subprocess
import sys
import tempfile
import unittest
from unittest import mock

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

import iam_audit as mod

NOW = datetime.datetime(2026, 7, 31, tzinfo=datetime.timezone.utc)

SAMPLE_CSV = """user,arn,user_creation_time,password_enabled,password_last_used,password_last_changed,password_next_rotation,mfa_active,access_key_1_active,access_key_1_last_rotated,access_key_1_last_used_date,access_key_1_last_used_region,access_key_1_last_used_service,access_key_2_active,access_key_2_last_rotated,access_key_2_last_used_date,access_key_2_last_used_region,access_key_2_last_used_service,cert_1_active,cert_1_last_rotated,cert_2_active,cert_2_last_rotated
<root_account>,arn:aws:iam::123456789012:root,2020-01-01T00:00:00+00:00,true,2026-07-30T00:00:00+00:00,2020-01-01T00:00:00+00:00,N/A,false,false,N/A,N/A,N/A,N/A,false,N/A,N/A,N/A,N/A,false,N/A,false,N/A
alice,arn:aws:iam::123456789012:user/alice,2024-01-01T00:00:00+00:00,true,2026-07-30T00:00:00+00:00,2024-01-01T00:00:00+00:00,N/A,true,true,2026-07-01T00:00:00+00:00,2026-07-29T00:00:00+00:00,us-east-1,ec2,false,N/A,N/A,N/A,N/A,false,N/A,false,N/A
bob,arn:aws:iam::123456789012:user/bob,2023-01-01T00:00:00+00:00,true,2025-01-01T00:00:00+00:00,2023-01-01T00:00:00+00:00,N/A,false,true,2024-01-01T00:00:00+00:00,2024-06-01T00:00:00+00:00,us-east-1,s3,false,N/A,N/A,N/A,N/A,false,N/A,false,N/A
carol,arn:aws:iam::123456789012:user/carol,2025-01-01T00:00:00+00:00,false,N/A,N/A,N/A,false,true,2026-07-20T00:00:00+00:00,N/A,N/A,N/A,false,N/A,N/A,N/A,N/A,false,N/A,false,N/A
"""


class TestParseIamDate(unittest.TestCase):
    def test_valid_date(self):
        d = mod.parse_iam_date("2026-07-01T00:00:00+00:00")
        self.assertEqual(d.year, 2026)
        self.assertEqual(d.month, 7)

    def test_na(self):
        self.assertIsNone(mod.parse_iam_date("N/A"))

    def test_not_supported(self):
        self.assertIsNone(mod.parse_iam_date("not_supported"))

    def test_no_information(self):
        self.assertIsNone(mod.parse_iam_date("no_information"))

    def test_empty(self):
        self.assertIsNone(mod.parse_iam_date(""))

    def test_garbage(self):
        self.assertIsNone(mod.parse_iam_date("not-a-date"))


class TestDaysSince(unittest.TestCase):
    def test_none_date(self):
        self.assertIsNone(mod.days_since(None, NOW))

    def test_days_computed(self):
        d = datetime.datetime(2026, 7, 1, tzinfo=datetime.timezone.utc)
        self.assertEqual(mod.days_since(d, NOW), 30)

    def test_naive_date_treated_as_utc(self):
        d = datetime.datetime(2026, 7, 1)
        self.assertEqual(mod.days_since(d, NOW), 30)


class TestParseCredentialReport(unittest.TestCase):
    def test_parses_rows(self):
        rows = mod.parse_credential_report(SAMPLE_CSV)
        self.assertEqual(len(rows), 4)
        usernames = [r["user"] for r in rows]
        self.assertIn("alice", usernames)
        self.assertIn("bob", usernames)


class TestFindOldAccessKeys(unittest.TestCase):
    def setUp(self):
        self.rows = mod.parse_credential_report(SAMPLE_CSV)

    def test_finds_bob_old_key(self):
        result = mod.find_old_access_keys(self.rows, 90, NOW)
        users = [r["User"] for r in result]
        self.assertIn("bob", users)
        self.assertNotIn("alice", users)  # rotated 30 days ago, under threshold

    def test_excludes_root(self):
        result = mod.find_old_access_keys(self.rows, 1, NOW)
        users = [r["User"] for r in result]
        self.assertNotIn("<root_account>", users)

    def test_carol_key_within_threshold(self):
        result = mod.find_old_access_keys(self.rows, 90, NOW)
        users = [r["User"] for r in result]
        self.assertNotIn("carol", users)  # rotated 11 days ago


class TestFindUsersWithoutMfa(unittest.TestCase):
    def setUp(self):
        self.rows = mod.parse_credential_report(SAMPLE_CSV)

    def test_finds_bob(self):
        result = mod.find_users_without_mfa(self.rows)
        self.assertIn("bob", result)

    def test_excludes_alice_with_mfa(self):
        result = mod.find_users_without_mfa(self.rows)
        self.assertNotIn("alice", result)

    def test_excludes_carol_no_password(self):
        result = mod.find_users_without_mfa(self.rows)
        self.assertNotIn("carol", result)

    def test_excludes_root(self):
        result = mod.find_users_without_mfa(self.rows)
        self.assertNotIn("<root_account>", result)


class TestFindUnusedCredentials(unittest.TestCase):
    def setUp(self):
        self.rows = mod.parse_credential_report(SAMPLE_CSV)

    def test_finds_bob_unused_password_and_key(self):
        result = mod.find_unused_credentials(self.rows, 90, NOW)
        bob_entries = [r for r in result if r["User"] == "bob"]
        types = [r["CredentialType"] for r in bob_entries]
        self.assertIn("password", types)
        self.assertIn("access_key_1", types)

    def test_carol_never_used_key(self):
        result = mod.find_unused_credentials(self.rows, 90, NOW)
        carol_entries = [r for r in result if r["User"] == "carol"]
        self.assertEqual(len(carol_entries), 1)
        self.assertEqual(carol_entries[0]["LastUsedDaysAgo"], "never")

    def test_alice_recently_used_not_flagged(self):
        result = mod.find_unused_credentials(self.rows, 90, NOW)
        alice_entries = [r for r in result if r["User"] == "alice"]
        self.assertEqual(alice_entries, [])


class TestBuildIssueRows(unittest.TestCase):
    def test_combines_all_three(self):
        old_keys = [{"User": "bob", "AccessKeyNumber": 1, "AgeDays": 100}]
        no_mfa = ["bob"]
        unused = [{"User": "bob", "CredentialType": "password", "LastUsedDaysAgo": 200}]
        issues = mod.build_issue_rows(old_keys, no_mfa, unused)
        self.assertEqual(len(issues), 3)
        types = {i["IssueType"] for i in issues}
        self.assertEqual(types, {"OldAccessKey", "NoMFA", "UnusedCredential"})

    def test_never_used_detail(self):
        unused = [{"User": "carol", "CredentialType": "access_key_1", "LastUsedDaysAgo": "never"}]
        issues = mod.build_issue_rows([], [], unused)
        self.assertIn("never used", issues[0]["Detail"])


class TestFetchCredentialReport(unittest.TestCase):
    def test_returns_immediately_when_ready(self):
        fake_client = mock.Mock()
        fake_client.get_credential_report.return_value = {"Content": b"user,arn\n"}
        result = mod.fetch_credential_report(fake_client, max_attempts=3, poll_interval=0)
        self.assertEqual(result, "user,arn\n")
        fake_client.generate_credential_report.assert_called_once()

    def test_polls_until_ready(self):
        from botocore.exceptions import ClientError

        fake_client = mock.Mock()
        in_progress_error = ClientError(
            {"Error": {"Code": "ReportInProgress", "Message": "in progress"}},
            "GetCredentialReport",
        )
        fake_client.get_credential_report.side_effect = [
            in_progress_error,
            {"Content": b"user,arn\n"},
        ]
        result = mod.fetch_credential_report(fake_client, max_attempts=5, poll_interval=0)
        self.assertEqual(result, "user,arn\n")

    def test_times_out(self):
        from botocore.exceptions import ClientError

        fake_client = mock.Mock()
        in_progress_error = ClientError(
            {"Error": {"Code": "ReportInProgress", "Message": "in progress"}},
            "GetCredentialReport",
        )
        fake_client.get_credential_report.side_effect = in_progress_error
        with self.assertRaises(TimeoutError):
            mod.fetch_credential_report(fake_client, max_attempts=2, poll_interval=0)


class TestOutputWriters(unittest.TestCase):
    def test_write_json(self):
        with tempfile.TemporaryDirectory() as tmp:
            path = os.path.join(tmp, "out.json")
            mod.write_json(path, [{"User": "bob", "IssueType": "NoMFA", "Detail": "x"}])
            with open(path) as f:
                data = json.load(f)
            self.assertEqual(data[0]["User"], "bob")

    def test_write_csv(self):
        with tempfile.TemporaryDirectory() as tmp:
            path = os.path.join(tmp, "out.csv")
            mod.write_csv(path, mod.ISSUE_FIELDNAMES, [{"User": "bob", "IssueType": "NoMFA", "Detail": "x"}])
            with open(path, newline="") as f:
                reader = list(csv.DictReader(f))
            self.assertEqual(reader[0]["User"], "bob")


class TestCLI(unittest.TestCase):
    def test_help_exits_zero(self):
        script = os.path.join(os.path.dirname(os.path.abspath(__file__)), "iam_audit.py")
        result = subprocess.run(
            [sys.executable, script, "--help"], capture_output=True, text=True
        )
        self.assertEqual(result.returncode, 0)
        self.assertIn("--max-key-age-days", result.stdout)

    def test_parse_args_defaults(self):
        args = mod.parse_args([])
        self.assertEqual(args.max_key_age_days, 90)
        self.assertEqual(args.unused_threshold_days, 90)

    def test_parse_args_custom(self):
        args = mod.parse_args(["--max-key-age-days", "30", "--unused-threshold-days", "60"])
        self.assertEqual(args.max_key_age_days, 30)
        self.assertEqual(args.unused_threshold_days, 60)


if __name__ == "__main__":
    unittest.main()
