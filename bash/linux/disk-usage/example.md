# disk-usage examples

## Default report (90% threshold)

```bash
./disk-usage.sh
```

```
[disk-usage] Disk usage per mounted filesystem (threshold: 90%):
Filesystem      Size  Used Avail Use% Mounted on
/dev/sda1        50G   22G   26G  46% /
/dev/sda2       200G  190G    5G  98% /data
tmpfs           7.8G     0  7.8G   0% /dev/shm
[disk-usage] ERROR: Mount /data at 98% usage (>= 90% threshold)
[disk-usage] ERROR: One or more mounts exceeded the 90% threshold.
```

Exits `1` because `/data` is above the threshold.

## Lower the alert threshold

```bash
./disk-usage.sh --threshold 80
```

## Show the 10 largest directories under /var

```bash
./disk-usage.sh --top 10 --path /var
```

```
[disk-usage] Disk usage per mounted filesystem (threshold: 90%):
...
[disk-usage] Top 10 largest directories under /var:
2.1G    /var/log
900M    /var/lib
300M    /var/cache
...
[disk-usage] All mounts are below the 90% threshold.
```

## Combine threshold and top-directory reporting

```bash
./disk-usage.sh --threshold 85 --top 5 --path /
```
