# Architecture

## Design principles

- **One script, one job.** Scripts do a single, well-defined task rather than growing multi-purpose flags.
- **Category folders, not language folders, drive discovery.** Bash is used for host/container/OS-level tasks; Python is used for API-heavy cloud/reporting tasks where SDKs (boto3, azure-sdk) make the job far simpler.
- **Consistent lifecycle per category** (see each category's workflow diagram in the root project description): collect → analyze/act → report, with an optional fix/cleanup step gated behind explicit flags.
- **Scripts are composable**, not orchestrated — no shared runtime or framework is required to run any single script today. The planned CLI (see [roadmap.md](roadmap.md)) will add an orchestration layer on top without breaking standalone usage.

## Layout

```
bash/<category>/<script>.sh      Bash scripts, POSIX-ish, shellcheck-clean
python/<category>/<script>.py    Python scripts, stdlib + category SDK (boto3, azure-sdk, kubernetes client)
examples/<category>/             Sample invocations and expected output per category
configs/                         Shared/sample config files (thresholds, credentials templates — no real secrets)
tests/                           Automated tests (bats for bash, pytest for python)
```

## CI pipeline

```
Push → ShellCheck → Python Lint → Unit Test → Security Scan → Release
```

Defined in `.github/workflows/bash.yml`, `python.yml`, `security.yml`, and `release.yml`.

## Future: unified CLI

Long-term (v5.0, see [roadmap.md](roadmap.md)), a thin CLI dispatcher will map subcommands (`devops-toolkit docker cleanup`) to the existing scripts, so today's scripts remain the source of truth and the CLI is purely a routing layer.
