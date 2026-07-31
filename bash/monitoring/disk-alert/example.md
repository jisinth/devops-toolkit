# disk-alert examples

## Check root filesystem

```bash
./disk-alert.sh
```

```
[disk-alert] / (/dev/sda1) — 62% used
[disk-alert] All checked mounts are below the 90% threshold.
```

## Check a specific mount with a lower threshold

```bash
./disk-alert.sh --mount /var --threshold 85
```

## Check every mount, run from cron with logging + webhook

```bash
*/15 * * * * /opt/devops-toolkit/bash/monitoring/disk-alert/disk-alert.sh --all --log-file /var/log/disk-alert.log --webhook https://hooks.example.com/alert
```

```
[disk-alert] / (/dev/sda1) — 62% used
[disk-alert] /data (/dev/sdb1) — 94% used
[disk-alert] ERROR: Mount /data at 94% usage (>= 90% threshold)
[disk-alert] ERROR: One or more mounts exceeded the 90% threshold.
```
