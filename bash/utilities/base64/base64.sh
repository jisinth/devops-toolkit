#!/usr/bin/env bash
#
# base64.sh — encode or decode base64 from a file, stdin, or an inline string.
#
# Usage: ./base64.sh (--encode|--decode) [-i <file>] [string]
# Run with --help for full usage.

set -euo pipefail

SCRIPT_NAME="$(basename "$0")"

MODE=""
IN_FILE=""
INLINE=""
HAVE_INLINE=false

usage() {
  cat <<EOF
Usage: ${SCRIPT_NAME} (--encode|--decode) [-i|--in-file <file>] [string]

Encode or decode base64 data from a file, stdin, or an inline string
positional argument. Exactly one of --encode/--decode is required.

Options:
  --encode              Base64-encode the input
  --decode              Base64-decode the input
  -i, --in-file <file>  Read input from <file>
  -h, --help            Show this help message and exit

Examples:
  ${SCRIPT_NAME} --encode "hello world"
  ${SCRIPT_NAME} --decode "aGVsbG8gd29ybGQ="
  ${SCRIPT_NAME} --encode -i secret.txt
  echo -n "hello" | ${SCRIPT_NAME} --encode

Notes:
  If neither -i/--in-file nor a positional string is given, input is read
  from stdin. -i/--in-file and the positional string are mutually exclusive.
EOF
}

log()  { printf '[base64] %s\n' "$*"; }
err()  { printf '[base64] ERROR: %s\n' "$*" >&2; }

while [ "$#" -gt 0 ]; do
  case "$1" in
    --encode)
      [ -z "$MODE" ] || { err "--encode and --decode are mutually exclusive"; exit 1; }
      MODE="encode"
      shift
      ;;
    --decode)
      [ -z "$MODE" ] || { err "--encode and --decode are mutually exclusive"; exit 1; }
      MODE="decode"
      shift
      ;;
    -i|--in-file)
      [ "$#" -ge 2 ] || { err "$1 requires a value"; exit 1; }
      IN_FILE="$2"
      shift 2
      ;;
    -h|--help) usage; exit 0 ;;
    -*)
      err "Unknown option: $1"
      usage
      exit 1
      ;;
    *)
      if [ "$HAVE_INLINE" = true ]; then
        err "Unexpected extra argument: $1"
        exit 1
      fi
      INLINE="$1"
      HAVE_INLINE=true
      shift
      ;;
  esac
done

if [ -z "$MODE" ]; then
  err "One of --encode or --decode is required."
  usage
  exit 1
fi

if [ -n "$IN_FILE" ] && [ "$HAVE_INLINE" = true ]; then
  err "-i/--in-file and an inline string argument are mutually exclusive."
  exit 1
fi

if [ -n "$IN_FILE" ] && [ ! -f "$IN_FILE" ]; then
  err "File not found: $IN_FILE"
  exit 1
fi

if ! command -v base64 >/dev/null 2>&1; then
  err "base64 command not found on PATH."
  exit 1
fi

run_base64() {
  local flag=()
  [ "$MODE" = "decode" ] && flag=(-d)
  if [ -n "$IN_FILE" ]; then
    base64 "${flag[@]}" "$IN_FILE"
  elif [ "$HAVE_INLINE" = true ]; then
    printf '%s' "$INLINE" | base64 "${flag[@]}"
  else
    base64 "${flag[@]}"
  fi
}

if ! OUTPUT="$(run_base64 2>&1)"; then
  err "base64 ${MODE} failed."
  printf '%s\n' "$OUTPUT" >&2
  exit 1
fi

printf '%s\n' "$OUTPUT"
