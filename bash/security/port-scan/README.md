# port-scan

Scan a single host across a TCP port range using bash's built-in `/dev/tcp`, with a short per-port connect timeout, and report which ports are open.

## Authorized use only

**Only scan hosts you own or are explicitly authorized to test.** Port scanning systems you don't own or lack authorization for can violate computer-misuse laws, your ISP's or cloud provider's acceptable-use policy, and the target's terms of service. This tool is intended for auditing your own infrastructure or systems you have explicit written authorization to assess. The script prints this reminder every time it runs.

## Purpose

Quick, dependency-free TCP port sweep for your own hosts — no `nmap` required, just bash.

## Requirements

- Bash 4+ built with `/dev/tcp` support (standard on Linux/macOS/Git Bash; not available if bash was built with `--disable-net-redirections`)
- `timeout` (GNU coreutils) recommended so `--timeout` is actually enforced; without it the script falls back to the OS's default TCP connect timeout, which can make large ranges slow

## Usage

```bash
./port-scan.sh --host <host> [options]
```

| Option | Description |
|---|---|
| `--host <host>` | Target host (hostname or IP) — required |
| `--range <start-end>` | Port range to scan (default: `1-1024`, well-known ports) |
| `--timeout <seconds>` | Per-port connect timeout in seconds (default: `1`) |
| `-h`, `--help` | Show usage |

## Examples

See [example.md](example.md).

## Output

One line per open port (`Port <n>: OPEN`), followed by a summary line with the count scanned and open. Closed/filtered ports are not printed individually to keep output readable on large ranges. Exits `0` on a completed scan (finding zero open ports is not an error); exits non-zero only on usage errors (missing `--host`, bad range).

## Troubleshooting

| Symptom | Cause | Fix |
|---|---|---|
| `--host is required` | `--host` not passed | Supply `--host <host>` |
| `Invalid port range` | `--range` malformed or outside 1-65535 | Use `<start>-<end>`, e.g. `1-1024` |
| Scan is very slow | No `timeout` command available, or scanning a large range against a host that silently drops packets (filtered, not closed) | Install GNU coreutils' `timeout`, narrow `--range`, or increase `--timeout` tolerance expectations |
| Everything reports closed on a host you know has open ports | Firewall between you and the host, or `/dev/tcp` blocked by a restrictive bash build | Confirm connectivity another way (e.g. `nc -zv`), check firewall rules |

## References

- [Bash manual: `/dev/tcp`](https://www.gnu.org/software/bash/manual/bash.html#Redirections)
- [nmap](https://nmap.org/) — for thorough, authorized network scanning
