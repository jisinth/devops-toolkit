# secret-scan

Recursively scan a directory for strings that look like hardcoded secrets — AWS access key IDs, private key headers, generic `password`/`secret`/`token`/`api_key` assignments, Slack tokens, GitHub tokens, and bearer tokens — using a curated set of regex patterns.

## Purpose

Catch obvious hardcoded secrets in your own code before they get committed or shipped, with zero setup and no external dependencies beyond bash and grep.

**This is a lightweight heuristic scanner, not a replacement for [gitleaks](https://github.com/gitleaks/gitleaks), [trufflehog](https://github.com/trufflesecurity/trufflehog), or similar dedicated secret-detection tools.** It has no entropy analysis, no verified-credential checking, no git history scanning, and its regex patterns will both miss real secrets (false negatives) and flag non-secrets (false positives). Use it as a quick local sanity check on code you own, and use a proper secret-scanning tool for anything that matters (CI gates, pre-commit hooks, compliance).

## Requirements

- Bash 4+
- GNU grep with extended regex support (`-E`)
- `find`

## Usage

```bash
./secret-scan.sh [options]
```

| Option | Description |
|---|---|
| `--path <dir>` | Directory to scan (default: `.`) |
| `--exclude <pattern>` | Path substring to skip; repeatable (default excludes: `.git`) |
| `-h`, `--help` | Show usage |

## Examples

See [example.md](example.md).

## Output

One line per match, to stdout:

```
file:line: <pattern-name>: <matched line, truncated to 120 chars>
```

A summary line reports how many files were scanned and how many potential secrets were found. The script exits `0` whether or not matches are found — a nonzero exit is reserved for usage errors (bad path, unknown option) so it's safe to run in scripts that just want the report. Grep the output for `: ` prefixes or parse the `pattern-name` field if you want to fail a pipeline on matches.

## Troubleshooting

| Symptom | Cause | Fix |
|---|---|---|
| `Path not found or not a directory` | `--path` points at a missing path or a file | Check the path; pass a directory |
| Binary files skipped silently | Script only scans files grep detects as text | Expected behavior — binary secrets aren't the target use case |
| Too many false positives | Generic patterns (password/secret/token/api_key) match broadly | Use `--exclude` to skip test fixtures/vendored code, or review matches manually — this tool intentionally favors recall over precision |
| Nothing found but you know a secret is there | Secret doesn't match any curated pattern (e.g. unusual variable name, no quotes, base64 blob) | Use a dedicated tool like gitleaks/trufflehog for thorough coverage |

## References

- [gitleaks](https://github.com/gitleaks/gitleaks)
- [trufflehog](https://github.com/trufflesecurity/trufflehog)
- [OWASP: Secrets Management Cheat Sheet](https://cheatsheetseries.owasp.org/cheatsheets/Secrets_Management_Cheat_Sheet.html)
