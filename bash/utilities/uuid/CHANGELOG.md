# Changelog — uuid

## [1.0.0] - 2026-07-31

### Added
- Initial release: generate one or more UUIDv4 values via `--count`
- `--upper` and `--no-dashes` formatting options
- Uses `uuidgen` when available, falls back to a pure-bash `/dev/urandom` generator with correct version/variant bits
