# Changelog — node-health

## [1.0.0] - 2026-07-31

### Added
- Initial release: report `Ready`, `MemoryPressure`, `DiskPressure`, `PIDPressure`, `NetworkUnavailable` per node, all nodes or `--node`
- `UNHEALTHY` flagging and non-zero exit when any node fails a condition check, for alerting/CI use
