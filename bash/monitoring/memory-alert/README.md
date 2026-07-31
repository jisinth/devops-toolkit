# memory-alert

Sample current memory usage and alert (non-zero exit) if it exceeds a threshold. Built for cron/monitoring wrappers.

## Purpose

Give cron or a monitoring system a simple, dependency-light way to check memory pressure and fail loudly when it's too high.

## Requirements

- Linux with a readable `/proc/meminfo`
- `awk`
- `curl` (only if using `--webhook`)

## Usage

```bash
./memory-alert.sh [options]
```

| Option | Description |
|---|---|
| `--threshold PCT` | Alert threshold as a percentage (default: 90) |
| `--log-file PATH` | Append timestamped results to this file |
| `--webhook URL` | POST a JSON alert when the threshold is breached |
| `-h`, `--help` | Show usage |

## Examples

See [example.md](example.md).

## Output

Prints the sampled memory usage percentage (using `MemAvailable`, falling back to `MemFree` on older kernels). Exits `1` (and POSTs to `--webhook` if set) when usage is at or above the threshold; exits `0` otherwise.

## Troubleshooting

| Symptom | Cause | Fix |
|---|---|---|
| `/proc/meminfo not readable` | Not running on Linux / no `/proc` | Run on a Linux host |
| "falling back to MemFree" note | Kernel older than 3.14 | Informational only — MemFree is a less accurate signal than MemAvailable |

## References

- [`/proc/meminfo` documentation](https://man7.org/linux/man-pages/man5/proc.5.html)
