# rds_report examples

## List RDS instances in the default region

```bash
python rds_report.py
```

```
Region     DBInstanceIdentifier  Engine    EngineVersion  DBInstanceClass  DBInstanceStatus  MultiAZ  AllocatedStorageGB
---------  --------------------  --------  -------------  ---------------  ----------------  -------  -------------------
us-east-1  prod-orders-db        postgres  15.4           db.r5.large      available         True     100
us-east-1  staging-reports-db    mysql     8.0.35         db.t3.medium     available         False    20
```

## Find databases without Multi-AZ configured

```bash
python rds_report.py --non-multi-az-only
```

```
Region     DBInstanceIdentifier  Engine  EngineVersion  DBInstanceClass  DBInstanceStatus  MultiAZ  AllocatedStorageGB
---------  --------------------  ------  -------------  ---------------  ----------------  -------  -------------------
us-east-1  staging-reports-db    mysql   8.0.35         db.t3.medium     available         False    20
```

## Check multiple regions and write a CSV report

```bash
python rds_report.py --region us-east-1 --region eu-west-1 --output rds-report.csv
```

```
Region     DBInstanceIdentifier  Engine    EngineVersion  DBInstanceClass  DBInstanceStatus  MultiAZ  AllocatedStorageGB
---------  --------------------  --------  -------------  ---------------  ----------------  -------  -------------------
us-east-1  prod-orders-db        postgres  15.4           db.r5.large      available         True     100
eu-west-1  eu-billing-db         postgres  14.9           db.m5.large      available         True     200
Wrote rds-report.csv
```

## Access denied

```bash
python rds_report.py --region us-east-1
```

```
ERROR: Access denied (AccessDenied). Ensure the caller has rds:DescribeDBInstances permission.
```

(exits with status 1)
