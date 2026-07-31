# storage_report examples

## Full report

```bash
python3 storage_report.py
```

```
Name        ResourceGroup  Location  Sku              Kind        AccessTier
----------  -------------  --------  ---------------  ----------  ----------
prodstore1  prod-rg        eastus    Standard_LRS     StorageV2   Hot

Containers:
Account     Container   PublicAccess  LastModifiedTime
----------  ----------  ------------  -----------------------
prodstore1  uploads     None          2026-07-30 10:15:00+00:00
```

## Accounts only, skip container listing

```bash
python3 storage_report.py --skip-containers
```
