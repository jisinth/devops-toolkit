# dns-check

Resolve a hostname across multiple DNS record types and report the result and query time for each.

## Purpose

A one-command way to check A/AAAA/MX/TXT/NS (or any other type) records for a host, optionally against a specific resolver — useful when debugging DNS propagation or misconfiguration.

## Requirements

- One of `dig`, `host`, or `nslookup` (auto-detected, in that preference order)

## Usage

```bash
./dns-check.sh --host <hostname> [options]
```

| Option | Description |
|---|---|
| `--host <hostname>` | Hostname to resolve (required) |
| `--types <list>` | Comma-separated record types (default: `A,AAAA,MX,TXT,NS`) |
| `--resolver <ip>` | Query this DNS server instead of the system default |
| `-h`, `--help` | Show usage |

## Examples

See [example.md](example.md).

## Output

For each record type: the raw answer (or "No records found") and the query time in ms.

## Troubleshooting

| Symptom | Cause | Fix |
|---|---|---|
| `No DNS lookup tool found` | None of `dig`/`host`/`nslookup` installed | Install `dnsutils`/`bind-utils` (for `dig`) |
| "No records found" for a type that should exist | Resolver doesn't have the record, or it's a caching/propagation delay | Try `--resolver 8.8.8.8` to bypass local caching |

## References

- [`dig(1)`](https://man7.org/linux/man-pages/man1/dig.1.html)
