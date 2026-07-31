# cleanup

Clean temp files, old rotated logs, and package manager caches. Dry-run by default.

## Purpose

Reclaim disk space from the usual culprits (stale `/tmp` files, rotated logs, package caches) in one command, without guessing what will be deleted first.

## Requirements

- `find`, `stat`
- One of `apt-get`, `dnf`, or `yum` (auto-detected) for package cache cleanup — skipped if none is present

## Usage

```bash
./cleanup.sh [options]
```

| Option | Description |
|---|---|
| `--days N` | Age threshold in days for temp files/logs (default: 7) |
| `--tmp-dir PATH` | Directory to scan for old temp files (default: `/tmp`) |
| `--log-dir PATH` | Directory to scan for old rotated logs (default: `/var/log`) |
| `--skip-tmp` | Skip cleaning temp files |
| `--skip-logs` | Skip cleaning old logs |
| `--skip-pkg-cache` | Skip cleaning package manager caches |
| `-y`, `--yes` | Actually perform the cleanup (default: dry-run report only) |
| `-h`, `--help` | Show usage |

## Examples

See [example.md](example.md).

## Output

Per-category report of file count and size, followed by a total. Without `--yes`, nothing is deleted — it's a dry-run report only.

## Troubleshooting

| Symptom | Cause | Fix |
|---|---|---|
| Nothing was actually deleted | `-y`/`--yes` wasn't passed | Re-run with `--yes` once you've reviewed the dry-run report |
| "No supported package manager detected" | Not apt/dnf/yum, or PATH issue | Expected on non-Debian/RHEL systems; use `--skip-pkg-cache` to silence |

## References

- [`find(1)`](https://man7.org/linux/man-pages/man1/find.1.html)
