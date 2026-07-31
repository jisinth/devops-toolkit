# latency

Ping one or more hosts and report packet loss and min/avg/max/stddev latency for each.

## Purpose

A quick multi-host latency/loss check for interactive troubleshooting or a CSV export across a fleet of hosts.

## Requirements

- `ping` (GNU/BSD `ping`, or Windows `ping.exe` under Git Bash/MSYS2 — auto-detected via `uname`)

## Usage

```bash
./latency.sh [options] host [host ...]
```

| Option | Description |
|---|---|
| `--hosts host1,host2` | Comma-separated hosts (in addition to any positional hosts) |
| `--count N` | Number of ping packets per host (default: 10) |
| `--output FORMAT` | `table` (default) or `csv` |
| `-h`, `--help` | Show usage |

## Examples

See [example.md](example.md).

## Output

Per host: packet loss % and min/avg/max/stddev round-trip latency in ms. On Windows `ping.exe`, stddev is reported as `N/A` (not provided by that tool).

## Troubleshooting

| Symptom | Cause | Fix |
|---|---|---|
| All values `N/A` | Host unreachable, or unexpected `ping` output format | Verify the host resolves and `ping` works manually |
| Different fields on Windows vs Linux | `ping.exe` output format differs from GNU/BSD `ping` | Expected — the script auto-detects and parses accordingly |

## References

- [`ping(8)`](https://man7.org/linux/man-pages/man8/ping.8.html)
