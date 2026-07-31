# Changelog — keyvault_audit

## [1.0.0] - 2026-07-31

### Added
- Initial release: lists Key Vaults with RBAC-vs-access-policy status, and secrets/certificates expiring within `--days` (default 30)
- Gracefully degrades to vault-level-only reporting if the optional data-plane packages aren't installed
