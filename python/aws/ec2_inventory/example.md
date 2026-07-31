# ec2_inventory examples

## List instances in the default region

```bash
python ec2_inventory.py
```

```
Region     InstanceId           Name      InstanceType  State    AvailabilityZone  PrivateIpAddress  PublicIpAddress
---------  -------------------  --------  ------------  -------  ----------------  ----------------  ---------------
us-east-1  i-0123456789abcdef0  web-1     t3.micro      running  us-east-1a        10.0.1.15         203.0.113.10
us-east-1  i-0fedcba9876543210  db-1      db.r5.large   running  us-east-1b        10.0.2.20
```

## List instances across multiple regions

```bash
python ec2_inventory.py --region us-east-1 --region eu-west-1
```

## Write a JSON and CSV report while still printing the table

```bash
python ec2_inventory.py --region us-east-1 --output ec2-report.json --output ec2-report.csv
```

```
Region     InstanceId           Name   InstanceType  State    AvailabilityZone  PrivateIpAddress  PublicIpAddress
---------  -------------------  -----  ------------  -------  ----------------  ----------------  ---------------
us-east-1  i-0123456789abcdef0  web-1  t3.micro      running  us-east-1a        10.0.1.15         203.0.113.10
Wrote ec2-report.json
Wrote ec2-report.csv
```

## No credentials configured

```bash
python ec2_inventory.py --region us-east-1
```

```
ERROR: No AWS credentials found. Configure credentials via `aws configure`, environment variables, or an IAM role.
```

(exits with status 1)
