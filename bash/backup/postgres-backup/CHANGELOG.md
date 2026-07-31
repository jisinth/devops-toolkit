# Changelog — postgres-backup

## [1.0.0] - 2026-07-31

### Added
- Initial release: `pg_dump` a database via `--host`, `--port`, `--user`, `--password-env`, `--database`
- Gzip compression of the dump to `--output-dir` (default `./backups`)
- Optional upload via `--upload-s3 <bucket>` (using the `aws` CLI) or `--upload-dir <path>` (plain copy)
- Post-dump verification: non-empty file and `gzip -t` integrity check
- `--pre-hook` / `--post-hook` for application-specific pause/resume of writes
- Summary output: file, size, duration
