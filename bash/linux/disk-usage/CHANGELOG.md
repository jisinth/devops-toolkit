# Changelog — disk-usage

## [1.0.0] - 2026-07-31

### Added
- Initial release: per-mount disk usage report via `df -hP`
- `--threshold` to alert (non-zero exit) when any mount's usage percentage is at or above the threshold
- `--top N` with `--path` to list the N largest first-level directories under a path via `du`
