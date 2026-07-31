# users

Report local users: last login, locked/expired accounts, UID 0 accounts other than root, and accounts with empty passwords.

## Purpose

A quick local-account hygiene check — the kind of thing you'd otherwise stitch together from `/etc/passwd`, `lastlog`, and `chage` by hand.

## Requirements

- Readable `/etc/passwd`
- `lastlog` and `chage` (optional — sections are skipped with a note if unavailable)
- Read access to `/etc/shadow` for the empty-password check (typically requires root; skipped with a note otherwise)

## Usage

```bash
./users.sh [options]
```

| Option | Description |
|---|---|
| `-h`, `--help` | Show usage |

## Examples

See [example.md](example.md).

## Output

Four sections: UID 0 accounts other than root, last login per user, accounts with a set expiry date, and accounts with an empty password.

## Troubleshooting

| Symptom | Cause | Fix |
|---|---|---|
| `/etc/shadow not readable (need root)` | Not running as root | Run with `sudo` to include the empty-password check |
| "'lastlog'/'chage' not available" | Minimal distro/container without `shadow-utils` | Install `shadow-utils` (or equivalent), or ignore — those sections are optional |

## References

- [`passwd(5)`](https://man7.org/linux/man-pages/man5/passwd.5.html)
- [`chage(1)`](https://man7.org/linux/man-pages/man1/chage.1.html)
