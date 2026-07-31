# postgres-backup examples

## Basic backup to the default `./backups` directory

```bash
export PG_PWD_VALUE='s3cret'
./postgres-backup.sh --host db.internal --user backup --password-env PG_PWD_VALUE --database app
```

```
[postgres-backup] Dumping database 'app' from db.internal to ./backups/app-20260731-141200.sql.gz
[postgres-backup] Backup complete.
[postgres-backup]   File:     ./backups/app-20260731-141200.sql.gz
[postgres-backup]   Size:     38M
[postgres-backup]   Duration: 15s
```

## Backup and upload to S3

```bash
./postgres-backup.sh --host db.internal --user backup --password-env PG_PWD_VALUE \
    --database app --upload-s3 my-backups-bucket
```

```
[postgres-backup] Dumping database 'app' from db.internal to ./backups/app-20260731-141530.sql.gz
[postgres-backup] Uploading to s3://my-backups-bucket/app-20260731-141530.sql.gz
upload: backups/app-20260731-141530.sql.gz to s3://my-backups-bucket/app-20260731-141530.sql.gz
[postgres-backup] Backup complete.
[postgres-backup]   File:     ./backups/app-20260731-141530.sql.gz
[postgres-backup]   Size:     38M
[postgres-backup]   Duration: 16s
```

## Pause application writes with a pre-hook, resume with a post-hook

```bash
./postgres-backup.sh --database app --user backup --password-env PG_PWD_VALUE \
    --pre-hook 'curl -sf -X POST http://localhost:8080/admin/pause-writes' \
    --post-hook 'curl -sf -X POST http://localhost:8080/admin/resume-writes'
```

## Copy the backup to a mounted network share instead of S3

```bash
./postgres-backup.sh --database app --user backup --password-env PG_PWD_VALUE \
    --upload-dir /mnt/backup-nas/postgres
```
