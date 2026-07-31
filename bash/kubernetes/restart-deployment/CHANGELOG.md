# Changelog — restart-deployment

## [1.0.0] - 2026-07-31

### Added
- Initial release: `kubectl rollout restart` for a `--namespace`/`--deployment`, followed by polling `kubectl rollout status`
- Configurable `--timeout`
- Clear `SUCCESS`/`FAILURE` reporting, non-zero exit on failure or timeout
