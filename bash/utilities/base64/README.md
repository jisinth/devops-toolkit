# base64

Encode or decode base64 from a file, stdin, or an inline string.

## Purpose

A one-stop wrapper around the `base64` CLI that accepts input three ways (file, stdin, inline argument) instead of remembering `-i`/`-d`/`-w0` combinations, and fails loudly on bad input rather than silently.

## Requirements

- `base64` CLI (GNU coreutils / BSD) on `PATH`
- Bash 4+

## Usage

```bash
./base64.sh (--encode|--decode) [-i|--in-file <file>] [string]
```

| Option | Description |
|---|---|
| `--encode` | Base64-encode the input |
| `--decode` | Base64-decode the input |
| `-i`, `--in-file <file>` | Read input from `<file>` |
| `-h`, `--help` | Show usage |

Exactly one of `--encode`/`--decode` is required. Input source precedence: `-i/--in-file` or the positional string argument (mutually exclusive with each other) — if neither is given, input is read from stdin.

## Examples

See [example.md](example.md).

## Output

- Encoded/decoded data on stdout, one trailing newline.
- Exits non-zero with an error on missing files, invalid combinations of options, or a failed `base64` invocation (e.g. malformed base64 input to `--decode`).

## Troubleshooting

| Symptom | Cause | Fix |
|---|---|---|
| `One of --encode or --decode is required` | Neither flag passed | Pass `--encode` or `--decode` |
| `--encode and --decode are mutually exclusive` | Both flags passed | Pass only one |
| `-i/--in-file and an inline string argument are mutually exclusive` | Both an input file and a positional string given | Pick one input source |
| `File not found: <path>` | `-i/--in-file` points to a missing path | Check the path |
| `base64 decode failed` | Input isn't valid base64 | Verify the encoded string/file |

## References

- [`base64(1)` — GNU coreutils](https://www.gnu.org/software/coreutils/manual/html_node/base64-invocation.html)
