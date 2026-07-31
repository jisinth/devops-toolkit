# random-password

Generate one or more random passwords using `/dev/urandom`.

## Purpose

Generate reasonably strong random passwords for temporary credentials, test accounts, or seed data — using an actual entropy source (`/dev/urandom`) rather than the weak, predictable `$RANDOM` shell builtin.

## Requirements

- Bash 4+
- `/dev/urandom` (standard on Linux/macOS/WSL/Git Bash)

## Usage

```bash
./random-password.sh [options]
```

| Option | Description |
|---|---|
| `--count <N>` | Number of passwords to generate (default: 1) |
| `--length <N>` | Length of each password (default: 16) |
| `--charset <type>` | `alnum` or `alnum-symbols` (default: `alnum-symbols`) |
| `--no-ambiguous` | Exclude visually-ambiguous characters (`0 O o 1 l I \|`) |
| `-h`, `--help` | Show usage |

## Examples

See [example.md](example.md).

## Output

- One password per line on stdout.
- Exits non-zero if `--count`/`--length` are not positive integers, or `--charset` is not `alnum`/`alnum-symbols`.

## Troubleshooting

| Symptom | Cause | Fix |
|---|---|---|
| `--count must be a positive integer` | `--count` given a non-numeric or non-positive value | Pass a positive integer |
| `--length must be a positive integer` | `--length` given a non-numeric or non-positive value | Pass a positive integer |
| `Invalid --charset` | Value other than `alnum`/`alnum-symbols` | Use one of the two supported charsets |
| `/dev/urandom is not available` | Running on a system without `/dev/urandom` | Run in an environment that provides it (Linux/macOS/WSL/Git Bash) |
| Generation feels slow for very large `--length`/`--count` | Rejection sampling discards out-of-range bytes | Expected; still fast for typical password lengths |

## References

- [`/dev/urandom` — Linux random(4)](https://man7.org/linux/man-pages/man4/random.4.html)
- [OWASP — Password strength](https://cheatsheetseries.owasp.org/cheatsheets/Authentication_Cheat_Sheet.html)
