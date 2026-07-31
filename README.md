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

| Category | Language | Path | Scripts |
|---|---|---|---|
| Docker | Bash | [`bash/docker/`](bash/docker/) | docker-clean, docker-health, docker-images, docker-logs, docker-network, docker-prune, docker-volumes |
| Kubernetes | Bash | [`bash/kubernetes/`](bash/kubernetes/) | ingress-report, namespace-cleanup, node-health, pending-pods, pod-logs, resource-report, restart-deployment |
| Linux | Bash | [`bash/linux/`](bash/linux/) | cleanup, cpu, disk-usage, memory, process, service-status, users |
| Monitoring | Bash | [`bash/monitoring/`](bash/monitoring/) | cpu-alert, disk-alert, memory-alert, ping-check, ssl-check, website-health |
| Networking | Bash | [`bash/networking/`](bash/networking/) | dns-check, firewall-report, latency, port-check, traceroute |
| Security | Bash | [`bash/security/`](bash/security/) | permission-check, port-scan, secret-scan, ssh-audit, user-audit |
| Backup | Bash | [`bash/backup/`](bash/backup/) | database-backup, file-backup, mysql-backup, postgres-backup, restore |
| Utilities | Bash | [`bash/utilities/`](bash/utilities/) | base64, json-pretty, random-password, uuid, yaml-validate |
| AWS | Python | [`python/aws/`](python/aws/) | cloudwatch_report, cost_report, ebs_snapshot, ec2_inventory, iam_audit, rds_report, s3_inventory |
| Azure | Python | [`python/azure/`](python/azure/) | aks_report, cost_report, keyvault_audit, resource_groups, storage_report, vm_inventory |

All 60 scripts follow the same per-script folder layout — script, `README.md`, `example.md`, `test.sh`/`test_*.py`, `CHANGELOG.md` — described in [CONTRIBUTING.md](CONTRIBUTING.md). Each script's `README.md` documents its own requirements, options, and troubleshooting.

## Roadmap

See [docs/roadmap.md](docs/roadmap.md) for the phased release plan (v1.0 through v5.0, culminating in a unified `devops-toolkit` CLI).

## Contributing

Contributions are welcome. See [CONTRIBUTING.md](CONTRIBUTING.md) for the workflow each script follows: write → test → document → example → automated testing → merge → release.

## License

[MIT](LICENSE)
