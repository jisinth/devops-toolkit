# Changelog — resource-report

## [1.0.0] - 2026-07-31

### Added
- Initial release: per-container CPU/memory requests, limits, and live usage report for `--namespace`, `--all-namespaces`, or a single `--pod`
- Flags containers missing `NO_CPU_REQUEST`, `NO_MEM_REQUEST`, `NO_CPU_LIMIT`, `NO_MEM_LIMIT`
- Graceful `N/A` usage columns when metrics-server is unavailable, instead of failing the whole report
