# Troubleshooting

## Bash scripts

| Symptom | Likely Cause | Fix |
|---|---|---|
| `Permission denied` | Script not executable | `chmod +x script.sh` |
| `command not found: docker/kubectl/aws` | Required CLI not installed or not on `PATH` | Install the CLI tool for that category |
| Script exits immediately with no output | `set -euo pipefail` tripped on an unset variable or failed command | Re-run with `bash -x script.sh` to trace |

## Python scripts

| Symptom | Likely Cause | Fix |
|---|---|---|
| `ModuleNotFoundError` | Missing dependency | `pip install -r python/<category>/requirements.txt` |
| `NoCredentialsError` (AWS) | AWS credentials not configured | Run `aws configure` or set `AWS_PROFILE` |
| `AuthenticationError` (Azure) | Not logged in | Run `az login` |

## General

- Run with verbose/debug flags first (`-v`, `--debug`, or `bash -x`) before filing an issue.
- Check [CHANGELOG.md](../CHANGELOG.md) — a recent change may explain a behavior shift.
- Open an issue with: script name, command run, full error output, OS/shell/Python version.
