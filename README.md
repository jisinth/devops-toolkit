# devops-toolkit

A comprehensive collection of production-ready Bash and Python scripts for DevOps, Cloud, Kubernetes, Docker, Linux administration, security, monitoring, backups, and automation.

## Why

Instead of hunting down one-off scripts across repos and gists, this toolkit collects tested, documented, and consistently-structured scripts for common operational tasks — organized by category so you can find (and trust) what you need quickly.

## Repository Structure

```
devops-toolkit/
├── bash/           Bash scripts (docker, kubernetes, linux, aws, azure, monitoring, networking, backup, security, utilities)
├── python/         Python scripts (aws, azure, kubernetes, monitoring, reports, backup, automation)
├── examples/        Example usage and sample output per category
├── configs/         Shared/sample configuration files
├── tests/           Automated tests for scripts
├── docs/            Installation, usage, troubleshooting, architecture, roadmap
└── assets/          Screenshots and diagrams used in docs
```

## Getting Started

See [docs/installation.md](docs/installation.md) to get set up and [docs/usage.md](docs/usage.md) for how to run scripts.

## Categories

| Category | Language | Path |
|---|---|---|
| Docker | Bash | `bash/docker/` |
| Kubernetes | Bash | `bash/kubernetes/` |
| Linux | Bash | `bash/linux/` |
| AWS | Python | `python/aws/` |
| Azure | Python | `python/azure/` |
| Monitoring | Bash | `bash/monitoring/` |
| Backup | Bash | `bash/backup/` |
| Security | Bash | `bash/security/` |
| Networking | Bash | `bash/networking/` |
| Utilities | Bash | `bash/utilities/` |

## Roadmap

See [docs/roadmap.md](docs/roadmap.md) for the phased release plan (v1.0 through v5.0, culminating in a unified `devops-toolkit` CLI).

## Contributing

Contributions are welcome. See [CONTRIBUTING.md](CONTRIBUTING.md) for the workflow each script follows: write → test → document → example → automated testing → merge → release.

## License

[MIT](LICENSE)
