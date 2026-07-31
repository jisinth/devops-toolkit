# Changelog — docker-prune

## [1.0.0] - 2026-07-31

### Added
- Initial release: one-shot wrapper around `docker system prune -a --volumes --force`
- `--dry-run` mode and confirmation prompt before the destructive prune
- Before/after `docker system df` report
