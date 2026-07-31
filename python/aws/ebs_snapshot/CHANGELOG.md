# Changelog - ebs_snapshot

## [1.0.0] - 2026-07-31

### Added
- Initial release: list EBS volumes with per-volume snapshot counts across one or more `--region`s
- `--unattached-only` filter to surface volumes in the `available` (unattached) state
- `--create <volume-id>` to create a new snapshot, with optional `--description`
- `--output` support for writing `.json` and `.csv` report files
- Clear error handling for missing credentials, access denied, invalid volume, and unresolved region
