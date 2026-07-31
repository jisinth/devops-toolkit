# ssh-audit

Parse an sshd_config file and flag insecure settings. Read-only.

## Purpose

A quick pass/fail check of the SSH daemon settings that matter most for security, without manually reading through `sshd_config`.

## Requirements

- A readable sshd_config file
- `awk`

## Usage

```bash
./ssh-audit.sh [options]
```

| Option | Description |
|---|---|
| `--config PATH` | Path to sshd_config (default: `/etc/ssh/sshd_config`) |
| `-h`, `--help` | Show usage |

## Examples

See [example.md](example.md).

## Output

A PASS/FAIL line per check (root login, password auth, empty passwords, X11 forwarding, protocol version), followed by a summary. Exits `1` if any check fails.

## Troubleshooting

| Symptom | Cause | Fix |
|---|---|---|
| `Cannot read sshd_config` | Wrong path, or insufficient permission | Check the path and run with `sudo` if needed |
| A setting shows "not set" as passing | The script's assumed default matches sshd's compiled-in default | Verify against `sshd -T` if you need the daemon's actual effective config |

## References

- [`sshd_config(5)`](https://man.openbsd.org/sshd_config.5)
