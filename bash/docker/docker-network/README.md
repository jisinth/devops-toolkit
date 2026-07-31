# docker-network

Read-only report of Docker networks, flagging unused ones.

## Purpose

Spot Docker networks with zero attached containers — candidates for cleanup (via `docker network prune` or `docker-clean.sh --networks`).

## Requirements

- Docker CLI on `PATH`
- Docker daemon running and reachable

## Usage

```bash
./docker-network.sh [options]
```

| Option | Description |
|---|---|
| `--unused-only` | Only show networks with zero attached containers |
| `-h`, `--help` | Show usage |

## Examples

See [example.md](example.md).

## Output

A table: name, driver, scope, attached container count, and an unused flag, followed by a count of unused networks.

## Troubleshooting

| Symptom | Cause | Fix |
|---|---|---|
| `docker CLI not found on PATH` | Docker not installed | Install Docker |
| `Docker daemon is not reachable` | Daemon not running / permission issue | Start Docker; check user is in the `docker` group |

## References

- [`docker network ls`](https://docs.docker.com/engine/reference/commandline/network_ls/)
- [`docker network inspect`](https://docs.docker.com/engine/reference/commandline/network_inspect/)
