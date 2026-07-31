# s3_inventory examples

## List all buckets using CloudWatch-based size estimates (default)

```bash
python s3_inventory.py
```

```
Bucket           Region     SizeBytes    SizeHuman  ObjectCount  PublicAccessBlock
---------------  ---------  -----------  ---------  -----------  -----------------
app-logs-prod    us-east-1  10737418240  10.0 GB    45213        Fully blocked
static-assets    us-east-1  524288000    500.0 MB   1820         Not blocked
new-bucket       eu-west-1                          unknown                      Not configured
```

## Get exact counts with a real object listing

```bash
python s3_inventory.py --deep
```

```
Bucket           Region     SizeBytes    SizeHuman  ObjectCount  PublicAccessBlock
---------------  ---------  -----------  ---------  -----------  -----------------
app-logs-prod    us-east-1  10871234560  10.1 GB    45301        Fully blocked
static-assets    us-east-1  523912345    499.6 MB   1818         Not blocked
new-bucket       eu-west-1  0            0 B        0            Not configured
```

## Write a JSON report for downstream tooling

```bash
python s3_inventory.py --output s3-report.json
```

```
Bucket           Region     SizeBytes    SizeHuman  ObjectCount  PublicAccessBlock
---------------  ---------  -----------  ---------  -----------  -----------------
app-logs-prod    us-east-1  10737418240  10.0 GB    45213        Fully blocked
Wrote s3-report.json
```

## Access denied on public access block check

```bash
python s3_inventory.py
```

```
ERROR: Access denied (AccessDenied). Ensure the caller has s3:ListAllMyBuckets, s3:GetBucketLocation, s3:GetBucketPublicAccessBlock, cloudwatch:GetMetricStatistics (and s3:ListBucket for --deep) permissions.
```

(exits with status 1)
