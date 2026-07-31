# Changelog — cleanup

## [1.0.0] - 2026-07-31

### Added
- Initial release: dry-run-by-default cleanup of old `/tmp` files, rotated logs, and package manager caches (apt/dnf/yum auto-detected)
- `-y`/`--yes` to actually perform the cleanup, `--skip-*` flags to scope it
