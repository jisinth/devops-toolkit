# Contributing

Thanks for considering a contribution to devops-toolkit. Every script follows the same lifecycle, whether it's a one-line utility or a multi-file report generator.

## Workflow

```
Identify Problem
      ↓
Choose Script Category
      ↓
Write Script
      ↓
Test Script
      ↓
Document Usage
      ↓
Add Example
      ↓
Automated Testing
      ↓
Merge
      ↓
Release
```

## Folder Layout

Scripts with non-trivial usage should live in their own folder alongside their docs and tests:

```
docker-clean/
├── README.md
├── docker-clean.sh
├── example.md
├── test.sh
└── CHANGELOG.md
```

Simple, self-contained scripts can live directly in their category folder (e.g. `bash/utilities/uuid.sh`).

## Script Requirements

- **Bash**: must pass `shellcheck` with no errors. Use `set -euo pipefail`. Include a usage/help function (`-h`/`--help`).
- **Python**: must pass linting (ruff/flake8) and type checks where practical. Use `argparse` for CLI scripts.
- Every script must:
  - Print a clear error and exit non-zero on failure.
  - Not require interactive input unless explicitly documented.
  - Avoid hardcoded secrets, credentials, or environment-specific paths.

## Documentation Requirements

Each script (or script folder) needs a README covering:

```
Purpose → Requirements → Usage → Examples → Parameters → Output → Troubleshooting → References
```

## Testing

- Bash scripts: add a `test.sh` (or use `bats`) that exercises the script's core paths.
- Python scripts: add `pytest` tests under `tests/`.
- CI (GitHub Actions) runs ShellCheck, Python lint, unit tests, and a security scan on every push — see `.github/workflows/`.

## Commit / PR Guidelines

- One script (or one logical change) per PR where possible.
- Update `CHANGELOG.md` for user-facing changes.
- Reference the category workflow diagram in this doc's parent `README.md` when describing what your script does.
