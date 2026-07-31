# Changelog — json-pretty

## [1.0.0] - 2026-07-31

### Added
- Initial release: pretty-print JSON from `--file` or stdin
- Uses `jq` when available, falls back to `python3 -m json.tool`
- Non-zero exit with a clear error message on invalid JSON
