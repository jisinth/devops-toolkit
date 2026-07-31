# docker-clean

Remove unused Docker containers, images, volumes, networks, and build cache — with a dry-run mode and a before/after disk usage report.

## Purpose

Reclaim disk space from Docker without hunting down individual `docker prune` subcommands, and without ever guessing what will be removed — `--dry-run` shows exactly what would happen first.

## Requirements

- Docker CLI on `PATH`
- Docker daemon running and reachable by the current user (no `sudo` handling is done by the script)
- Bash 4+

## Usage

```bash
./docker-clean.sh [options]
```

| Option | Description |
|---|---|
| `--containers` | Remove stopped containers |
| `--images` | Remove dangling and unused images |
| `--volumes` | Remove unused (unmounted) volumes |
| `--networks` | Remove unused networks |
| `--build-cache` | Remove the builder cache |
| `--all` | All of the above |
| `--dry-run` | Show what would be removed without removing anything |
| `-y`, `--yes` | Skip the confirmation prompt (including the volume-deletion warning) |
| `-h`, `--help` | Show usage |

Running with no arguments prints usage and exits `0`.

## Examples

See [example.md](example.md).

## Output

- Prints `docker system df` before and after cleanup so you can see reclaimed space.
- In `--dry-run` mode, prints each command that *would* run, prefixed `DRY-RUN:`, and makes no changes.
- Exits non-zero if Docker isn't installed or the daemon isn't reachable.

## Troubleshooting

| Symptom | Cause | Fix |
|---|---|---|
| `docker CLI not found on PATH` | Docker not installed / not on PATH | Install Docker, or fix `PATH` |
| `Docker daemon is not reachable` | Daemon not running, or user lacks permission | Start Docker; add user to the `docker` group or run with sufficient privileges |
| Volumes not removed | Confirmation declined | Re-run with `-y` if you're sure, after reviewing `--dry-run` output |

## References

- [`docker system df`](https://docs.docker.com/engine/reference/commandline/system_df/)
- [`docker image prune`](https://docs.docker.com/engine/reference/commandline/image_prune/)
- [`docker volume prune`](https://docs.docker.com/engine/reference/commandline/volume_prune/)
