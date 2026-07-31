# users examples

## Full report (run as root for the empty-password check)

```bash
sudo ./users.sh
```

```
[users] UID 0 accounts other than root:
[users]   (none found)
[users] Last login per user:
  Username         Port     From             Latest
  root             pts/0    10.0.0.5         Thu Jul 30 09:12:03 2026
  deploy           pts/1    10.0.0.9         Thu Jul 31 08:55:41 2026
[users] Account expiry/lock status (chage):
  contractor: expires 2026-08-15
[users] Accounts with an empty password:
[users]   (none found)
```

## Run as a non-root user (empty-password check skipped)

```bash
./users.sh
```

```
[users] Accounts with an empty password:
[users]   /etc/shadow not readable (need root), skipping.
```
