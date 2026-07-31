# mysql-backup examples

## Basic backup to the default `./backups` directory

```bash
export MYSQL_PWD_VALUE='s3cret'
./mysql-backup.sh --host db.internal --user backup --password-env MYSQL_PWD_VALUE --database app
```

```
[mysql-backup] Dumping database 'app' from db.internal to ./backups/app-20260731-141200.sql.gz
[mysql-backup] Backup complete.
[mysql-backup]   File:     ./backups/app-20260731-141200.sql.gz
[mysql-backup]   Size:     42M
[mysql-backup]   Duration: 18s
```

## Backup and upload to S3

```bash
./mysql-backup.sh --host db.internal --user backup --password-env MYSQL_PWD_VALUE \
    --database app --upload-s3 my-backups-bucket
```

```
[mysql-backup] Dumping database 'app' from db.internal to ./backups/app-20260731-141530.sql.gz
[mysql-backup] Uploading to s3://my-backups-bucket/app-20260731-141530.sql.gz
upload: backups/app-20260731-141530.sql.gz to s3://my-backups-bucket/app-20260731-141530.sql.gz
[mysql-backup] Backup complete.
[mysql-backup]   File:     ./backups/app-20260731-141530.sql.gz
[mysql-backup]   Size:     42M
[mysql-backup]   Duration: 19s
```

## Pause application writes with a pre-hook, resume with a post-hook

```bash
./mysql-backup.sh --database app --user backup --password-env MYSQL_PWD_VALUE \
    --pre-hook 'curl -sf -X POST http://localhost:8080/admin/pause-writes' \
    --post-hook 'curl -sf -X POST http://localhost:8080/admin/resume-writes'
```

## Copy the backup to a mounted network share instead of S3

```bash
./mysql-backup.sh --database app --user backup --password-env MYSQL_PWD_VALUE \
    --upload-dir /mnt/backup-nas/mysql
```
