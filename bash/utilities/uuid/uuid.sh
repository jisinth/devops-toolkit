#!/usr/bin/env bash
#
# uuid.sh — generate one or more UUIDv4 values.
# Uses uuidgen if available, otherwise a pure-bash /dev/urandom fallback.
#
# Usage: ./uuid.sh [--count N] [--upper] [--no-dashes]
# Run with --help for full usage.

set -euo pipefail

SCRIPT_NAME="$(basename "$0")"

COUNT=1
UPPER=false
NO_DASHES=false

usage() {
  cat <<EOF
Usage: ${SCRIPT_NAME} [options]

Generate one or more random UUIDv4 values.

Options:
  --count <N>       Number of UUIDs to generate (default: 1)
  --upper           Print uppercase UUIDs
  --no-dashes       Strip dashes from the output
  -h, --help        Show this help message and exit

Examples:
  ${SCRIPT_NAME}
  ${SCRIPT_NAME} --count 5
  ${SCRIPT_NAME} --upper --no-dashes

Notes:
  Uses 'uuidgen' when it's on PATH, otherwise falls back to a pure-bash
  /dev/urandom generator that sets the correct version (4) and variant
  (8/9/a/b) bits.
EOF
}

log()  { printf '[uuid] %s\n' "$*"; }
err()  { printf '[uuid] ERROR: %s\n' "$*" >&2; }

while [ "$#" -gt 0 ]; do
  case "$1" in
    --count)
      [ "$#" -ge 2 ] || { err "--count requires a value"; exit 1; }
      COUNT="$2"
      shift 2
      ;;
    --upper) UPPER=true; shift ;;
    --no-dashes) NO_DASHES=true; shift ;;
    -h|--help) usage; exit 0 ;;
    *)
      err "Unknown option: $1"
      usage
      exit 1
      ;;
  esac
done

if ! [[ "$COUNT" =~ ^[0-9]+$ ]] || [ "$COUNT" -lt 1 ]; then
  err "--count must be a positive integer."
  exit 1
fi

generate_uuid_fallback() {
  # Read 16 random bytes, set version 4 and variant bits, format as UUID.
  local hex
  hex="$(od -An -N16 -tx1 /dev/urandom | tr -d ' \n')"
  local b6="${hex:12:2}"
  local b8="${hex:16:2}"
  b6="$(printf '%02x' "$(( (16#$b6 & 0x0f) | 0x40 ))")"
  b8="$(printf '%02x' "$(( (16#$b8 & 0x3f) | 0x80 ))")"
  hex="${hex:0:12}${b6}${hex:14:2}${b8}${hex:18:16}"
  printf '%s-%s-%s-%s-%s\n' \
    "${hex:0:8}" "${hex:8:4}" "${hex:12:4}" "${hex:16:4}" "${hex:20:12}"
}

generate_uuid() {
  if command -v uuidgen >/dev/null 2>&1; then
    uuidgen | tr '[:upper:]' '[:lower:]'
  else
    generate_uuid_fallback
  fi
}

for ((i = 0; i < COUNT; i++)); do
  u="$(generate_uuid)"
  if [ "$NO_DASHES" = true ]; then
    u="${u//-/}"
  fi
  if [ "$UPPER" = true ]; then
    u="$(printf '%s' "$u" | tr '[:lower:]' '[:upper:]')"
  fi
  printf '%s\n' "$u"
done
