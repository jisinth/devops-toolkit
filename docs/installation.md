# Installation

## Requirements

- Bash 4+ (scripts under `bash/`)
- Python 3.9+ (scripts under `python/`)
- `shellcheck` (for contributing/testing Bash scripts)
- Category-specific tooling as needed: `docker`, `kubectl`, `aws` CLI, `az` CLI

## Clone the repo

```bash
git clone https://github.com/jisinth/devops-toolkit.git
cd devops-toolkit
```

## Bash scripts

No installation needed — make the script executable and run it directly:

```bash
chmod +x bash/docker/docker-clean.sh
./bash/docker/docker-clean.sh --help
```

## Python scripts

Each Python category may ship its own `requirements.txt`. Install into a virtual environment:

```bash
python3 -m venv .venv
source .venv/bin/activate
pip install -r python/aws/requirements.txt
```

## Future: unified CLI

A planned `devops-toolkit` CLI (see [roadmap.md](roadmap.md)) will wrap all scripts behind one command, e.g. `devops-toolkit docker cleanup`. Until then, scripts are run individually.
