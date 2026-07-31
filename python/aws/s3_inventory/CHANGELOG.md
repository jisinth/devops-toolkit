# Changelog - s3_inventory

## [1.0.0] - 2026-07-31

### Added
- Initial release: list S3 buckets with region, size, object count, and public-access-block status
- Default CloudWatch-metric-based sizing; `--deep` for exact `list_objects_v2` totals
- `--output` support for writing `.json` and `.csv` report files
- Clear error handling for missing credentials and access denied
