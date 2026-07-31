# memory

Report memory usage (total/used/free/available/cached/swap), alert when used-memory percentage crosses a threshold, and optionally show the top memory-consuming processes.

## Purpose

Give a quick, scriptable snapshot of system memory pressure suitable for cron/monitoring, with a non-zero exit when memory usage is high, plus an optional breakdown of which processes are consuming the most RAM.

## Requirements

- `free` (procps), preferred — falls back to `/proc/meminfo` if `free` isn't available
- `ps` (only required when `--top` is used; needs a procps-compatible `ps -eo ...`)
- Bash 4+

## Usage

```bash
./memory.sh [options]
```

| Option | Description |
|---|---|
| `--threshold PCT` | Alert threshold as a percentage of memory used (default: `90`) |
| `--top N` | Show the N top memory-consuming processes |
| `-h`, `--help` | Show usage |

## Examples

See [example.md](example.md).

## Output

- Prints `free -h` (total/used/free/shared/buff-cache/available) and a swap line.
- Falls back to parsing `/proc/meminfo` directly when `free` isn't installed.
- With `--top N`, prints the N processes with the highest `%mem` via `ps -eo pid,ppid,%mem,%cpu,comm --sort=-%mem`.
- Exits non-zero if used-memory percentage is at or above `--threshold`, or if memory info can't be determined.

## Troubleshooting

| Symptom | Cause | Fix |
|---|---|---|
| `Neither 'free' nor a readable /proc/meminfo is available` | Running in a minimal/non-Linux environment | Run on a real Linux host, or install procps |
| `--top requires 'ps', which was not found` | `ps` missing / not on `PATH` | Install procps |
| `Available: 0 MiB` / `Cached: 0 MiB` in the fallback path | `/proc/meminfo` on this system lacks `MemAvailable`/`Cached` fields (rare, older kernels or non-standard environments) | Install/use `free` instead, or update the kernel |
| Script exits 1 with no obvious alert | Memory usage crossed the threshold — check the `ERROR` line | Free memory or raise `--threshold` |

## References

- [`free(1)`](https://man7.org/linux/man-pages/man1/free.1.html)
- [`proc(5)` — /proc/meminfo](https://man7.org/linux/man-pages/man5/proc.5.html)
- [`ps(1)`](https://man7.org/linux/man-pages/man1/ps.1.html)
