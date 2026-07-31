# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/).

## [Unreleased]

### Added
- Initial repository scaffold: folder structure for bash/, python/, examples/, configs/, tests/, docs/, assets/.
- README, LICENSE (MIT), CONTRIBUTING guide.
- GitHub Actions workflow stubs for ShellCheck, Python lint, unit tests, and security scanning.
- Full v1.0–v4.0 script catalog (60 scripts total), each with its own README, example, test suite, and CHANGELOG:
  - `bash/docker/`: docker-clean, docker-health, docker-images, docker-logs, docker-network, docker-prune, docker-volumes
  - `bash/kubernetes/`: ingress-report, namespace-cleanup, node-health, pending-pods, pod-logs, resource-report, restart-deployment
  - `bash/linux/`: cleanup, cpu, disk-usage, memory, process, service-status, users
  - `bash/monitoring/`: cpu-alert, disk-alert, memory-alert, ping-check, ssl-check, website-health
  - `bash/networking/`: dns-check, firewall-report, latency, port-check, traceroute
  - `bash/security/`: permission-check, port-scan, secret-scan, ssh-audit, user-audit
  - `bash/backup/`: database-backup, file-backup, mysql-backup, postgres-backup, restore
  - `bash/utilities/`: base64, json-pretty, random-password, uuid, yaml-validate
  - `python/aws/`: cloudwatch_report, cost_report, ebs_snapshot, ec2_inventory, iam_audit, rds_report, s3_inventory (+ requirements.txt)
  - `python/azure/`: aks_report, cost_report, keyvault_audit, resource_groups, storage_report, vm_inventory (+ requirements.txt)
