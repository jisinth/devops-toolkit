# yaml-validate

Validate YAML syntax for one or more files, or a single document from stdin.

## Purpose

Catch YAML syntax errors (bad indentation, unclosed flow collections, tab characters, etc.) in config files, CI manifests, or Kubernetes/Helm YAML before something downstream chokes on them.

## Requirements

- `yq` (preferred), or `python3` with `PyYAML` as a fallback
- Bash 4+

## Usage

```bash
./yaml-validate.sh [file ...]
```

| Option | Description |
|---|---|
| `file ...` | One or more YAML files to validate |
| `-h`, `--help` | Show usage |

If no files are given, a single document is read and validated from stdin.

## Examples

See [example.md](example.md).

## Output

- Prints `PASS - <file>` or `FAIL - <file>` (or `PASS - stdin` / `FAIL - stdin`) for each input.
- On failure, prints the underlying parser error indented beneath the `FAIL` line, on stderr.
- Exits `0` only if every input validated successfully; exits non-zero if any file failed or was missing.

## Troubleshooting

| Symptom | Cause | Fix |
|---|---|---|
| `Neither yq nor python3 is available on PATH` | Neither tool installed | Install `yq` or `python3` (with `PyYAML`) |
| `FAIL - <file> (file not found)` | Path doesn't exist | Check the path/spelling |
| `FAIL - <file>` with a parser error | Malformed YAML | Fix the reported line/column |

## References

- [yq](https://github.com/mikefarah/yq)
- [PyYAML](https://pyyaml.org/wiki/PyYAMLDocumentation)
