# disk-alert

Check disk usage via `df` for a mount point (or all mounts) and alert (non-zero exit) if usage exceeds a threshold. Built for cron/monitoring wrappers.

## Purpose

Give cron or a monitoring system a simple way to catch a filling disk before it becomes an outage.

## Requirements

- `df` supporting `--output` (GNU coreutils)
- `curl` (only if using `--webhook`)

## Usage

```bash
./disk-alert.sh [options]
```

| Option | Description |
|---|---|
| `--mount PATH` | Mount point to check (default: `/`) |
| `--all` | Check every mounted filesystem instead of a single mount |
| `--threshold PCT` | Alert threshold as a percentage (default: 90) |
| `--log-file PATH` | Append timestamped results to this file |
| `--webhook URL` | POST a JSON alert when the threshold is breached |
| `-h`, `--help` | Show usage |

`--mount` and `--all` are mutually exclusive; `--all` wins if both are given.

## Examples

See [example.md](example.md).

## Output

Logs usage per checked mount. Exits `1` (and POSTs to `--webhook` if set) if any checked mount is at or above the threshold; exits `0` otherwise.

## Troubleshooting

| Symptom | Cause | Fix |
|---|---|---|
| `--mount path does not exist` | Typo or the mount isn't present | Check the path with `df` directly |
| `No mounts matched` | `--all` on a system with unparsable `df` output | Verify `df --output=target,pcent,source` works on this system |

## References

- [`df(1)`](https://man7.org/linux/man-pages/man1/df.1.html)
