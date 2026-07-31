# Changelog — port-scan

## [1.0.0] - 2026-07-31

### Added
- Initial release: TCP port range scan against a single host using bash's `/dev/tcp`
- `--host` (required), `--range` (default `1-1024`), `--timeout` (default `1`s) options
- Per-port timeout enforcement via `timeout(1)` when available, with a fallback warning when it isn't
- Explicit "authorized use only" reminder printed in `--help` and at scan start
