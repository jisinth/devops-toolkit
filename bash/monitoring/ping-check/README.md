# ping-check

Ping one or more hosts, report packet loss % and average latency, and alert (non-zero exit) if either exceeds a threshold. Built for cron/monitoring wrappers.

## Purpose

Detect host reachability/latency problems from cron without hand-parsing `ping` output every time.

## Requirements

- `ping` (GNU/BSD `ping`, or Windows `ping.exe` under Git Bash/MSYS2 — auto-detected via `uname`)
- `awk`
- `curl` (only if using `--webhook`)

## Usage

```bash
./ping-check.sh [options] host [host ...]
```

| Option | Description |
|---|---|
| `--count N` | Number of ping packets per host (default: 5) |
| `--max-loss PCT` | Alert if packet loss exceeds this percentage (default: 20) |
| `--max-latency-ms MS` | Alert if average latency exceeds this many ms (default: unset) |
| `--log-file PATH` | Append timestamped results to this file |
| `--webhook URL` | POST a JSON alert when a host breaches a threshold |
| `-h`, `--help` | Show usage |

## Examples

See [example.md](example.md).

## Output

Logs loss % and average latency per host. Exits `1` (and POSTs to `--webhook` if set) if any host breaches `--max-loss` or `--max-latency-ms`, or is unreachable/unparsable; exits `0` otherwise.

## Troubleshooting

| Symptom | Cause | Fix |
|---|---|---|
| "could not determine packet loss" | Host unresolvable, or unexpected `ping` output format | Verify the host resolves and `ping` works manually |
| Behaves differently across OSes | `ping` output format differs (Windows vs Linux/macOS) | The script auto-detects via `uname`; file an issue if a variant isn't handled |

## References

- [`ping(8)`](https://man7.org/linux/man-pages/man8/ping.8.html)
