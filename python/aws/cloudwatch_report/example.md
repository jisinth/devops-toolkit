# cloudwatch_report examples

## All alarms in the default region

```bash
python3 cloudwatch_report.py
```

```
AlarmName          StateValue  MetricName   Namespace   StateUpdatedTimestamp
-----------------  ----------  -----------  ----------  ---------------------
high-cpu-web-1     ALARM       CPUUtilization  AWS/EC2  2026-07-31 12:03:11+00:00
disk-space-db-1    OK          DiskSpaceUtil   AWS/EC2  2026-07-30 08:15:44+00:00
```

## Only alarms currently firing

```bash
python3 cloudwatch_report.py --region us-east-1 --state ALARM
```

## With recent datapoints for a specific metric

```bash
python3 cloudwatch_report.py --namespace AWS/EC2 --metric-name CPUUtilization --hours 6
```

## Write a CSV report

```bash
python3 cloudwatch_report.py --output alarms.csv
```
