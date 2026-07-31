# user-audit examples

## As root (full report)

```bash
sudo ./user-audit.sh
```

```
[user-audit] UID 0 accounts other than root:
  (none found)
[user-audit] Members of sudo/wheel group:
  sudo: deploy,alice
[user-audit] Accounts with an empty password:
  (none found)
[user-audit] Accounts with no password expiry set:
  deploy
  alice
```

## As a non-root user (empty-password check skipped)

```bash
./user-audit.sh
```

```
[user-audit] Accounts with an empty password:
  /etc/shadow not readable (need root), skipping.
```
