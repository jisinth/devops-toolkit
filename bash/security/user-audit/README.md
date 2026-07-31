# user-audit

Audit local users for security-relevant issues. Read-only.

## Purpose

A focused security pass over local accounts: empty passwords, unexpected UID 0 accounts, sudo/wheel membership, and accounts with no password expiry — the kind of checks worth running periodically on any Linux host.

## Requirements

- Readable `/etc/passwd`
- `getent` or a readable `/etc/group` (for the sudo/wheel check)
- `chage` (optional — expiry check skipped with a note if unavailable)
- Read access to `/etc/shadow` for the empty-password check (typically requires root; skipped with a note otherwise)

## Usage

```bash
./user-audit.sh [options]
```

| Option | Description |
|---|---|
| `-h`, `--help` | Show usage |

## Examples

See [example.md](example.md).

## Output

Four sections: UID 0 accounts other than root, sudo/wheel group members, accounts with an empty password, and accounts with no password expiry set.

## Troubleshooting

| Symptom | Cause | Fix |
|---|---|---|
| "/etc/shadow not readable (need root)" | Not running as root | Run with `sudo` to include the empty-password check |
| "'chage' not available" | Minimal distro/container without `shadow-utils` | Install `shadow-utils` (or equivalent), or ignore |

## References

- [`passwd(5)`](https://man7.org/linux/man-pages/man5/passwd.5.html)
- [`shadow(5)`](https://man7.org/linux/man-pages/man5/shadow.5.html)
