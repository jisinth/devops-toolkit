#!/usr/bin/env python3
"""Unit tests for s3_inventory.py. No AWS credentials or network access required."""
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

import s3_inventory as mod


class TestFormatSize(unittest.TestCase):
    def test_bytes(self):
        self.assertEqual(mod.format_size(500), "500 B")

    def test_kb(self):
        self.assertEqual(mod.format_size(1536), "1.5 KB")

    def test_gb(self):
        self.assertEqual(mod.format_size(5 * 1024 ** 3), "5.0 GB")

    def test_none(self):
        self.assertEqual(mod.format_size(None), "unknown")

    def test_zero(self):
        self.assertEqual(mod.format_size(0), "0 B")


class TestSummarizePublicAccessBlock(unittest.TestCase):
    def test_none_config(self):
        self.assertEqual(mod.summarize_public_access_block(None), "Not configured")

    def test_fully_blocked(self):
        config = {
            "BlockPublicAcls": True,
            "IgnorePublicAcls": True,
            "BlockPublicPolicy": True,
            "RestrictPublicBuckets": True,
        }
        self.assertEqual(mod.summarize_public_access_block(config), "Fully blocked")

    def test_partially_blocked(self):
        config = {
            "BlockPublicAcls": True,
            "IgnorePublicAcls": False,
            "BlockPublicPolicy": False,
            "RestrictPublicBuckets": False,
        }
        self.assertEqual(mod.summarize_public_access_block(config), "Partially blocked")

    def test_not_blocked(self):
        config = {
            "BlockPublicAcls": False,
            "IgnorePublicAcls": False,
            "BlockPublicPolicy": False,
            "RestrictPublicBuckets": False,
        }
        self.assertEqual(mod.summarize_public_access_block(config), "Not blocked")


class TestBuildBucketRow(unittest.TestCase):
    def test_full_row(self):
        row = mod.build_bucket_row("my-bucket", "us-east-1", 2048, 10, "Fully blocked")
        self.assertEqual(row["Bucket"], "my-bucket")
        self.assertEqual(row["SizeBytes"], 2048)
        self.assertEqual(row["SizeHuman"], "2.0 KB")
        self.assertEqual(row["ObjectCount"], 10)

    def test_missing_metrics(self):
        row = mod.build_bucket_row("empty-bucket", "us-west-2", None, None, "Not configured")
        self.assertEqual(row["SizeBytes"], "")
        self.assertEqual(row["ObjectCount"], "")
        self.assertEqual(row["SizeHuman"], "unknown")


class TestGetBucketRegion(unittest.TestCase):
    def test_us_east_1_returns_none_constraint(self):
        fake_client = mock.Mock()
        fake_client.get_bucket_location.return_value = {"LocationConstraint": None}
        self.assertEqual(mod.get_bucket_region(fake_client, "b"), "us-east-1")

    def test_other_region(self):
        fake_client = mock.Mock()
        fake_client.get_bucket_location.return_value = {"LocationConstraint": "eu-west-1"}
        self.assertEqual(mod.get_bucket_region(fake_client, "b"), "eu-west-1")


class TestDeepCountBucket(unittest.TestCase):
    def test_sums_pages(self):
        fake_client = mock.Mock()
        fake_paginator = mock.Mock()
        fake_paginator.paginate.return_value = [
            {"Contents": [{"Size": 100}, {"Size": 200}]},
            {"Contents": [{"Size": 50}]},
        ]
        fake_client.get_paginator.return_value = fake_paginator
        size, count = mod.deep_count_bucket(fake_client, "b")
        self.assertEqual(size, 350)
        self.assertEqual(count, 3)

    def test_empty_bucket(self):
        fake_client = mock.Mock()
        fake_paginator = mock.Mock()
        fake_paginator.paginate.return_value = [{}]
        fake_client.get_paginator.return_value = fake_paginator
        size, count = mod.deep_count_bucket(fake_client, "b")
        self.assertEqual(size, 0)
        self.assertEqual(count, 0)


class TestOutputWriters(unittest.TestCase):
    def setUp(self):
        self.rows = [mod.build_bucket_row("b1", "us-east-1", 100, 5, "Fully blocked")]

    def test_write_json(self):
        with tempfile.TemporaryDirectory() as tmp:
            path = os.path.join(tmp, "out.json")
            mod.write_json(path, self.rows)
            with open(path) as f:
                data = json.load(f)
            self.assertEqual(data[0]["Bucket"], "b1")

    def test_write_csv(self):
        with tempfile.TemporaryDirectory() as tmp:
            path = os.path.join(tmp, "out.csv")
            mod.write_csv(path, mod.FIELDNAMES, self.rows)
            with open(path, newline="") as f:
                reader = list(csv.DictReader(f))
            self.assertEqual(reader[0]["Bucket"], "b1")


class TestCLI(unittest.TestCase):
    def test_help_exits_zero(self):
        script = os.path.join(os.path.dirname(os.path.abspath(__file__)), "s3_inventory.py")
        result = subprocess.run(
            [sys.executable, script, "--help"], capture_output=True, text=True
        )
        self.assertEqual(result.returncode, 0)
        self.assertIn("--deep", result.stdout)
        self.assertIn("--output", result.stdout)

    def test_parse_args_deep_flag(self):
        args = mod.parse_args(["--deep"])
        self.assertTrue(args.deep)

    def test_parse_args_defaults(self):
        args = mod.parse_args([])
        self.assertFalse(args.deep)
        self.assertIsNone(args.outputs)


if __name__ == "__main__":
    unittest.main()
