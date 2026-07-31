# docker-logs

Export logs for one or all containers to gzip-compressed files.

## Purpose

Capture a snapshot of container logs to disk for later inspection or attaching to a bug report, without leaving a terminal tailing logs.

## Requirements

- Docker CLI on `PATH`
- Docker daemon running and reachable
- `gzip`

## Usage

```bash
./docker-logs.sh [options]
```

| Option | Description |
|---|---|
| `--container NAME` | Export logs for a single container (default: all running containers) |
| `--since TIME` | Only return logs since this time (passed to `docker logs --since`) |
| `--tail N` | Only return the last N lines |
| `--output-dir PATH` | Directory to write log files to (default: `./docker-logs`) |
| `-h`, `--help` | Show usage |

## Examples

See [example.md](example.md).

## Output

One `<container>-<timestamp>.log.gz` file per container under `--output-dir`.

## Troubleshooting

| Symptom | Cause | Fix |
|---|---|---|
| `No such container` | Typo in `--container`, or it's stopped | Check `docker ps -a` |
| Empty log file | Container has produced no logs, or logs were rotated away | Check `docker logs <name>` directly |

## References

- [`docker logs`](https://docs.docker.com/engine/reference/commandline/logs/)
