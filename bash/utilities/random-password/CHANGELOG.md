# Changelog — random-password

## [1.0.0] - 2026-07-31

### Added
- Initial release: generate one or more random passwords via `--count` and `--length`
- `--charset alnum|alnum-symbols` selection (default: `alnum-symbols`)
- `--no-ambiguous` to exclude visually-ambiguous characters
- Randomness sourced from `/dev/urandom` with rejection sampling to avoid modulo bias
