# file-backup

Tar+gzip a directory, optionally upload it, verify archive integrity, and print a summary.

## Purpose

Produce a reliable, compressed, verified backup of a directory tree — with optional exclude patterns and an upload step — for anything that isn't a database (application files, config, uploads, static assets).

This script only handles **Create Backup → Compress → Upload Cloud → Verify** of the backup workflow. **Stop Writes** (pausing an application or flushing writes so the files on disk are consistent) is application-specific and cannot be safely automated here — use `--pre-hook`/`--post-hook` to plug in your own commands for that.

## Requirements

- `tar` on `PATH`
- `gzip` on `PATH`
- `aws` CLI on `PATH` (only if using `--upload-s3`)
- Bash 4+

## Usage

```bash
./file-backup.sh --source <dir> [options]
```

| Option | Description |
|---|---|
| `--source <dir>` | Directory to back up (required) |
| `--exclude <pattern>` | Pattern to exclude (repeatable), passed to `tar --exclude` |
| `--output-dir <dir>` | Directory to write the backup to (default: `./backups`) |
| `--upload-s3 <bucket>` | Upload the backup to this S3 bucket via `aws s3 cp` |
| `--upload-dir <path>` | Copy the backup to this local/mounted directory |
| `--pre-hook '<command>'` | Shell command to run before the tar starts |
| `--post-hook '<command>'` | Shell command to run after the tar completes |
| `-h`, `--help` | Show usage |

Running with no arguments prints usage and exits `0`.

## Examples

See [example.md](example.md).

## Output

- Writes `<source-dir-basename>-<timestamp>.tar.gz` to `--output-dir`.
- Verifies the archive is non-empty and passes `tar -tzf` before declaring success.
- Prints a summary: file path, size, and duration.
- Exits non-zero on any failure (missing tools, missing source, corrupt archive, upload failure).

## Troubleshooting

| Symptom | Cause | Fix |
|---|---|---|
| `Source directory does not exist` | `--source` path is wrong or not mounted | Double check the path |
| `Backup file is empty` | tar produced no output (permissions, everything excluded) | Check `--exclude` patterns and read permissions on `--source` |
| `Backup archive failed integrity check` | Archive was interrupted or disk ran out of space | Check disk space and re-run |
| Upload fails with `aws` errors | Missing AWS credentials or bucket permissions | Configure AWS credentials (`aws configure` or environment) and bucket access |

## References

- [`tar` manual](https://www.gnu.org/software/tar/manual/tar.html)
- [`aws s3 cp`](https://docs.aws.amazon.com/cli/latest/reference/s3/cp.html)
