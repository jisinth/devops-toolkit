# Changelog — secret-scan

## [1.0.0] - 2026-07-31

### Added
- Initial release: recursive directory scan for likely hardcoded secrets
- Curated regex patterns for AWS access key IDs, private key headers, generic password/secret/token/api_key assignments, Slack tokens, GitHub tokens, and bearer tokens
- `--path` to select the scan root and repeatable `--exclude` to skip paths (`.git` excluded by default)
- `file:line: pattern-name: matched line` reporting, with binary files skipped automatically
