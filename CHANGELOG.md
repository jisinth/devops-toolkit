# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/).

## [Unreleased]

### Added
- Initial repository scaffold: folder structure for bash/, python/, examples/, configs/, tests/, docs/, assets/.
- README, LICENSE (MIT), CONTRIBUTING guide.
- GitHub Actions workflow stubs for ShellCheck, Python lint, unit tests, and security scanning.
- `bash/docker/docker-clean/docker-clean.sh`: removes unused Docker containers, images, volumes, networks, and build cache, with `--dry-run` and a before/after disk usage report.
