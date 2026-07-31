# permission-check

Scan a path for world-writable files/directories, SUID/SGID binaries, and files with no valid owner. Read-only.

## Purpose

Catch common filesystem permission mistakes — a world-writable config, an unexpected SUID binary, a file left behind by a deleted user — before they become a security incident.

## Requirements

- `find` supporting `-perm`, `-nouser`, `-nogroup` (GNU findutils)

## Usage

```bash
./permission-check.sh [options]
```

| Option | Description |
|---|---|
| `--path PATH` | Path to scan (default: `/`) |
| `-h`, `--help` | Show usage |

Scanning `/` can be slow on a large filesystem — scope `--path` to what you actually care about (e.g. `/var/www`, `/home`) when possible.

## Examples

See [example.md](example.md).

## Output

Three sections, each listing matching paths and a count: world-writable files/directories, SUID/SGID binaries, and files with no valid owner/group.

## Troubleshooting

| Symptom | Cause | Fix |
|---|---|---|
| Scan is very slow | Scanning a large tree (e.g. `/`) | Scope `--path` to a smaller directory |
| "Permission denied" noise suppressed | `find` errors are redirected to `/dev/null` by design | Run as root for a complete scan if needed |

## References

- [`find(1)`](https://man7.org/linux/man-pages/man1/find.1.html)
