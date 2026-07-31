#!/usr/bin/env python3
"""Unit tests for resource_groups.py. No Azure credentials or network access required."""
import os
import subprocess
import sys
import unittest
from unittest import mock

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

import resource_groups as mod


class TestCountResourcesByType(unittest.TestCase):
    def test_counts_by_type(self):
        fake_client = mock.Mock()
        fake_client.resources.list_by_resource_group.return_value = [
            mock.Mock(type="Microsoft.Compute/virtualMachines"),
            mock.Mock(type="Microsoft.Compute/virtualMachines"),
            mock.Mock(type="Microsoft.Storage/storageAccounts"),
        ]
        counts = mod.count_resources_by_type(fake_client, "prod-rg")
        self.assertEqual(counts["Microsoft.Compute/virtualMachines"], 2)
        self.assertEqual(counts["Microsoft.Storage/storageAccounts"], 1)


class TestCollectResourceGroups(unittest.TestCase):
    def test_summary_only(self):
        fake_client = mock.Mock()
        fake_client.resource_groups.list.return_value = [mock.Mock(name="prod-rg", location="eastus")]
        fake_client.resources.list_by_resource_group.return_value = [
            mock.Mock(type="Microsoft.Compute/virtualMachines")
        ]

        summary, detail = mod.collect_resource_groups(fake_client, detailed=False)
        self.assertEqual(len(summary), 1)
        self.assertEqual(summary[0]["ResourceCount"], 1)
        self.assertEqual(detail, [])

    def test_detailed_breaks_down_by_type(self):
        fake_client = mock.Mock()
        fake_client.resource_groups.list.return_value = [mock.Mock(name="prod-rg", location="eastus")]
        fake_client.resources.list_by_resource_group.return_value = [
            mock.Mock(type="Microsoft.Compute/virtualMachines"),
            mock.Mock(type="Microsoft.Compute/virtualMachines"),
        ]

        summary, detail = mod.collect_resource_groups(fake_client, detailed=True)
        self.assertEqual(summary[0]["ResourceCount"], 2)
        self.assertEqual(len(detail), 1)
        self.assertEqual(detail[0]["Count"], 2)

    def test_detailed_empty_group_reports_none(self):
        fake_client = mock.Mock()
        fake_client.resource_groups.list.return_value = [mock.Mock(name="empty-rg", location="eastus")]
        fake_client.resources.list_by_resource_group.return_value = []

        _, detail = mod.collect_resource_groups(fake_client, detailed=True)
        self.assertEqual(detail[0]["ResourceType"], "(none)")
        self.assertEqual(detail[0]["Count"], 0)


class TestCLI(unittest.TestCase):
    def test_help_exits_zero(self):
        script = os.path.join(os.path.dirname(os.path.abspath(__file__)), "resource_groups.py")
        result = subprocess.run([sys.executable, script, "--help"], capture_output=True, text=True)
        self.assertEqual(result.returncode, 0)
        self.assertIn("--detailed", result.stdout)

    def test_main_errors_without_subscription_id(self):
        with mock.patch.dict(os.environ, {}, clear=True):
            rc = mod.main([])
        self.assertEqual(rc, 1)


if __name__ == "__main__":
    unittest.main()
