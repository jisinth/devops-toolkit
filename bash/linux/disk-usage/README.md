# disk-usage

Report disk usage per mounted filesystem, alert when any mount crosses a threshold, and optionally show the largest directories under a path.

## Purpose

Give a quick, scriptable snapshot of filesystem usage (`df`) suitable for cron/monitoring, with a non-zero exit when any mount is running low on space, plus an optional `du`-based breakdown of what's eating space under a directory.

## Requirements

- `df` (coreutils, present on virtually all Linux systems)
- `du` (only required when `--top` is used)
- Bash 4+

## Usage

```bash
./disk-usage.sh [options]
```

| Option | Description |
|---|---|
| `--threshold PCT` | Alert threshold as a percentage (default: `90`) |
| `--top N` | Show the N largest directories under `--path` |
| `--path PATH` | Path to scan for `--top` (default: `/`) |
| `-h`, `--help` | Show usage |

## Examples

See [example.md](example.md).

## Output

- Prints `df -hP` for a human-readable view of every mounted filesystem.
- Prints an `ERROR` line to stderr for each mount at or above `--threshold`.
- With `--top N`, prints the N largest first-level directories under `--path` (via `du -h --max-depth=1 | sort -rh`).
- Exits non-zero if any mount is at or above the threshold, or if a required command is missing.

## Troubleshooting

| Symptom | Cause | Fix |
|---|---|---|
| `required command not found: df` | `df` missing / not on `PATH` | Install coreutils |
| `--path is not a directory` | `--path` doesn't exist or isn't a directory | Pass a valid directory |
| `--top` output is empty or slow | Scanning a very large tree, or permission errors on subdirectories | Narrow `--path`, or run with sufficient privileges (permission errors on `du` are suppressed, not fatal) |
| Script exits 1 with no obvious alert | A mount crossed the threshold — check the `ERROR` lines above the summary | Free space or raise `--threshold` |

## References

- [`df(1)`](https://man7.org/linux/man-pages/man1/df.1.html)
- [`du(1)`](https://man7.org/linux/man-pages/man1/du.1.html)
