# website-health

Curl one or more URLs, check HTTP status code and response time, and alert (non-zero exit) on failure. Built for cron/monitoring wrappers.

## Purpose

A simple uptime/latency check for cron or a monitoring system — no external service required.

## Requirements

- `curl`

## Usage

```bash
./website-health.sh [options] [url ...]
```

| Option | Description |
|---|---|
| `--url-file PATH` | Read additional URLs from PATH (one per line, `#` comments allowed) |
| `--timeout SEC` | Max response time in seconds before it counts as a failure (default: 10) |
| `--log-file PATH` | Append timestamped results to this file |
| `--webhook URL` | POST a JSON alert when a check fails |
| `-h`, `--help` | Show usage |

URLs may be given positionally, via `--url-file`, or both.

## Examples

See [example.md](example.md).

## Output

Logs HTTP status and response time per URL. Exits `1` (and POSTs to `--webhook` if set) if any URL returns non-2xx, fails to connect, or exceeds `--timeout`; exits `0` otherwise.

## Troubleshooting

| Symptom | Cause | Fix |
|---|---|---|
| "timed out after Ns" | Site slow or unreachable within `--timeout` | Increase `--timeout` or investigate the target |
| "curl failed (exit code N)" | DNS failure, connection refused, TLS error, etc. | Check curl's exit code meaning (`man curl` exit codes section) |

## References

- [`curl(1)` `-w` format variables](https://curl.se/docs/manpage.html#-w)
