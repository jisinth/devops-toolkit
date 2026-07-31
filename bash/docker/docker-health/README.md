# docker-health

Report the Docker health-check status of every running container, and optionally restart unhealthy ones.

## Purpose

Quickly see which containers are failing their `HEALTHCHECK`, and fix it in one step when appropriate.

## Requirements

- Docker CLI on `PATH`
- Docker daemon running and reachable

## Usage

```bash
./docker-health.sh [options]
```

| Option | Description |
|---|---|
| `--fix` | Restart containers reported as unhealthy |
| `-y`, `--yes` | Skip the confirmation prompt before restarting |
| `--output FORMAT` | `table` (default), `csv`, or `json` |
| `-h`, `--help` | Show usage |

Containers with no `HEALTHCHECK` defined report as `none` and are never restarted.

## Examples

See [example.md](example.md).

## Output

A table/CSV/JSON report of container → health status, followed by a summary line. With `--fix`, restarts unhealthy containers after confirmation (or immediately with `-y`).

## Troubleshooting

| Symptom | Cause | Fix |
|---|---|---|
| `docker CLI not found on PATH` | Docker not installed | Install Docker |
| `Docker daemon is not reachable` | Daemon not running / permission issue | Start Docker; check user is in the `docker` group |
| Container restarted but still unhealthy | The health check itself is failing due to an app bug | Investigate the container's health-check command/logs, not this script |

## References

- [`docker inspect`](https://docs.docker.com/engine/reference/commandline/inspect/)
- [Docker HEALTHCHECK](https://docs.docker.com/engine/reference/builder/#healthcheck)
