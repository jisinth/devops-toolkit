# docker-prune

A blunt, one-shot "nuke everything unused" wrapper around `docker system prune -a --volumes --force`, with a dry-run mode and a before/after disk usage report.

## Purpose

Sometimes you just want the simple "clean everything" button rather than picking individual resource types. `docker-prune.sh` is that button: it removes all stopped containers, all unused images (not just dangling ones), all unused networks, all unused volumes, and the build cache in a single confirmed action. For granular, flag-based cleanup of individual resource types, use [`docker-clean.sh`](../docker-clean/) instead.

## Requirements

- Docker CLI on `PATH`
- Docker daemon running and reachable by the current user (no `sudo` handling is done by the script)
- Bash 4+

## Usage

```bash
./docker-prune.sh [options]
```

| Option | Description |
|---|---|
| `--dry-run` | Show what would be removed without removing anything |
| `-y`, `--yes` | Skip the confirmation prompt |
| `-h`, `--help` | Show usage |

Running with no arguments prints a before/after report and prompts for confirmation before pruning (equivalent to just running the command with no flags).

## Examples

See [example.md](example.md).

## Output

- Prints `docker system df` before and after the prune so you can see reclaimed space.
- In `--dry-run` mode, prints the command that *would* run, prefixed `DRY-RUN:`, and makes no changes.
- Exits non-zero if Docker isn't installed, the daemon isn't reachable, or the confirmation is declined.

## Troubleshooting

| Symptom | Cause | Fix |
|---|---|---|
| `docker CLI not found on PATH` | Docker not installed / not on PATH | Install Docker, or fix `PATH` |
| `Docker daemon is not reachable` | Daemon not running, or user lacks permission | Start Docker; add user to the `docker` group or run with sufficient privileges |
| Script exits 1 with "Aborted" | Confirmation declined | Re-run with `-y` if you're sure, after reviewing `--dry-run` output |
| Unexpected data loss | `--volumes` removes ALL unused volumes, not just dangling ones | Always review `--dry-run` output first, and use `docker-clean.sh --volumes --dry-run` for a narrower preview |

## References

- [`docker system prune`](https://docs.docker.com/engine/reference/commandline/system_prune/)
- [`docker system df`](https://docs.docker.com/engine/reference/commandline/system_df/)
