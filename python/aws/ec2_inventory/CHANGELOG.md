# Changelog - ec2_inventory

## [1.0.0] - 2026-07-31

### Added
- Initial release: list EC2 instances (id, Name tag, type, state, AZ, private/public IP) across one or more `--region`s
- `--output` support for writing `.json` and `.csv` report files
- Clear error handling for missing credentials, access denied, and unresolved region
