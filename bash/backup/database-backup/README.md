# database-backup

Thin dispatcher that routes to `mysql-backup.sh` or `postgres-backup.sh` based on `--type`, passing all other options through unchanged.

## Purpose

One entry point for database backups regardless of engine — useful in scripts/CI/cron where the database type is a parameter rather than hardcoded.

## Requirements

- `mysql-backup.sh` and `postgres-backup.sh` present as sibling scripts under `../mysql-backup/` and `../postgres-backup/` relative to this script (i.e. the standard layout of this repo)
- Whatever `mysql-backup.sh` / `postgres-backup.sh` themselves require (`mysqldump` or `pg_dump`, `gzip`, optionally `aws`)
- Bash 4+

## Usage

```bash
./database-backup.sh --type mysql|postgres [script options...]
```

| Option | Description |
|---|---|
| `--type mysql\|postgres` | Which backup script to run (required) |
| `-h`, `--help` | Show this script's usage |
| *(everything else)* | Passed through unchanged to the selected backup script |

Running with no arguments prints usage and exits `0`. For the full option list of the underlying script, run `mysql-backup.sh --help` or `postgres-backup.sh --help` directly (or see their READMEs).

## Examples

See [example.md](example.md).

## Output

Identical to whichever script it dispatches to (`mysql-backup.sh` or `postgres-backup.sh`) — this wrapper only adds a single `Dispatching to <script>` line before handing off. It `exec`s the target script, so the exit code is exactly the target script's exit code.

## Troubleshooting

| Symptom | Cause | Fix |
|---|---|---|
| `--type is required` | `--type` flag omitted | Pass `--type mysql` or `--type postgres` |
| `Unknown --type: <value>` | Typo or unsupported engine | Use exactly `mysql` or `postgres` |
| `Backup script not found or not executable` | Sibling script missing or not `chmod +x` | Verify `bash/backup/mysql-backup/mysql-backup.sh` and `bash/backup/postgres-backup/postgres-backup.sh` exist and are executable |
| Errors from `mysql-backup`/`postgres-backup` | Passed-through option is invalid for that script | See the target script's own `--help` / README / Troubleshooting table |

## References

- [mysql-backup README](../mysql-backup/README.md)
- [postgres-backup README](../postgres-backup/README.md)
