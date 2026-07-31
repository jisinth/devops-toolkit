# ssl-check

Check TLS certificate expiry for one or more domains and alert (non-zero exit) if any certificate is expiring soon. Built for cron/monitoring wrappers.

## Purpose

Catch an expiring TLS certificate before it takes down a site or API.

## Requirements

- `openssl`
- `curl` (only if using `--webhook`)

## Usage

```bash
./ssl-check.sh [options] domain[:port] [domain[:port] ...]
```

| Option | Description |
|---|---|
| `--days N` | Alert if expiry is within N days (default: 14) |
| `--log-file PATH` | Append timestamped results to this file |
| `--webhook URL` | POST a JSON alert when any cert breaches the threshold |
| `-h`, `--help` | Show usage |

Ports default to 443 (`example.com:8443` to override).

## Examples

See [example.md](example.md).

## Output

Logs subject, issuer, and days-until-expiry per domain. Exits `1` (and POSTs to `--webhook` if set) if any certificate expires within `--days`, or couldn't be retrieved/parsed; exits `0` otherwise.

## Troubleshooting

| Symptom | Cause | Fix |
|---|---|---|
| "could not retrieve certificate" | Connection failed, wrong port, or no cert presented | Verify the host/port with `openssl s_client -connect host:port` manually |
| "could not parse expiry date" | Unusual date format from a non-standard OpenSSL build | Check `date -d` (GNU) / `date -j -f` (BSD) support on this host |

## References

- [`openssl-s_client(1)`](https://docs.openssl.org/master/man1/openssl-s_client/)
