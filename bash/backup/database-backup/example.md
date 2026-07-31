# database-backup examples

## Dispatch to mysql-backup.sh

```bash
./database-backup.sh --type mysql --host db.internal --user backup \
    --password-env MYSQL_PWD_VALUE --database app
```

```
[database-backup] Dispatching to mysql-backup.sh
[mysql-backup] Dumping database 'app' from db.internal to ./backups/app-20260731-141200.sql.gz
[mysql-backup] Backup complete.
[mysql-backup]   File:     ./backups/app-20260731-141200.sql.gz
[mysql-backup]   Size:     42M
[mysql-backup]   Duration: 18s
```

## Dispatch to postgres-backup.sh

```bash
./database-backup.sh --type postgres --host db.internal --user backup \
    --password-env PG_PWD_VALUE --database app --upload-s3 my-backups-bucket
```

```
[database-backup] Dispatching to postgres-backup.sh
[postgres-backup] Dumping database 'app' from db.internal to ./backups/app-20260731-141530.sql.gz
[postgres-backup] Uploading to s3://my-backups-bucket/app-20260731-141530.sql.gz
[postgres-backup] Backup complete.
[postgres-backup]   File:     ./backups/app-20260731-141530.sql.gz
[postgres-backup]   Size:     38M
[postgres-backup]   Duration: 16s
```

## Unsupported type

```bash
./database-backup.sh --type oracle --database app
```

```
[database-backup] ERROR: Unknown --type: oracle (expected mysql or postgres)
Usage: database-backup.sh --type mysql|postgres [options...]
...
```
