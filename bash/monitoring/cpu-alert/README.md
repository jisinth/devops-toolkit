# cpu-alert

Sample current CPU usage and alert (non-zero exit) if it exceeds a threshold. Built for cron/monitoring wrappers.

## Purpose

Give cron or a monitoring system a simple, dependency-light way to check CPU load and fail loudly (exit code + optional webhook) when it's too high.

## Requirements

- Linux with a readable `/proc/stat`
- `awk`
- `curl` (only if using `--webhook`)

## Usage

```bash
./cpu-alert.sh [options]
```

| Option | Description |
|---|---|
| `--threshold PCT` | Alert threshold as a percentage (default: 90) |
| `--interval SEC` | Seconds between the two `/proc/stat` samples (default: 1) |
| `--log-file PATH` | Append timestamped results to this file |
| `--webhook URL` | POST a JSON alert when the threshold is breached |
| `-h`, `--help` | Show usage |

## Examples

See [example.md](example.md).

## Output

Prints the sampled CPU usage percentage. Exits `1` (and POSTs to `--webhook` if set) when usage is at or above the threshold; exits `0` otherwise.

## Troubleshooting

| Symptom | Cause | Fix |
|---|---|---|
| `/proc/stat not readable` | Not running on Linux / no `/proc` | Run on a Linux host |
| Webhook not received | `curl` missing, or POST failed | Check `curl` is installed; webhook failures are logged but don't fail the script |

## References

- [`/proc/stat` documentation](https://man7.org/linux/man-pages/man5/proc.5.html)
