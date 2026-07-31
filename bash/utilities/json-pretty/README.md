# json-pretty

Pretty-print and validate JSON from a file or stdin.

## Purpose

Quickly reformat and sanity-check JSON — from an API response, a config file, or a clipboard paste — without opening an editor or writing a one-off `python -c`.

## Requirements

- `jq` (preferred), or `python3` as a fallback
- Bash 4+

## Usage

```bash
./json-pretty.sh [options]
```

| Option | Description |
|---|---|
| `--file <path>` | Read JSON from `<path>` instead of stdin |
| `-h`, `--help` | Show usage |

If `--file` is omitted, JSON is read from stdin.

## Examples

See [example.md](example.md).

## Output

- Pretty-printed JSON (2-space indent via `python3 -m json.tool`, or `jq`'s default indent) on stdout.
- On invalid JSON, prints the parser's error message and a `[json-pretty] ERROR: Invalid JSON.` line to stderr, and exits non-zero.

## Troubleshooting

| Symptom | Cause | Fix |
|---|---|---|
| `Neither jq nor python3 is available on PATH` | Neither tool installed | Install `jq` or `python3` |
| `File not found: <path>` | `--file` points to a missing path | Check the path |
| `No JSON input provided` | Empty stdin/file and no `--file` given | Pipe JSON in or pass `--file` |
| `Invalid JSON` | Malformed input | Check the reported line/column in the parser error above it |

## References

- [jq manual](https://jqlang.github.io/jq/manual/)
- [Python `json.tool`](https://docs.python.org/3/library/json.html#module-json.tool)
