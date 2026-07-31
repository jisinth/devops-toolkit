#!/usr/bin/env python3
"""Unit tests for cost_report.py (Azure). No Azure credentials or network access required."""
import os
import subprocess
import sys
import unittest
from unittest import mock

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

import cost_report as mod


class TestBuildQuery(unittest.TestCase):
    def test_month_to_date_query(self):
        q = mod.build_query()
        self.assertEqual(str(q.timeframe), "TimeframeType.MONTH_TO_DATE")
        self.assertEqual(q.dataset.grouping[0].name, "ServiceName")

    def test_custom_query_sets_time_period(self):
        q = mod.build_custom_query("2026-06-01", "2026-07-01")
        self.assertEqual(str(q.timeframe), "TimeframeType.CUSTOM")
        self.assertEqual(q.time_period.from_property, "2026-06-01")
        self.assertEqual(q.time_period.to, "2026-07-01")


class TestExtractRows(unittest.TestCase):
    def test_flattens_and_sorts_descending(self):
        result = mock.Mock()
        result.columns = [mock.Mock(name="Cost"), mock.Mock(name="ServiceName"), mock.Mock(name="Currency")]
        result.columns[0].name = "Cost"
        result.columns[1].name = "ServiceName"
        result.columns[2].name = "Currency"
        result.rows = [
            [5.0, "Storage", "USD"],
            [50.0, "Virtual Machines", "USD"],
        ]
        rows = mod.extract_rows(result)
        self.assertEqual(rows[0]["Service"], "Virtual Machines")
        self.assertEqual(rows[1]["Service"], "Storage")


class TestCollectCosts(unittest.TestCase):
    def test_uses_month_to_date_by_default(self):
        fake_client = mock.Mock()
        fake_result = mock.Mock(columns=[], rows=[])
        fake_client.query.usage.return_value = fake_result
        rows = mod.collect_costs(fake_client, "/subscriptions/abc")
        self.assertEqual(rows, [])
        fake_client.query.usage.assert_called_once()
        scope_arg = fake_client.query.usage.call_args.args[0]
        self.assertEqual(scope_arg, "/subscriptions/abc")

    def test_uses_custom_range_when_given(self):
        fake_client = mock.Mock()
        fake_client.query.usage.return_value = mock.Mock(columns=[], rows=[])
        mod.collect_costs(fake_client, "/subscriptions/abc", start="2026-06-01", end="2026-07-01")
        query_arg = fake_client.query.usage.call_args.args[1]
        self.assertEqual(str(query_arg.timeframe), "TimeframeType.CUSTOM")


class TestCLI(unittest.TestCase):
    def test_help_exits_zero(self):
        script = os.path.join(os.path.dirname(os.path.abspath(__file__)), "cost_report.py")
        result = subprocess.run([sys.executable, script, "--help"], capture_output=True, text=True, check=False)
        self.assertEqual(result.returncode, 0)
        self.assertIn("--start", result.stdout)

    def test_start_without_end_errors(self):
        with self.assertRaises(SystemExit):
            mod.parse_args(["--start", "2026-06-01"])

    def test_main_errors_without_subscription_id(self):
        with mock.patch.dict(os.environ, {}, clear=True):
            rc = mod.main([])
        self.assertEqual(rc, 1)


if __name__ == "__main__":
    unittest.main()
