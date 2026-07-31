# cost_report examples

## Current month-to-date

```bash
python3 cost_report.py
```

```
Cost by service, 2026-07-01 to 2026-07-31:
Service                  Amount   Unit
-----------------------  -------  ----
Amazon EC2                412.50  USD
Amazon S3                  38.20  USD
AWS Lambda                  4.10  USD
```

## A specific date range

```bash
python3 cost_report.py --start 2026-06-01 --end 2026-07-01
```

## Write JSON and CSV reports

```bash
python3 cost_report.py --output cost-report.json --output cost-report.csv
```
