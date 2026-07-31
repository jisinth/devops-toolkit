# cost_report examples

## Current month-to-date

```bash
python3 cost_report.py
```

```
Cost by service, month-to-date:
Service                 Amount   Currency
----------------------  -------  --------
Virtual Machines         210.40  USD
Storage                   18.60  USD
Azure Kubernetes Service   9.15  USD
```

## Custom date range

```bash
python3 cost_report.py --start 2026-06-01 --end 2026-07-01
```

## Write JSON and CSV reports

```bash
python3 cost_report.py --output cost-report.json --output cost-report.csv
```
