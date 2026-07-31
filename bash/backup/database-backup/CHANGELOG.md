# Changelog — database-backup

## [1.0.0] - 2026-07-31

### Added
- Initial release: thin dispatcher taking `--type mysql|postgres`
- Resolves and execs the matching sibling script (`mysql-backup.sh` / `postgres-backup.sh`) relative to its own script directory
- Passes all other arguments through to the selected script unchanged
