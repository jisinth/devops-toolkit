# docker-volumes

Read-only report of Docker volumes: name, driver, mountpoint, and whether each volume is currently attached to any container.

## Purpose

Find out which volumes exist, where their data lives on disk, and — most importantly — which ones aren't attached to any container (running or stopped) and are therefore safe candidates for cleanup.

## Requirements

- Docker CLI on `PATH`
- Docker daemon running and reachable by the current user
- Bash 4+, `column` (standard on Linux/macOS/WSL/Git Bash)

## Usage

```bash
./docker-volumes.sh [options]
```

| Option | Description |
|---|---|
| `--unattached-only` | Show only volumes not attached to any container |
| `--output FORMAT` | Output format: `table` (default), `csv`, or `json` |
| `-h`, `--help` | Show usage |

This script is read-only: it never modifies Docker state.

## Examples

See [example.md](example.md).

## Output

- `table` (default): aligned columns — NAME, DRIVER, MOUNTPOINT, ATTACHED.
- `csv`: header row followed by comma-separated values.
- `json`: a JSON array of objects with `name`, `driver`, `mountpoint`, `attached` keys.
- "Attached" means at least one container (running or stopped) references the volume; unattached volumes are the ones `docker volume prune` would remove.
- Prints a message and exits `0` if there are no volumes (or none match `--unattached-only`).
- Exits non-zero if Docker isn't installed or the daemon isn't reachable.

## Troubleshooting

| Symptom | Cause | Fix |
|---|---|---|
| `docker CLI not found on PATH` | Docker not installed / not on PATH | Install Docker, or fix `PATH` |
| `Docker daemon is not reachable` | Daemon not running, or user lacks permission | Start Docker; add user to the `docker` group or run with sufficient privileges |
| `Invalid --output value` | Typo in `--output` argument | Use one of `table`, `csv`, `json` |
| Volume shows `attached: false` but you expect it to be in use | Volume is referenced by a compose file/service that isn't currently running a container | Attachment is checked against actual containers (`docker ps -a`), not compose definitions |

## References

- [`docker volume ls`](https://docs.docker.com/engine/reference/commandline/volume_ls/)
- [`docker volume inspect`](https://docs.docker.com/engine/reference/commandline/volume_inspect/)
- [`docker volume prune`](https://docs.docker.com/engine/reference/commandline/volume_prune/)
