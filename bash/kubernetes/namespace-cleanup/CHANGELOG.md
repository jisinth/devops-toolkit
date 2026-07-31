# Changelog — namespace-cleanup

## [1.0.0] - 2026-07-31

### Added
- Initial release: report pods and namespaces stuck in `Terminating` state, for `--namespace` or `--all-namespaces`
- `--fix` to strip finalizers via `kubectl patch` (pods) and the `/finalize` subresource (namespaces, requires `jq`)
- Dry-run by default; destructive fixes require `--fix` combined with `-y`/`--yes`
