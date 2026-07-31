# cleanup examples

## Dry-run report (default)

```bash
./cleanup.sh
```

```
[cleanup] /tmp files older than 7d: 42 file(s), 1830 KB
[cleanup] Rotated logs under /var/log older than 7d: 6 file(s), 512 KB
[cleanup] Detected apt. Package cache cleanup: apt-get clean
[cleanup] (dry-run) would run: apt-get clean
[cleanup] Total: 48 file(s), 2342 KB would be removed (dry-run, use --yes to clean)
```

## Actually clean, with a longer retention window

```bash
./cleanup.sh --days 14 -y
```

## Only clean /tmp, skip logs and package cache

```bash
./cleanup.sh --skip-logs --skip-pkg-cache -y
```
