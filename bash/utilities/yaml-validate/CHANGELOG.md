# Changelog — yaml-validate

## [1.0.0] - 2026-07-31

### Added
- Initial release: validate one or more YAML files, or a document from stdin
- Uses `yq` when available, falls back to `python3` + `PyYAML`
- Per-file PASS/FAIL reporting, non-zero exit if any input fails
