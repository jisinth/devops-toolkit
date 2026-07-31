# port-check

Check whether specific TCP ports on a host are open, with connect latency. No `nc`/`ncat` dependency — uses bash's built-in `/dev/tcp`.

## Purpose

A quick, dependency-light check for a handful of known ports (e.g. "is 443 open on this host?"). For a broader port-range sweep, see [bash/security/port-scan](../../security/port-scan/README.md) instead — remember its authorized-use-only guidance applies there too.

## Requirements

- `timeout` (GNU coreutils)
- Bash with `/dev/tcp` support (standard on Linux/macOS bash builds; not MSYS2/Windows bash)

## Usage

```bash
./port-check.sh --host <hostname> --ports <list> [options]
```

| Option | Description |
|---|---|
| `--host <hostname>` | Host to check (required) |
| `--ports <list>` | Comma-separated ports and/or ranges, e.g. `22,80,443` or `20-25` (required) |
| `--timeout <secs>` | Per-port connect timeout in seconds (default: 3) |
| `-h`, `--help` | Show usage |

## Examples

See [example.md](example.md).

## Output

Per port: `open` (with connect time), `closed` (connection actively refused), or `filtered` (no response before the timeout — likely firewalled).

## Troubleshooting

| Symptom | Cause | Fix |
|---|---|---|
| Everything reports `filtered` | Firewall dropping packets, or wrong host/port | Verify connectivity another way (e.g. `curl -v telnet://host:port`) |
| `'timeout' command not found` | Non-GNU environment | Install GNU coreutils, or run on a standard Linux host |

## References

- [Bash `/dev/tcp`](https://www.gnu.org/software/bash/manual/html_node/Redirections.html)
