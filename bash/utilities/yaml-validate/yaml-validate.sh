#!/usr/bin/env bash
#
# yaml-validate.sh — validate YAML syntax for one or more files, or a single
# document from stdin when no files are given.
# Uses yq if available, otherwise falls back to python3 + PyYAML.
#
# Usage: ./yaml-validate.sh [file ...]
# Run with --help for full usage.

set -euo pipefail

SCRIPT_NAME="$(basename "$0")"

usage() {
  cat <<EOF
Usage: ${SCRIPT_NAME} [file ...]

Validate YAML syntax. Pass one or more files as positional arguments, or
pipe a single document on stdin when no files are given.

Options:
  -h, --help        Show this help message and exit

Examples:
  ${SCRIPT_NAME} config.yaml
  ${SCRIPT_NAME} a.yaml b.yaml c.yaml
  cat config.yaml | ${SCRIPT_NAME}

Notes:
  Uses 'yq' when it's on PATH, otherwise falls back to python3 + PyYAML.
  Prints a pass/fail line per file (or 'stdin') and exits non-zero if any
  input failed to parse.
EOF
}

log()  { printf '[yaml-validate] %s\n' "$*"; }
err()  { printf '[yaml-validate] ERROR: %s\n' "$*" >&2; }

FILES=()

while [ "$#" -gt 0 ]; do
  case "$1" in
    -h|--help) usage; exit 0 ;;
    --)
      shift
      while [ "$#" -gt 0 ]; do FILES+=("$1"); shift; done
      ;;
    -*)
      err "Unknown option: $1"
      usage
      exit 1
      ;;
    *)
      FILES+=("$1")
      shift
      ;;
  esac
done

have_yq=false
have_python=false
command -v yq >/dev/null 2>&1 && have_yq=true
command -v python3 >/dev/null 2>&1 && have_python=true

if [ "$have_yq" = false ] && [ "$have_python" = false ]; then
  err "Neither yq nor python3 is available on PATH."
  exit 1
fi

validate_file() {
  local path="$1"
  if [ "$have_yq" = true ]; then
    yq eval . "$path" >/dev/null 2>/tmp/yaml-validate-err.$$
  else
    python3 -c 'import sys, yaml
try:
    with open(sys.argv[1], encoding="utf-8") as f:
        for _ in yaml.safe_load_all(f):
            pass
except yaml.YAMLError as e:
    print(e, file=sys.stderr)
    sys.exit(1)' "$path" 2>/tmp/yaml-validate-err.$$
  fi
}

validate_stdin() {
  if [ "$have_yq" = true ]; then
    yq eval . - >/dev/null 2>/tmp/yaml-validate-err.$$
  else
    python3 -c 'import sys, yaml
try:
    yaml.safe_load(sys.stdin)
except yaml.YAMLError as e:
    print(e, file=sys.stderr)
    sys.exit(1)' 2>/tmp/yaml-validate-err.$$
  fi
}

fail_count=0

if [ "${#FILES[@]}" -eq 0 ]; then
  if validate_stdin; then
    log "PASS - stdin"
  else
    log "FAIL - stdin"
    sed 's/^/  /' /tmp/yaml-validate-err.$$ >&2 2>/dev/null || true
    fail_count=$((fail_count + 1))
  fi
  rm -f /tmp/yaml-validate-err.$$
else
  for f in "${FILES[@]}"; do
    if [ ! -f "$f" ]; then
      log "FAIL - $f (file not found)"
      fail_count=$((fail_count + 1))
      continue
    fi
    if validate_file "$f"; then
      log "PASS - $f"
    else
      log "FAIL - $f"
      sed 's/^/  /' /tmp/yaml-validate-err.$$ >&2 2>/dev/null || true
      fail_count=$((fail_count + 1))
    fi
  done
  rm -f /tmp/yaml-validate-err.$$
fi

if [ "$fail_count" -gt 0 ]; then
  err "${fail_count} file(s) failed validation."
  exit 1
fi

log "All inputs are valid YAML."
