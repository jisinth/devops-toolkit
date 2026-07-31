# Changelog - rds_report

## [1.0.0] - 2026-07-31

### Added
- Initial release: list RDS instances (identifier, engine, engine version, instance class, status, Multi-AZ, allocated storage) across one or more `--region`s
- `--non-multi-az-only` filter to surface databases lacking high availability
- `--output` support for writing `.json` and `.csv` report files
- Clear error handling for missing credentials, access denied, and unresolved region
