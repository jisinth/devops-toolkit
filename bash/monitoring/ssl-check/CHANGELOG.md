# Changelog — ssl-check

## [1.0.0] - 2026-07-31

### Added
- Initial release: checks TLS cert expiry for one or more domains via `openssl s_client`, alerts within `--days`
- `--log-file` and best-effort `--webhook` alert support
