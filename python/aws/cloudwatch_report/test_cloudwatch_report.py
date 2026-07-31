#!/usr/bin/env python3
"""Unit tests for cloudwatch_report.py. No AWS credentials or network access required."""
import io
import os
import subprocess
import sys
import unittest
from unittest import mock

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

import cloudwatch_report as mod


class TestExtractAlarmRow(unittest.TestCase):
    def test_full_alarm(self):
        alarm = {
            "AlarmName": "high-cpu-web-1",
            "StateValue": "ALARM",
            "MetricName": "CPUUtilization",
            "Namespace": "AWS/EC2",
            "StateUpdatedTimestamp": "2026-07-31 12:03:11+00:00",
        }
        row = mod.extract_alarm_row(alarm)
        self.assertEqual(row["AlarmName"], "high-cpu-web-1")
        self.assertEqual(row["StateValue"], "ALARM")

    def test_missing_fields(self):
        row = mod.extract_alarm_row({})
        self.assertEqual(row["AlarmName"], "")
        self.assertEqual(row["StateValue"], "")


class TestCollectAlarms(unittest.TestCase):
    def test_collect_paginated(self):
        fake_client = mock.Mock()
        fake_paginator = mock.Mock()
        fake_paginator.paginate.return_value = [
            {"MetricAlarms": [{"AlarmName": "a1", "StateValue": "OK"}]},
            {"MetricAlarms": [{"AlarmName": "a2", "StateValue": "ALARM"}]},
        ]
        fake_client.get_paginator.return_value = fake_paginator

        rows = mod.collect_alarms(fake_client)
        self.assertEqual(len(rows), 2)
        self.assertEqual([r["AlarmName"] for r in rows], ["a1", "a2"])
        fake_client.get_paginator.assert_called_once_with("describe_alarms")

    def test_state_filter_passed_through(self):
        fake_client = mock.Mock()
        fake_paginator = mock.Mock()
        fake_paginator.paginate.return_value = [{"MetricAlarms": []}]
        fake_client.get_paginator.return_value = fake_paginator

        mod.collect_alarms(fake_client, state_filter="ALARM")
        fake_paginator.paginate.assert_called_once_with(StateValue="ALARM")


class TestCollectDatapoints(unittest.TestCase):
    def test_sorts_and_flattens_datapoints(self):
        import datetime

        fake_client = mock.Mock()
        t1 = datetime.datetime(2026, 7, 31, 12, 0)
        t2 = datetime.datetime(2026, 7, 31, 12, 5)
        fake_client.get_metric_statistics.return_value = {
            "Datapoints": [
                {"Timestamp": t2, "Average": 50.0, "Unit": "Percent"},
                {"Timestamp": t1, "Average": 40.0, "Unit": "Percent"},
            ]
        }
        rows = mod.collect_datapoints(fake_client, "AWS/EC2", "CPUUtilization", 3)
        self.assertEqual(len(rows), 2)
        self.assertEqual(rows[0]["Average"], 40.0)
        self.assertEqual(rows[1]["Average"], 50.0)
        fake_client.get_metric_statistics.assert_called_once()
        call_kwargs = fake_client.get_metric_statistics.call_args.kwargs
        self.assertEqual(call_kwargs["Namespace"], "AWS/EC2")
        self.assertEqual(call_kwargs["MetricName"], "CPUUtilization")


class TestPrintTable(unittest.TestCase):
    def test_no_rows(self):
        buf = io.StringIO()
        with mock.patch("sys.stdout", buf):
            mod.print_table(["A", "B"], [])
        self.assertIn("No results found.", buf.getvalue())


class TestCLI(unittest.TestCase):
    def test_help_exits_zero(self):
        script = os.path.join(os.path.dirname(os.path.abspath(__file__)), "cloudwatch_report.py")
        result = subprocess.run([sys.executable, script, "--help"], capture_output=True, text=True)
        self.assertEqual(result.returncode, 0)
        self.assertIn("--namespace", result.stdout)
        self.assertIn("--metric-name", result.stdout)

    def test_parse_args_defaults(self):
        args = mod.parse_args([])
        self.assertIsNone(args.region)
        self.assertIsNone(args.state)
        self.assertEqual(args.hours, 3)

    def test_metric_name_requires_namespace(self):
        with self.assertRaises(SystemExit):
            mod.parse_args(["--metric-name", "CPUUtilization"])

    def test_valid_state_choice(self):
        args = mod.parse_args(["--state", "ALARM"])
        self.assertEqual(args.state, "ALARM")

    def test_invalid_state_choice_exits(self):
        with self.assertRaises(SystemExit):
            mod.parse_args(["--state", "BOGUS"])


if __name__ == "__main__":
    unittest.main()
