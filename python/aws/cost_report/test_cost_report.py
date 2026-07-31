#!/usr/bin/env python3
"""Unit tests for cost_report.py. No AWS credentials or network access required."""
import datetime
import os
import subprocess
import sys
import unittest
from unittest import mock

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

import cost_report as mod


class TestMonthToDateRange(unittest.TestCase):
    def test_mid_month(self):
        start, end = mod.month_to_date_range(today=datetime.date(2026, 7, 31))
        self.assertEqual(start, "2026-07-01")
        self.assertEqual(end, "2026-07-31")


class TestExtractServiceRows(unittest.TestCase):
    def test_flattens_groups(self):
        response = {
            "ResultsByTime": [
                {
                    "Groups": [
                        {"Keys": ["Amazon EC2"], "Metrics": {"UnblendedCost": {"Amount": "10.50", "Unit": "USD"}}},
                        {"Keys": ["Amazon S3"], "Metrics": {"UnblendedCost": {"Amount": "2.00", "Unit": "USD"}}},
                    ]
                }
            ]
        }
        rows = mod.extract_service_rows(response)
        self.assertEqual(len(rows), 2)
        self.assertEqual(rows[0]["Service"], "Amazon EC2")
        self.assertEqual(rows[0]["Amount"], "10.50")


class TestMergeServiceRows(unittest.TestCase):
    def test_sums_and_sorts_descending(self):
        rows = [
            {"Service": "Amazon EC2", "Amount": "10.00", "Unit": "USD"},
            {"Service": "Amazon S3", "Amount": "2.00", "Unit": "USD"},
            {"Service": "Amazon EC2", "Amount": "5.00", "Unit": "USD"},
        ]
        merged = mod.merge_service_rows(rows)
        self.assertEqual(len(merged), 2)
        self.assertEqual(merged[0]["Service"], "Amazon EC2")
        self.assertEqual(merged[0]["Amount"], "15.00")
        self.assertEqual(merged[1]["Service"], "Amazon S3")


class TestCollectCosts(unittest.TestCase):
    def test_calls_cost_explorer_with_expected_args(self):
        fake_client = mock.Mock()
        fake_client.get_cost_and_usage.return_value = {"ResultsByTime": []}
        rows = mod.collect_costs(fake_client, "2026-07-01", "2026-07-31")
        self.assertEqual(rows, [])
        call_kwargs = fake_client.get_cost_and_usage.call_args.kwargs
        self.assertEqual(call_kwargs["TimePeriod"], {"Start": "2026-07-01", "End": "2026-07-31"})
        self.assertEqual(call_kwargs["Granularity"], "MONTHLY")


class TestCLI(unittest.TestCase):
    def test_help_exits_zero(self):
        script = os.path.join(os.path.dirname(os.path.abspath(__file__)), "cost_report.py")
        result = subprocess.run([sys.executable, script, "--help"], capture_output=True, text=True)
        self.assertEqual(result.returncode, 0)
        self.assertIn("--start", result.stdout)
        self.assertIn("--end", result.stdout)

    def test_parse_args_defaults(self):
        args = mod.parse_args([])
        self.assertIsNone(args.start)
        self.assertIsNone(args.end)


if __name__ == "__main__":
    unittest.main()
