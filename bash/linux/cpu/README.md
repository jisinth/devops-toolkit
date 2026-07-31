# cpu

Report overall CPU usage and load average, alert above a threshold, and optionally show top CPU-consuming processes.

## Purpose

A quick, dependency-light CPU check for interactive use or monitoring wrappers.

## Requirements

- Linux with a readable `/proc/stat` (and ideally `/proc/loadavg`)
- `awk`
- `ps` (only if using `--top`)

## Usage

```bash
./cpu.sh [options]
```

| Option | Description |
|---|---|
| `--threshold PCT` | Alert threshold as a percentage of CPU used (default: 90) |
| `--top N` | Show the N top CPU-consuming processes |
| `--interval SEC` | Sampling interval in seconds (default: 1) |
| `-h`, `--help` | Show usage |

## Examples

See [example.md](example.md).

## Output

Overall CPU usage % and load average (1m/5m/15m). With `--top`, also lists the top N processes by `%cpu`. Exits `1` if usage is at or above `--threshold`.

## Troubleshooting

| Symptom | Cause | Fix |
|---|---|---|
| `/proc/stat is not readable` | Not running on Linux | Run on a Linux host |
| "Load average: unavailable" | No `/proc/loadavg` and no `uptime` | Informational only, doesn't affect the usage check |

## References

- [`/proc/stat` documentation](https://man7.org/linux/man-pages/man5/proc.5.html)
