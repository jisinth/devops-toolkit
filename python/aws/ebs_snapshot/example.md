# ebs_snapshot examples

## List volumes and snapshot coverage in the default region

```bash
python ebs_snapshot.py
```

```
Region     VolumeId              State      SizeGiB  VolumeType  AvailabilityZone  Unattached  SnapshotCount
---------  --------------------  ---------  -------  ----------  ----------------  ----------  -------------
us-east-1  vol-0123456789abcdef  in-use     100      gp3         us-east-1a        False       3
us-east-1  vol-0fedcba987654321  available  50       gp2         us-east-1b        True        0

1 unattached (available) volume(s) found.
```

## List only unattached volumes

```bash
python ebs_snapshot.py --unattached-only
```

```
Region     VolumeId              State      SizeGiB  VolumeType  AvailabilityZone  Unattached  SnapshotCount
---------  --------------------  ---------  -------  ----------  ----------------  ----------  -------------
us-east-1  vol-0fedcba987654321  available  50       gp2         us-east-1b        True        0

1 unattached (available) volume(s) found.
```

## Create a snapshot of a specific volume

```bash
python ebs_snapshot.py --region us-east-1 --create vol-0fedcba987654321 --description "pre-decommission backup"
```

```
Created snapshot snap-0a1b2c3d4e5f67890 of volume vol-0fedcba987654321 in us-east-1 (state: pending)
```

## Write the volume inventory to JSON

```bash
python ebs_snapshot.py --output ebs-report.json
```

```
Region     VolumeId              State   SizeGiB  VolumeType  AvailabilityZone  Unattached  SnapshotCount
---------  --------------------  ------  -------  ----------  ----------------  ----------  -------------
us-east-1  vol-0123456789abcdef  in-use  100      gp3         us-east-1a        False       3
Wrote ebs-report.json
```
