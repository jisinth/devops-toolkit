# uuid

Generate one or more UUIDv4 values.

## Purpose

Quickly generate RFC 4122 version-4 UUIDs for test fixtures, resource IDs, or scripting — without depending on a particular language runtime being installed.

## Requirements

- `uuidgen` (preferred), or Bash 4+ with `/dev/urandom` as a fallback (no other dependencies)

## Usage

```bash
./uuid.sh [options]
```

| Option | Description |
|---|---|
| `--count <N>` | Number of UUIDs to generate (default: 1) |
| `--upper` | Print uppercase UUIDs |
| `--no-dashes` | Strip dashes from the output |
| `-h`, `--help` | Show usage |

## Examples

See [example.md](example.md).

## Output

- One UUIDv4 per line on stdout, lowercase with dashes by default.
- Exits non-zero if `--count` is not a positive integer, or on an unknown option.

## Troubleshooting

| Symptom | Cause | Fix |
|---|---|---|
| `--count must be a positive integer` | `--count` given a non-numeric or zero/negative value | Pass a positive integer |
| UUIDs look identical across runs | Should not happen — check `/dev/urandom` is available | Verify `/dev/urandom` exists and is readable |

## References

- [RFC 4122 — A Universally Unique IDentifier (UUID) URN Namespace](https://www.rfc-editor.org/rfc/rfc4122)
- [`uuidgen(1)`](https://man7.org/linux/man-pages/man1/uuidgen.1.html)
