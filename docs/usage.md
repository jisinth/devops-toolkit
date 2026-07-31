# Usage

## General pattern

Every script supports `-h` / `--help` and prints usage, required arguments, and examples.

```bash
./bash/docker/docker-clean.sh --help
python3 python/aws/ec2_inventory.py --help
```

## Bash scripts

```bash
./bash/linux/disk-usage.sh --threshold 80
./bash/monitoring/ssl-check.sh example.com
```

## Python scripts

Python scripts typically follow: authenticate → collect resources → generate report (JSON/CSV) → optional notification.

```bash
python3 python/aws/ec2_inventory.py --region us-east-1 --output ec2-report.csv
```

## Output conventions

- Reports default to stdout unless `--output <file>` is given.
- Scripts exit `0` on success, non-zero on failure, and print errors to stderr.
- Destructive actions (deletes, restarts) require an explicit `--yes` / `--force` flag or prompt for confirmation.

See each script's own README (for scripts with a dedicated folder) or its `--help` output for parameters specific to that script.
