#!/usr/bin/env python3
"""Unit tests for keyvault_audit.py. No Azure credentials or network access required."""
import datetime
import os
import subprocess
import sys
import unittest
from unittest import mock

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

import keyvault_audit as mod


class TestExtractVaultRow(unittest.TestCase):
    def test_rbac_vault(self):
        vault = mock.Mock()
        vault.name = "prod-kv"
        vault.id = "/subscriptions/abc/resourceGroups/prod-rg/providers/Microsoft.KeyVault/vaults/prod-kv"
        vault.location = "eastus"
        vault.properties.enable_rbac_authorization = True

        row = mod.extract_vault_row(vault)
        self.assertEqual(row["AuthorizationModel"], "RBAC")
        self.assertEqual(row["ResourceGroup"], "prod-rg")

    def test_access_policy_vault(self):
        vault = mock.Mock()
        vault.name = "legacy-kv"
        vault.id = "/subscriptions/abc/resourceGroups/dev-rg/providers/Microsoft.KeyVault/vaults/legacy-kv"
        vault.location = "westus2"
        vault.properties.enable_rbac_authorization = False

        row = mod.extract_vault_row(vault)
        self.assertEqual(row["AuthorizationModel"], "Access policies")


class TestDaysUntil(unittest.TestCase):
    def test_future_date(self):
        now = datetime.datetime(2026, 7, 31, tzinfo=datetime.timezone.utc)
        expires = datetime.datetime(2026, 8, 10, tzinfo=datetime.timezone.utc)
        self.assertEqual(mod.days_until(expires, now=now), 10)

    def test_past_date_is_negative(self):
        now = datetime.datetime(2026, 7, 31, tzinfo=datetime.timezone.utc)
        expires = datetime.datetime(2026, 7, 20, tzinfo=datetime.timezone.utc)
        self.assertLess(mod.days_until(expires, now=now), 0)


class TestFindExpiringInVault(unittest.TestCase):
    def test_returns_empty_when_data_plane_unavailable(self):
        with mock.patch.object(mod, "DATA_PLANE_AVAILABLE", False):
            rows = mod.find_expiring_in_vault("some-vault", mock.Mock(), 30)
        self.assertEqual(rows, [])

    @unittest.skipUnless(mod.DATA_PLANE_AVAILABLE, "azure-keyvault-secrets/certificates not installed")
    def test_filters_by_expiry_window(self):
        now = datetime.datetime(2026, 7, 31, tzinfo=datetime.timezone.utc)
        soon = now + datetime.timedelta(days=5)
        far = now + datetime.timedelta(days=90)

        fake_secret_client = mock.Mock()
        fake_secret_client.list_properties_of_secrets.return_value = [
            mock.Mock(name="soon-secret", expires_on=soon),
            mock.Mock(name="far-secret", expires_on=far),
            mock.Mock(name="no-expiry-secret", expires_on=None),
        ]
        fake_secret_client.list_properties_of_secrets.return_value[0].name = "soon-secret"
        fake_secret_client.list_properties_of_secrets.return_value[1].name = "far-secret"
        fake_secret_client.list_properties_of_secrets.return_value[2].name = "no-expiry-secret"

        fake_cert_client = mock.Mock()
        fake_cert_client.list_properties_of_certificates.return_value = []

        with mock.patch.object(mod, "SecretClient", return_value=fake_secret_client), mock.patch.object(
            mod, "CertificateClient", return_value=fake_cert_client
        ):
            rows = mod.find_expiring_in_vault("some-vault", mock.Mock(), 30, now=now)

        self.assertEqual(len(rows), 1)
        self.assertEqual(rows[0]["Name"], "soon-secret")
        self.assertEqual(rows[0]["Kind"], "secret")


class TestCLI(unittest.TestCase):
    def test_help_exits_zero(self):
        script = os.path.join(os.path.dirname(os.path.abspath(__file__)), "keyvault_audit.py")
        result = subprocess.run([sys.executable, script, "--help"], capture_output=True, text=True, check=False)
        self.assertEqual(result.returncode, 0)
        self.assertIn("--days", result.stdout)

    def test_parse_args_default_days(self):
        args = mod.parse_args([])
        self.assertEqual(args.days, 30)

    def test_main_errors_without_subscription_id(self):
        with mock.patch.dict(os.environ, {}, clear=True):
            rc = mod.main([])
        self.assertEqual(rc, 1)


if __name__ == "__main__":
    unittest.main()
