# Changelog — restore

## [1.0.0] - 2026-07-31

### Added
- Initial release: restores `.tar.gz` (file) or `.sql.gz` (mysql/postgres, via `--type`) backups
- `--dry-run` and confirmation/`-y` gating before any destructive action, gzip/tar integrity verification
