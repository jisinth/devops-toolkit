#!/usr/bin/env python3
"""Unit tests for vm_inventory.py. No Azure credentials or network access required."""
import os
import subprocess
import sys
import unittest
from unittest import mock

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

import vm_inventory as mod


class FakeStatus:
    def __init__(self, code):
        self.code = code


class FakeInstanceView:
    def __init__(self, statuses):
        self.statuses = statuses


class TestGetPowerState(unittest.TestCase):
    def test_finds_power_state(self):
        iv = FakeInstanceView([FakeStatus("ProvisioningState/succeeded"), FakeStatus("PowerState/running")])
        self.assertEqual(mod.get_power_state(iv), "running")

    def test_no_instance_view(self):
        self.assertEqual(mod.get_power_state(None), "unknown")

    def test_no_power_state_status(self):
        iv = FakeInstanceView([FakeStatus("ProvisioningState/succeeded")])
        self.assertEqual(mod.get_power_state(iv), "unknown")


class TestResourceGroupFromId(unittest.TestCase):
    def test_extracts_resource_group(self):
        rid = "/subscriptions/abc/resourceGroups/prod-rg/providers/Microsoft.Compute/virtualMachines/web-1"
        self.assertEqual(mod.resource_group_from_id(rid), "prod-rg")

    def test_malformed_id_returns_empty(self):
        self.assertEqual(mod.resource_group_from_id("not-a-resource-id"), "")


class TestExtractVmRow(unittest.TestCase):
    def test_full_vm(self):
        vm = mock.Mock()
        vm.name = "web-1"
        vm.location = "eastus"
        vm.hardware_profile.vm_size = "Standard_D2s_v3"
        vm.storage_profile.os_disk.os_type = "Linux"
        vm.instance_view = FakeInstanceView([FakeStatus("PowerState/running")])

        row = mod.extract_vm_row(vm, "prod-rg")
        self.assertEqual(row["Name"], "web-1")
        self.assertEqual(row["ResourceGroup"], "prod-rg")
        self.assertEqual(row["Size"], "Standard_D2s_v3")
        self.assertEqual(row["PowerState"], "running")
        self.assertEqual(row["OsType"], "Linux")


class TestCollectVms(unittest.TestCase):
    def test_collect_all_resolves_power_state_per_vm(self):
        fake_client = mock.Mock()
        vm_summary = mock.Mock(
            id="/subscriptions/abc/resourceGroups/prod-rg/providers/Microsoft.Compute/virtualMachines/web-1",
        )
        vm_summary.name = "web-1"  # mock.Mock(name=...) sets the mock's repr name, not this attribute
        fake_client.virtual_machines.list_all.return_value = [vm_summary]

        vm_detailed = mock.Mock()
        vm_detailed.name = "web-1"
        vm_detailed.location = "eastus"
        vm_detailed.hardware_profile.vm_size = "Standard_D2s_v3"
        vm_detailed.storage_profile.os_disk.os_type = "Linux"
        vm_detailed.instance_view = FakeInstanceView([FakeStatus("PowerState/running")])
        fake_client.virtual_machines.get.return_value = vm_detailed

        rows = mod.collect_vms(fake_client)
        self.assertEqual(len(rows), 1)
        self.assertEqual(rows[0]["Name"], "web-1")
        fake_client.virtual_machines.get.assert_called_once_with("prod-rg", "web-1", expand="instanceView")

    def test_collect_scoped_to_resource_group(self):
        fake_client = mock.Mock()
        vm_summary = mock.Mock(id="/subscriptions/abc/resourceGroups/prod-rg/x")
        vm_summary.name = "web-1"
        fake_client.virtual_machines.list.return_value = [vm_summary]
        detailed_vm = mock.Mock(location="eastus", instance_view=None)
        detailed_vm.name = "web-1"
        fake_client.virtual_machines.get.return_value = detailed_vm

        mod.collect_vms(fake_client, resource_group="prod-rg")
        fake_client.virtual_machines.list.assert_called_once_with("prod-rg")


class TestCLI(unittest.TestCase):
    def test_help_exits_zero(self):
        script = os.path.join(os.path.dirname(os.path.abspath(__file__)), "vm_inventory.py")
        result = subprocess.run([sys.executable, script, "--help"], capture_output=True, text=True, check=False)
        self.assertEqual(result.returncode, 0)
        self.assertIn("--resource-group", result.stdout)

    def test_parse_args_defaults(self):
        args = mod.parse_args([])
        self.assertIsNone(args.subscription_id)
        self.assertIsNone(args.resource_group)

    def test_resolve_subscription_id_prefers_explicit(self):
        with mock.patch.dict(os.environ, {"AZURE_SUBSCRIPTION_ID": "env-sub"}):
            self.assertEqual(mod.resolve_subscription_id("explicit-sub"), "explicit-sub")

    def test_resolve_subscription_id_falls_back_to_env(self):
        with mock.patch.dict(os.environ, {"AZURE_SUBSCRIPTION_ID": "env-sub"}):
            self.assertEqual(mod.resolve_subscription_id(None), "env-sub")

    def test_main_errors_without_subscription_id(self):
        with mock.patch.dict(os.environ, {}, clear=True):
            rc = mod.main([])
        self.assertEqual(rc, 1)


if __name__ == "__main__":
    unittest.main()
