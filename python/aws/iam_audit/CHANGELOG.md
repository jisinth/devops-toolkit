# Changelog - iam_audit

## [1.0.0] - 2026-07-31

### Added
- Initial release: audit IAM users via the IAM credential report API
- `--max-key-age-days` (default 90) to flag stale active access keys
- Detection of console users with password login enabled but no active MFA device
- `--unused-threshold-days` (default 90) to flag never-used or long-unused passwords/access keys
- `--output` support for writing `.json` and `.csv` findings reports
- Credential report polling with `ReportInProgress` retry handling and timeout
- Clear error handling for missing credentials and access denied
