# service-status

Report systemd services in a failed state, and optionally restart them.

## Purpose

Surface failed systemd units in one command instead of remembering `systemctl --failed` syntax, with an opt-in restart path.

## Requirements

- `systemctl` (systemd-based Linux)

## Usage

```bash
./service-status.sh [options]
```

| Option | Description |
|---|---|
| `--name PATTERN` | Only consider failed services whose unit name matches this pattern |
| `--fix` | Restart matching failed services |
| `-y`, `--yes` | Skip the confirmation prompt before `--fix` acts |
| `-h`, `--help` | Show usage |

## Examples

See [example.md](example.md).

## Output

Lists matching failed unit names, then a count. Exits `1` if any matching failed services exist and `--fix` wasn't used (so it's usable in monitoring); exits `0` if none are failed, or after a successful `--fix`.

## Troubleshooting

| Symptom | Cause | Fix |
|---|---|---|
| `systemctl not found` | Not a systemd host (e.g. Alpine/OpenRC, non-Linux) | Not supported on non-systemd systems |
| Restart didn't fix it | Underlying app/config issue | Check `journalctl -u <unit>` for the real cause |

## References

- [`systemctl(1)`](https://man7.org/linux/man-pages/man1/systemctl.1.html)
