# file-backup examples

## Basic backup of a directory

```bash
./file-backup.sh --source /var/www/app
```

```
[file-backup] Archiving /var/www/app to ./backups/app-20260731-141200.tar.gz
[file-backup] Backup complete.
[file-backup]   File:     ./backups/app-20260731-141200.tar.gz
[file-backup]   Size:     156M
[file-backup]   Duration: 8s
```

## Exclude logs and temp files

```bash
./file-backup.sh --source /var/www/app --exclude '*.log' --exclude 'tmp/*' --exclude '.git'
```

## Backup and upload to S3

```bash
./file-backup.sh --source /data/uploads --upload-s3 my-backups-bucket
```

```
[file-backup] Archiving /data/uploads to ./backups/uploads-20260731-141530.tar.gz
[file-backup] Uploading to s3://my-backups-bucket/uploads-20260731-141530.tar.gz
upload: backups/uploads-20260731-141530.tar.gz to s3://my-backups-bucket/uploads-20260731-141530.tar.gz
[file-backup] Backup complete.
[file-backup]   File:     ./backups/uploads-20260731-141530.tar.gz
[file-backup]   Size:     412M
[file-backup]   Duration: 34s
```

## Pause application writes with a pre-hook, resume with a post-hook

```bash
./file-backup.sh --source /var/lib/app-data \
    --pre-hook 'systemctl stop myapp' \
    --post-hook 'systemctl start myapp'
```
