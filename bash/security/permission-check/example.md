# permission-check examples

## Scoped to a web root

```bash
./permission-check.sh --path /var/www
```

```
[permission-check] Scanning /var/www (this may take a while on large filesystems)...
[permission-check] World-writable files/directories:
  /var/www/html/uploads
[permission-check]   1 world-writable path(s) found.
[permission-check] SUID/SGID binaries:
  (none found)
[permission-check]   0 SUID/SGID binarie(s) found.
[permission-check] Files with no valid owner (orphaned UID/GID):
  (none found)
[permission-check]   0 orphaned-owner path(s) found.
```

## Full filesystem scan (slow)

```bash
sudo ./permission-check.sh --path /
```
