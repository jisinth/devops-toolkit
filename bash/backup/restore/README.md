# restore

Restore from a backup produced by `mysql-backup.sh`, `postgres-backup.sh`, or `file-backup.sh`.

## Purpose

A single, safe entry point for restoring backups made by this toolkit — auto-detecting file vs. database restore, and refusing to act without confirmation or `--dry-run` first.

## Requirements

- `gzip` (integrity check)
- `tar` (for `.tar.gz` file restores)
- `mysql` or `psql` client (for `.sql.gz` database restores, matching `--type`)

## Usage

```bash
./restore.sh --file <backup> [options]
```

| Option | Description |
|---|---|
| `--file <path>` | Backup file to restore from (required) |
| `--target-dir <dir>` | Directory to extract a `.tar.gz` backup into |
| `--type mysql\|postgres` | Database engine for a `.sql.gz` backup (required for `.sql.gz`) |
| `--host <host>` | Database host (default: `127.0.0.1`) |
| `--port <port>` | Database port |
| `--user <user>` | Database user |
| `--password-env <VAR>` | Name of an environment variable holding the password (never pass it on the CLI) |
| `--database <name>` | Database to restore into (required for `.sql.gz`) |
| `-y`, `--yes` | Do not prompt for confirmation |
| `--dry-run` | Show what would happen without making changes |
| `-h`, `--help` | Show usage |

Running with no arguments prints usage and exits `0`.

## Examples

See [example.md](example.md).

## Output

**This is destructive** — it overwrites files at `--target-dir` or data in `--database`. It always verifies the backup's gzip (and, for file backups, tar) integrity first, and requires `--dry-run` or explicit confirmation (`-y`/prompt) before touching the target.

## Troubleshooting

| Symptom | Cause | Fix |
|---|---|---|
| `Cannot determine backup type from filename` | File doesn't end in `.tar.gz` or `.sql.gz` | Rename to match, or restore manually |
| `--type mysql\|postgres is required` | Ambiguous `.sql.gz` (both backup scripts use this extension) | Pass `--type` explicitly |
| `Backup file failed gzip integrity check` | Corrupt or truncated backup | Use a different backup; investigate how it got corrupted |

## References

- [`tar` manual](https://www.gnu.org/software/tar/manual/tar.html)
- [`mysql(1)`](https://dev.mysql.com/doc/refman/8.0/en/mysql.html)
- [`psql`](https://www.postgresql.org/docs/current/app-psql.html)
