#!/usr/bin/env python3
"""Unit tests for aks_report.py. No Azure credentials or network access required."""
import os
import subprocess
import sys
import unittest
from unittest import mock

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

import aks_report as mod


class TestSummarizeNodePools(unittest.TestCase):
    def test_summarizes_multiple_pools(self):
        pools = [
            mock.Mock(name="system", vm_size="Standard_D4s_v3", count=3),
            mock.Mock(name="user", vm_size="Standard_D8s_v3", count=5),
        ]
        # mock.Mock(name=...) sets the mock's repr name, not the .name attribute;
        # set it explicitly to simulate the real SDK model attribute.
        pools[0].name = "system"
        pools[1].name = "user"
        summary = mod.summarize_node_pools(pools)
        self.assertEqual(summary, "system:Standard_D4s_v3 x3, user:Standard_D8s_v3 x5")

    def test_empty_pools(self):
        self.assertEqual(mod.summarize_node_pools(None), "")
        self.assertEqual(mod.summarize_node_pools([]), "")


class TestExtractClusterRow(unittest.TestCase):
    def test_full_cluster(self):
        cluster = mock.Mock()
        cluster.name = "prod-aks"
        cluster.id = "/subscriptions/abc/resourceGroups/prod-rg/providers/Microsoft.ContainerService/managedClusters/prod-aks"
        cluster.kubernetes_version = "1.29.4"
        cluster.provisioning_state = "Succeeded"
        cluster.location = "eastus"
        pool = mock.Mock(vm_size="Standard_D4s_v3", count=3)
        pool.name = "system"
        cluster.agent_pool_profiles = [pool]

        row = mod.extract_cluster_row(cluster)
        self.assertEqual(row["Name"], "prod-aks")
        self.assertEqual(row["ResourceGroup"], "prod-rg")
        self.assertEqual(row["KubernetesVersion"], "1.29.4")
        self.assertIn("system:Standard_D4s_v3 x3", row["NodePools"])


class TestCollectClusters(unittest.TestCase):
    def test_subscription_wide(self):
        fake_client = mock.Mock()
        cluster = mock.Mock(
            id="/subscriptions/abc/resourceGroups/prod-rg/x",
            name="prod-aks",
            kubernetes_version="1.29.4",
            provisioning_state="Succeeded",
            location="eastus",
            agent_pool_profiles=[],
        )
        fake_client.managed_clusters.list.return_value = [cluster]

        rows = mod.collect_clusters(fake_client)
        self.assertEqual(len(rows), 1)
        fake_client.managed_clusters.list.assert_called_once()

    def test_scoped_to_resource_group(self):
        fake_client = mock.Mock()
        fake_client.managed_clusters.list_by_resource_group.return_value = []
        mod.collect_clusters(fake_client, resource_group="prod-rg")
        fake_client.managed_clusters.list_by_resource_group.assert_called_once_with("prod-rg")


class TestCLI(unittest.TestCase):
    def test_help_exits_zero(self):
        script = os.path.join(os.path.dirname(os.path.abspath(__file__)), "aks_report.py")
        result = subprocess.run([sys.executable, script, "--help"], capture_output=True, text=True)
        self.assertEqual(result.returncode, 0)
        self.assertIn("--resource-group", result.stdout)

    def test_main_errors_without_subscription_id(self):
        with mock.patch.dict(os.environ, {}, clear=True):
            rc = mod.main([])
        self.assertEqual(rc, 1)


if __name__ == "__main__":
    unittest.main()
