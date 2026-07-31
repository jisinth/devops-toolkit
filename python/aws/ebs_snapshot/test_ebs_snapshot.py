#!/usr/bin/env python3
"""Unit tests for ebs_snapshot.py. No AWS credentials or network access required."""
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

import ebs_snapshot as mod


class TestIsUnattached(unittest.TestCase):
    def test_available_is_unattached(self):
        self.assertTrue(mod.is_unattached({"State": "available"}))

    def test_in_use_is_attached(self):
        self.assertFalse(mod.is_unattached({"State": "in-use"}))


class TestExtractVolumeRow(unittest.TestCase):
    def test_full_volume(self):
        volume = {
            "VolumeId": "vol-0123456789abcdef0",
            "State": "available",
            "Size": 100,
            "VolumeType": "gp3",
            "AvailabilityZone": "us-east-1a",
        }
        row = mod.extract_volume_row(volume, "us-east-1", snapshot_count=2)
        self.assertEqual(row["VolumeId"], "vol-0123456789abcdef0")
        self.assertTrue(row["Unattached"])
        self.assertEqual(row["SnapshotCount"], 2)

    def test_attached_volume(self):
        volume = {"VolumeId": "vol-abc", "State": "in-use"}
        row = mod.extract_volume_row(volume, "us-east-1")
        self.assertFalse(row["Unattached"])
        self.assertEqual(row["SnapshotCount"], 0)


class TestExtractSnapshotRow(unittest.TestCase):
    def test_full_snapshot(self):
        snapshot = {
            "SnapshotId": "snap-123",
            "VolumeId": "vol-abc",
            "State": "completed",
            "Progress": "100%",
            "Description": "nightly backup",
        }
        row = mod.extract_snapshot_row(snapshot, "us-east-1")
        self.assertEqual(row["SnapshotId"], "snap-123")
        self.assertEqual(row["Progress"], "100%")


class TestGroupSnapshotsByVolume(unittest.TestCase):
    def test_groups_correctly(self):
        rows = [
            {"VolumeId": "vol-1", "SnapshotId": "snap-a"},
            {"VolumeId": "vol-1", "SnapshotId": "snap-b"},
            {"VolumeId": "vol-2", "SnapshotId": "snap-c"},
        ]
        grouped = mod.group_snapshots_by_volume(rows)
        self.assertEqual(len(grouped["vol-1"]), 2)
        self.assertEqual(len(grouped["vol-2"]), 1)

    def test_empty(self):
        self.assertEqual(mod.group_snapshots_by_volume([]), {})


class TestFilterUnattached(unittest.TestCase):
    def test_filters(self):
        rows = [
            {"VolumeId": "a", "Unattached": True},
            {"VolumeId": "b", "Unattached": False},
        ]
        result = mod.filter_unattached(rows)
        self.assertEqual([r["VolumeId"] for r in result], ["a"])


class TestCollectVolumes(unittest.TestCase):
    def test_paginated(self):
        fake_client = mock.Mock()
        fake_paginator = mock.Mock()
        fake_paginator.paginate.return_value = [
            {"Volumes": [{"VolumeId": "vol-1", "State": "available"}]},
            {"Volumes": [{"VolumeId": "vol-2", "State": "in-use"}]},
        ]
        fake_client.get_paginator.return_value = fake_paginator
        rows = mod.collect_volumes(fake_client, "us-east-1")
        self.assertEqual(len(rows), 2)


class TestCollectSnapshots(unittest.TestCase):
    def test_uses_owner_self(self):
        fake_client = mock.Mock()
        fake_paginator = mock.Mock()
        fake_paginator.paginate.return_value = [
            {"Snapshots": [{"SnapshotId": "snap-1", "VolumeId": "vol-1"}]}
        ]
        fake_client.get_paginator.return_value = fake_paginator
        rows = mod.collect_snapshots(fake_client, "us-east-1")
        self.assertEqual(len(rows), 1)
        fake_paginator.paginate.assert_called_once_with(OwnerIds=["self"])


class TestCreateSnapshot(unittest.TestCase):
    def test_with_description(self):
        fake_client = mock.Mock()
        fake_client.create_snapshot.return_value = {"SnapshotId": "snap-new", "State": "pending"}
        resp = mod.create_snapshot(fake_client, "vol-abc", "backup")
        fake_client.create_snapshot.assert_called_once_with(
            VolumeId="vol-abc", Description="backup"
        )
        self.assertEqual(resp["SnapshotId"], "snap-new")

    def test_without_description(self):
        fake_client = mock.Mock()
        fake_client.create_snapshot.return_value = {"SnapshotId": "snap-new"}
        mod.create_snapshot(fake_client, "vol-abc")
        fake_client.create_snapshot.assert_called_once_with(VolumeId="vol-abc")


class TestCLI(unittest.TestCase):
    def test_help_exits_zero(self):
        script = os.path.join(os.path.dirname(os.path.abspath(__file__)), "ebs_snapshot.py")
        result = subprocess.run(
            [sys.executable, script, "--help"], capture_output=True, text=True
        )
        self.assertEqual(result.returncode, 0)
        self.assertIn("--create", result.stdout)
        self.assertIn("--unattached-only", result.stdout)

    def test_parse_args_create(self):
        args = mod.parse_args(["--create", "vol-abc", "--description", "test"])
        self.assertEqual(args.create, "vol-abc")
        self.assertEqual(args.description, "test")

    def test_parse_args_defaults(self):
        args = mod.parse_args([])
        self.assertIsNone(args.create)
        self.assertFalse(args.unattached_only)


if __name__ == "__main__":
    unittest.main()
