# firewall-report

Detect the active firewall subsystem and print its current rules in a normalized summary. Read-only.

## Purpose

One command to see "what firewall is this host using, and what does it currently allow" — instead of remembering separate syntax for `ufw`, `firewalld`, `nftables`, and `iptables`.

## Requirements

- One of `ufw`, `firewall-cmd` (firewalld), `nft` (nftables), or `iptables` — checked in that order, first one with an active/queryable state wins
- Typically requires root to read rules

## Usage

```bash
./firewall-report.sh
```

| Option | Description |
|---|---|
| `-h`, `--help` | Show usage |

## Examples

See [example.md](example.md).

## Output

The detected subsystem's name, followed by its rules in that tool's native listing format.

## Troubleshooting

| Symptom | Cause | Fix |
|---|---|---|
| `No supported firewall subsystem found` | None of ufw/firewalld/nftables/iptables present or active | Expected on hosts without a local firewall (e.g. behind a cloud security group only) |
| Empty rule output | Not run as root | Re-run with `sudo` |

## References

- [`iptables(8)`](https://man7.org/linux/man-pages/man8/iptables.8.html)
- [`nft(8)`](https://www.man7.org/linux/man-pages/man8/nft.8.html)
