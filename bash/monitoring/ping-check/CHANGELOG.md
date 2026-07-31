# Changelog — ping-check

## [1.0.0] - 2026-07-31

### Added
- Initial release: pings one or more hosts, reports loss %/latency, alerts on `--max-loss`/`--max-latency-ms`
- Auto-detects Windows vs GNU/BSD `ping` output format
- `--log-file` and best-effort `--webhook` alert support
