#!/usr/bin/env python3
"""Unit tests for storage_report.py. No Azure credentials or network access required."""
import os
import subprocess
import sys
import unittest
from unittest import mock

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

import storage_report as mod


class TestExtractAccountRow(unittest.TestCase):
    def test_full_account(self):
        account = mock.Mock()
        account.name = "prodstore1"
        account.id = "/subscriptions/abc/resourceGroups/prod-rg/providers/Microsoft.Storage/storageAccounts/prodstore1"
        account.location = "eastus"
        account.sku.name = "Standard_LRS"
        account.kind = "StorageV2"
        account.access_tier = "Hot"

        row = mod.extract_account_row(account)
        self.assertEqual(row["Name"], "prodstore1")
        self.assertEqual(row["ResourceGroup"], "prod-rg")
        self.assertEqual(row["Sku"], "Standard_LRS")
        self.assertEqual(row["AccessTier"], "Hot")


class TestCollectContainers(unittest.TestCase):
    def test_lists_containers_via_arm(self):
        fake_client = mock.Mock()
        container = mock.Mock(name="uploads", public_access="None", last_modified_time="2026-07-30T10:15:00Z")
        container.name = "uploads"
        fake_client.blob_containers.list.return_value = [container]

        account_row = {"Name": "prodstore1", "ResourceGroup": "prod-rg"}
        rows = mod.collect_containers(fake_client, account_row)
        self.assertEqual(len(rows), 1)
        self.assertEqual(rows[0]["Container"], "uploads")
        fake_client.blob_containers.list.assert_called_once_with("prod-rg", "prodstore1")

    def test_warns_and_returns_empty_on_error(self):
        from azure.core.exceptions import HttpResponseError

        fake_client = mock.Mock()
        fake_client.blob_containers.list.side_effect = HttpResponseError(message="denied")

        account_row = {"Name": "prodstore1", "ResourceGroup": "prod-rg"}
        rows = mod.collect_containers(fake_client, account_row)
        self.assertEqual(rows, [])


class TestCLI(unittest.TestCase):
    def test_help_exits_zero(self):
        script = os.path.join(os.path.dirname(os.path.abspath(__file__)), "storage_report.py")
        result = subprocess.run([sys.executable, script, "--help"], capture_output=True, text=True)
        self.assertEqual(result.returncode, 0)
        self.assertIn("--skip-containers", result.stdout)

    def test_main_errors_without_subscription_id(self):
        with mock.patch.dict(os.environ, {}, clear=True):
            rc = mod.main([])
        self.assertEqual(rc, 1)


if __name__ == "__main__":
    unittest.main()
