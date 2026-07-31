#!/usr/bin/env python3
"""Unit tests for ec2_inventory.py. No AWS credentials or network access required."""
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

import ec2_inventory as mod


class TestGetNameTag(unittest.TestCase):
    def test_finds_name_tag(self):
        tags = [{"Key": "Env", "Value": "prod"}, {"Key": "Name", "Value": "web-1"}]
        self.assertEqual(mod.get_name_tag(tags), "web-1")

    def test_no_name_tag(self):
        tags = [{"Key": "Env", "Value": "prod"}]
        self.assertEqual(mod.get_name_tag(tags), "")

    def test_none_tags(self):
        self.assertEqual(mod.get_name_tag(None), "")

    def test_empty_tags(self):
        self.assertEqual(mod.get_name_tag([]), "")


class TestExtractInstanceRow(unittest.TestCase):
    def test_full_instance(self):
        instance = {
            "InstanceId": "i-0123456789abcdef0",
            "InstanceType": "t3.micro",
            "State": {"Name": "running"},
            "Placement": {"AvailabilityZone": "us-east-1a"},
            "PrivateIpAddress": "10.0.0.5",
            "PublicIpAddress": "203.0.113.5",
            "Tags": [{"Key": "Name", "Value": "web-1"}],
        }
        row = mod.extract_instance_row(instance, "us-east-1")
        self.assertEqual(
            row,
            {
                "Region": "us-east-1",
                "InstanceId": "i-0123456789abcdef0",
                "Name": "web-1",
                "InstanceType": "t3.micro",
                "State": "running",
                "AvailabilityZone": "us-east-1a",
                "PrivateIpAddress": "10.0.0.5",
                "PublicIpAddress": "203.0.113.5",
            },
        )

    def test_missing_optional_fields(self):
        instance = {"InstanceId": "i-abc", "State": {"Name": "stopped"}}
        row = mod.extract_instance_row(instance, "eu-west-1")
        self.assertEqual(row["Name"], "")
        self.assertEqual(row["PublicIpAddress"], "")
        self.assertEqual(row["AvailabilityZone"], "")


class TestCollectInstances(unittest.TestCase):
    def test_collect_paginated(self):
        fake_client = mock.Mock()
        fake_paginator = mock.Mock()
        fake_paginator.paginate.return_value = [
            {
                "Reservations": [
                    {
                        "Instances": [
                            {"InstanceId": "i-1", "State": {"Name": "running"}},
                            {"InstanceId": "i-2", "State": {"Name": "stopped"}},
                        ]
                    }
                ]
            },
            {"Reservations": [{"Instances": [{"InstanceId": "i-3", "State": {"Name": "running"}}]}]},
        ]
        fake_client.get_paginator.return_value = fake_paginator

        rows = mod.collect_instances(fake_client, "us-east-1")
        self.assertEqual(len(rows), 3)
        self.assertEqual([r["InstanceId"] for r in rows], ["i-1", "i-2", "i-3"])
        self.assertTrue(all(r["Region"] == "us-east-1" for r in rows))
        fake_client.get_paginator.assert_called_once_with("describe_instances")


class TestResolveRegions(unittest.TestCase):
    def test_explicit_regions_used(self):
        self.assertEqual(mod.resolve_regions(["us-east-1", "eu-west-1"]), ["us-east-1", "eu-west-1"])

    @mock.patch("ec2_inventory.boto3.Session")
    def test_falls_back_to_session_region(self, mock_session_cls):
        mock_session_cls.return_value.region_name = "ap-southeast-2"
        self.assertEqual(mod.resolve_regions(None), ["ap-southeast-2"])

    @mock.patch("ec2_inventory.boto3.Session")
    def test_no_region_available(self, mock_session_cls):
        mock_session_cls.return_value.region_name = None
        self.assertEqual(mod.resolve_regions(None), [])


class TestOutputWriters(unittest.TestCase):
    def setUp(self):
        self.rows = [
            {
                "Region": "us-east-1",
                "InstanceId": "i-1",
                "Name": "web-1",
                "InstanceType": "t3.micro",
                "State": "running",
                "AvailabilityZone": "us-east-1a",
                "PrivateIpAddress": "10.0.0.5",
                "PublicIpAddress": "",
            }
        ]

    def test_write_json(self):
        with tempfile.TemporaryDirectory() as tmp:
            path = os.path.join(tmp, "out.json")
            mod.write_json(path, self.rows)
            with open(path) as f:
                data = json.load(f)
            self.assertEqual(data, self.rows)

    def test_write_csv(self):
        with tempfile.TemporaryDirectory() as tmp:
            path = os.path.join(tmp, "out.csv")
            mod.write_csv(path, mod.FIELDNAMES, self.rows)
            with open(path, newline="") as f:
                reader = list(csv.DictReader(f))
            self.assertEqual(reader[0]["InstanceId"], "i-1")

    def test_unrecognized_extension_warns(self):
        with tempfile.TemporaryDirectory() as tmp:
            path = os.path.join(tmp, "out.txt")
            stderr = io.StringIO()
            with mock.patch("sys.stderr", stderr):
                mod.write_outputs(self.rows, mod.FIELDNAMES, [path])
            self.assertIn("unrecognized output extension", stderr.getvalue())
            self.assertFalse(os.path.exists(path))


class TestPrintTable(unittest.TestCase):
    def test_no_rows(self):
        buf = io.StringIO()
        with mock.patch("sys.stdout", buf):
            mod.print_table(["A", "B"], [])
        self.assertIn("No results found.", buf.getvalue())

    def test_with_rows(self):
        buf = io.StringIO()
        with mock.patch("sys.stdout", buf):
            mod.print_table(["A", "B"], [["1", "2"]])
        out = buf.getvalue()
        self.assertIn("A", out)
        self.assertIn("1", out)


class TestCLI(unittest.TestCase):
    def test_help_exits_zero(self):
        script = os.path.join(os.path.dirname(os.path.abspath(__file__)), "ec2_inventory.py")
        result = subprocess.run(
            [sys.executable, script, "--help"], capture_output=True, text=True, check=False
        )
        self.assertEqual(result.returncode, 0)
        self.assertIn("--region", result.stdout)
        self.assertIn("--output", result.stdout)

    def test_parse_args_multiple_regions(self):
        args = mod.parse_args(["--region", "us-east-1", "--region", "eu-west-1"])
        self.assertEqual(args.regions, ["us-east-1", "eu-west-1"])

    def test_parse_args_defaults(self):
        args = mod.parse_args([])
        self.assertIsNone(args.regions)
        self.assertIsNone(args.outputs)


if __name__ == "__main__":
    unittest.main()
