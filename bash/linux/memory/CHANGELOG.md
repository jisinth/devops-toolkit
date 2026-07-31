# Changelog — memory

## [1.0.0] - 2026-07-31

### Added
- Initial release: memory report via `free -h`, with `/proc/meminfo` fallback when `free` is unavailable
- `--threshold` to alert (non-zero exit) when used-memory percentage is at or above the threshold
- `--top N` to list the N top memory-consuming processes via `ps --sort=-%mem`
- Swap usage reporting
