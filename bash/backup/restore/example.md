# restore examples

## Preview a file restore

```bash
./restore.sh --file backups/app-20260731-140501.tar.gz --target-dir /var/www/app --dry-run
```

```
[restore] Backup type: file archive
[restore]   Source: backups/app-20260731-140501.tar.gz
[restore]   Target: /var/www/app
[restore] DRY-RUN: would extract backups/app-20260731-140501.tar.gz into /var/www/app
[restore] DRY-RUN: contents:
[restore] DRY-RUN:   app/
[restore] DRY-RUN:   app/index.html
[restore] Dry run complete. No changes were made.
```

## Actually restore a file backup, without prompting

```bash
./restore.sh --file backups/app-20260731-140501.tar.gz --target-dir /var/www/app -y
```

## Restore a MySQL database backup

```bash
export MYSQL_RESTORE_PWD='s3cret'
./restore.sh --file backups/app-20260731-140501.sql.gz --type mysql \
  --database app --user root --password-env MYSQL_RESTORE_PWD -y
```

## Restore a PostgreSQL database backup

```bash
export PG_RESTORE_PWD='s3cret'
./restore.sh --file backups/app-20260731-140501.sql.gz --type postgres \
  --database app --user postgres --password-env PG_RESTORE_PWD -y
```
