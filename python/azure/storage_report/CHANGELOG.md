# Changelog — storage_report

## [1.0.0] - 2026-07-31

### Added
- Initial release: lists storage accounts (SKU, kind, access tier) and their containers (via the ARM blob_containers API, no data-plane key needed); `--skip-containers` option
