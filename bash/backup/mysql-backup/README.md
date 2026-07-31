# mysql-backup

`mysqldump` a MySQL/MariaDB database, gzip-compress it, optionally upload it, verify the result, and print a summary.

## Purpose

Produce a reliable, compressed, verified backup of a single MySQL/MariaDB database with one command — without ever putting a password on the command line (visible in `ps`).

This script only handles **Create Backup → Compress → Upload Cloud → Verify** of the backup workflow. **Stop Writes** (pausing an application, flushing caches, putting a database in a consistent state) is application-specific and cannot be safely automated here — use `--pre-hook`/`--post-hook` to plug in your own commands for that.

## Requirements

- `mysqldump` on `PATH`
- `gzip` on `PATH`
- `aws` CLI on `PATH` (only if using `--upload-s3`)
- Network access to the target database host
- Bash 4+

## Usage

```bash
./mysql-backup.sh --database <name> [options]
```

| Option | Description |
|---|---|
| `--host <host>` | Database host (default: `127.0.0.1`) |
| `--port <port>` | Database port (default: mysqldump's default, 3306) |
| `--user <user>` | Database user |
| `--password-env <VAR>` | Name of an environment variable holding the password. **Never** pass the password directly on the command line. |
| `--database <name>` | Database to dump (required) |
| `--output-dir <dir>` | Directory to write the backup to (default: `./backups`) |
| `--upload-s3 <bucket>` | Upload the backup to this S3 bucket via `aws s3 cp` |
| `--upload-dir <path>` | Copy the backup to this local/mounted directory |
| `--pre-hook '<command>'` | Shell command to run before the dump starts |
| `--post-hook '<command>'` | Shell command to run after the dump completes |
| `-h`, `--help` | Show usage |

Running with no arguments prints usage and exits `0`.

## Examples

See [example.md](example.md).

## Output

- Writes `<database>-<timestamp>.sql.gz` to `--output-dir`.
- Verifies the file is non-empty and passes `gzip -t` before declaring success.
- Prints a summary: file path, size, and duration.
- Exits non-zero on any failure (missing tools, empty/corrupt dump, upload failure).

## Troubleshooting

| Symptom | Cause | Fix |
|---|---|---|
| `Required command not found on PATH: mysqldump` | `mysqldump` not installed | Install MySQL/MariaDB client tools |
| `Environment variable '<VAR>' ... is not set or empty` | `--password-env` points to an unset variable | `export <VAR>=...` before running, or use a secrets manager to set it |
| `Backup file is empty` | mysqldump produced no output (bad credentials, unreachable host, empty database) | Check `--host`/`--user`/`--password-env`, verify connectivity |
| `Backup file failed gzip integrity check` | Dump was interrupted or disk ran out of space | Check disk space and re-run |
| Upload fails with `aws` errors | Missing AWS credentials or bucket permissions | Configure AWS credentials (`aws configure` or environment) and bucket access |

## References

- [`mysqldump` reference](https://dev.mysql.com/doc/refman/8.0/en/mysqldump.html)
- [`aws s3 cp`](https://docs.aws.amazon.com/cli/latest/reference/s3/cp.html)
