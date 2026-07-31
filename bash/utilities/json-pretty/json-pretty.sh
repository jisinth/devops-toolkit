#!/usr/bin/env bash
#
# json-pretty.sh — pretty-print and validate JSON from a file or stdin.
# Uses jq if available, otherwise falls back to python3 -m json.tool.
#
# Usage: ./json-pretty.sh [--file <path>]
# Run with --help for full usage.

set -euo pipefail

SCRIPT_NAME="$(basename "$0")"

FILE=""

usage() {
  cat <<EOF
Usage: ${SCRIPT_NAME} [options]

Pretty-print and validate JSON, read from --file or stdin.

Options:
  --file <path>     Read JSON from <path> instead of stdin
  -h, --help        Show this help message and exit

Examples:
  ${SCRIPT_NAME} --file data.json
  cat data.json | ${SCRIPT_NAME}
  echo '{"a":1}' | ${SCRIPT_NAME}

Notes:
  Uses 'jq .' when jq is on PATH, otherwise falls back to
  'python3 -m json.tool'. Exits non-zero with an error on invalid JSON.
EOF
}

log()  { printf '[json-pretty] %s\n' "$*"; }
err()  { printf '[json-pretty] ERROR: %s\n' "$*" >&2; }

while [ "$#" -gt 0 ]; do
  case "$1" in
    --file)
      [ "$#" -ge 2 ] || { err "--file requires a value"; exit 1; }
      FILE="$2"
      shift 2
      ;;
    -h|--help) usage; exit 0 ;;
    *)
      err "Unknown option: $1"
      usage
      exit 1
      ;;
  esac
done

if [ -n "$FILE" ]; then
  if [ ! -f "$FILE" ]; then
    err "File not found: $FILE"
    exit 1
  fi
fi

read_input() {
  if [ -n "$FILE" ]; then
    cat "$FILE"
  else
    cat
  fi
}

INPUT="$(read_input)"

if [ -z "${INPUT// /}" ]; then
  err "No JSON input provided."
  exit 1
fi

if command -v jq >/dev/null 2>&1; then
  if ! printf '%s' "$INPUT" | jq . ; then
    err "Invalid JSON."
    exit 1
  fi
elif command -v python3 >/dev/null 2>&1; then
  if ! printf '%s' "$INPUT" | python3 -m json.tool; then
    err "Invalid JSON."
    exit 1
  fi
else
  err "Neither jq nor python3 is available on PATH."
  exit 1
fi
