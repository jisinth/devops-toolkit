# Changelog — pod-logs

## [1.0.0] - 2026-07-31

### Added
- Initial release: export logs for pods matching `--namespace`/`--selector` to gzip-compressed files under `--output-dir`
- `--since` to limit to recent logs, `--previous` to fetch crashed-container logs
- Per pod/container export with summary counts, non-zero exit on any failed export
