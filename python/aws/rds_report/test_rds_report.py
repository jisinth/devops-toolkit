#!/usr/bin/env python3
"""Unit tests for rds_report.py. No AWS credentials or network access required."""
import csv
import io
import json
import os
import subprocess
import sys
import tempfile
import unittest
from unittest import mock

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

import rds_report as mod


class TestExtractDbInstanceRow(unittest.TestCase):
    def test_full_instance(self):
        db_instance = {
            "DBInstanceIdentifier": "prod-db",
            "Engine": "postgres",
            "EngineVersion": "15.4",
            "DBInstanceClass": "db.r5.large",
            "DBInstanceStatus": "available",
            "MultiAZ": True,
            "AllocatedStorage": 100,
        }
        row = mod.extract_db_instance_row(db_instance, "us-east-1")
        self.assertEqual(row["DBInstanceIdentifier"], "prod-db")
        self.assertEqual(row["MultiAZ"], True)
        self.assertEqual(row["AllocatedStorageGB"], 100)
        self.assertEqual(row["Region"], "us-east-1")

    def test_missing_fields(self):
        row = mod.extract_db_instance_row({"DBInstanceIdentifier": "x"}, "eu-west-1")
        self.assertEqual(row["Engine"], "")
        self.assertEqual(row["MultiAZ"], False)
        self.assertEqual(row["AllocatedStorageGB"], "")


class TestCollectDbInstances(unittest.TestCase):
    def test_paginated(self):
        fake_client = mock.Mock()
        fake_paginator = mock.Mock()
        fake_paginator.paginate.return_value = [
            {"DBInstances": [{"DBInstanceIdentifier": "a"}, {"DBInstanceIdentifier": "b"}]},
            {"DBInstances": [{"DBInstanceIdentifier": "c"}]},
        ]
        fake_client.get_paginator.return_value = fake_paginator
        rows = mod.collect_db_instances(fake_client, "us-east-1")
        self.assertEqual(len(rows), 3)
        fake_client.get_paginator.assert_called_once_with("describe_db_instances")


class TestFilterNonMultiAz(unittest.TestCase):
    def test_filters_correctly(self):
        rows = [
            {"DBInstanceIdentifier": "a", "MultiAZ": True},
            {"DBInstanceIdentifier": "b", "MultiAZ": False},
            {"DBInstanceIdentifier": "c", "MultiAZ": False},
        ]
        filtered = mod.filter_non_multi_az(rows)
        self.assertEqual([r["DBInstanceIdentifier"] for r in filtered], ["b", "c"])

    def test_empty_input(self):
        self.assertEqual(mod.filter_non_multi_az([]), [])


class TestOutputWriters(unittest.TestCase):
    def setUp(self):
        self.rows = [mod.extract_db_instance_row(
            {"DBInstanceIdentifier": "db1", "Engine": "mysql", "AllocatedStorage": 20},
            "us-east-1",
        )]

    def test_write_json(self):
        with tempfile.TemporaryDirectory() as tmp:
            path = os.path.join(tmp, "out.json")
            mod.write_json(path, self.rows)
            with open(path) as f:
                data = json.load(f)
            self.assertEqual(data[0]["DBInstanceIdentifier"], "db1")

    def test_write_csv(self):
        with tempfile.TemporaryDirectory() as tmp:
            path = os.path.join(tmp, "out.csv")
            mod.write_csv(path, mod.FIELDNAMES, self.rows)
            with open(path, newline="") as f:
                reader = list(csv.DictReader(f))
            self.assertEqual(reader[0]["DBInstanceIdentifier"], "db1")

    def test_unrecognized_extension(self):
        with tempfile.TemporaryDirectory() as tmp:
            path = os.path.join(tmp, "out.xml")
            stderr = io.StringIO()
            with mock.patch("sys.stderr", stderr):
                mod.write_outputs(self.rows, mod.FIELDNAMES, [path])
            self.assertIn("unrecognized output extension", stderr.getvalue())


class TestCLI(unittest.TestCase):
    def test_help_exits_zero(self):
        script = os.path.join(os.path.dirname(os.path.abspath(__file__)), "rds_report.py")
        result = subprocess.run(
            [sys.executable, script, "--help"], capture_output=True, text=True, check=False
        )
        self.assertEqual(result.returncode, 0)
        self.assertIn("--region", result.stdout)
        self.assertIn("--non-multi-az-only", result.stdout)

    def test_parse_args_flag(self):
        args = mod.parse_args(["--non-multi-az-only"])
        self.assertTrue(args.non_multi_az_only)

    def test_parse_args_defaults(self):
        args = mod.parse_args([])
        self.assertFalse(args.non_multi_az_only)
        self.assertIsNone(args.regions)


if __name__ == "__main__":
    unittest.main()
