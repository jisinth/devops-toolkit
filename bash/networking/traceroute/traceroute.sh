#!/usr/bin/env bash
#
# traceroute.sh — wrapper around traceroute/tracepath (auto-detected)
# producing a clean, formatted hop-by-hop report.
#
# Usage: ./traceroute.sh [options] host
# Run with --help for full usage.

set -euo pipefail

SCRIPT_NAME="$(basename "$0")"

MAX_HOPS=30
HOST=""

usage() {
  cat <<EOF
Usage: ${SCRIPT_NAME} [options] host

Trace the network path to a host and print a formatted hop-by-hop report.
Uses 'traceroute' if available, falling back to 'tracepath'.

Options:
  --max-hops N   Maximum number of hops (default: ${MAX_HOPS})
  -h, --help     Show this help message and exit

Examples:
  ${SCRIPT_NAME} example.com
  ${SCRIPT_NAME} --max-hops 15 8.8.8.8
EOF
}

log()  { printf '[traceroute] %s\n' "$*"; }
err()  { printf '[traceroute] ERROR: %s\n' "$*" >&2; }

while [ "$#" -gt 0 ]; do
  case "$1" in
    --max-hops)
      [ "$#" -ge 2 ] || { err "--max-hops requires a value"; exit 1; }
      MAX_HOPS="$2"
      shift
      ;;
    -h|--help) usage; exit 0 ;;
    -*)
      err "Unknown option: $1"
      usage
      exit 1
      ;;
    *)
      if [ -n "$HOST" ]; then
        err "Only one host may be given, got both '$HOST' and '$1'"
        exit 1
      fi
      HOST="$1"
      ;;
  esac
  shift
done

case "$MAX_HOPS" in ''|*[!0-9]*) err "--max-hops must be a non-negative integer, got: $MAX_HOPS"; exit 1 ;; esac

if [ -z "$HOST" ]; then
  err "No host given."
  usage
  exit 1
fi

if command -v traceroute >/dev/null 2>&1; then
  log "Tracing route to ${HOST} (max ${MAX_HOPS} hops) via 'traceroute'..."
  traceroute -m "$MAX_HOPS" "$HOST"
elif command -v tracepath >/dev/null 2>&1; then
  log "Tracing route to ${HOST} (max ${MAX_HOPS} hops) via 'tracepath'..."
  tracepath -m "$MAX_HOPS" "$HOST"
else
  err "Neither 'traceroute' nor 'tracepath' found."
  exit 1
fi
