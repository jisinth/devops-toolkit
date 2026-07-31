# traceroute

Trace the network path to a host and print a formatted hop-by-hop report.

## Purpose

A thin, consistent wrapper around whichever path-tracing tool is available, for diagnosing routing/latency issues.

## Requirements

- `traceroute` (preferred) or `tracepath` (fallback), auto-detected

## Usage

```bash
./traceroute.sh [options] host
```

| Option | Description |
|---|---|
| `--max-hops N` | Maximum number of hops (default: 30) |
| `-h`, `--help` | Show usage |

## Examples

See [example.md](example.md).

## Output

The underlying `traceroute`/`tracepath` hop-by-hop output, prefixed with which tool was used.

## Troubleshooting

| Symptom | Cause | Fix |
|---|---|---|
| `Neither 'traceroute' nor 'tracepath' found` | Neither installed | Install `traceroute` (or `iputils-tracepath`) |
| Trace stalls / times out at a hop | Intermediate router dropping ICMP/UDP probes (common, often not an outage) | Not necessarily a problem — check if the destination itself is reachable |

## References

- [`traceroute(8)`](https://man7.org/linux/man-pages/man8/traceroute.8.html)
