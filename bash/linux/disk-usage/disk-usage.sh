#!/usr/bin/env bash
#
# disk-usage.sh — report disk usage per mounted filesystem (df), and alert
# (non-zero exit) if any mount exceeds a usage threshold. Optionally show the
# largest directories under a given path.
#
# Usage: ./disk-usage.sh [options]
# Run with --help for full usage.

set -euo pipefail

SCRIPT_NAME="$(basename "$0")"

THRESHOLD=90
TOP_N=0
TOP_PATH="/"

usage() {
  cat <<EOF
Usage: ${SCRIPT_NAME} [options]

Report disk usage per mounted filesystem via df, and exit non-zero if any
mount's usage exceeds --threshold. Optionally list the largest directories
under --path with --top.

Options:
  --threshold PCT   Alert threshold as a percentage (default: ${THRESHOLD})
  --top N           Show the N largest directories under --path
  --path PATH       Path to scan for --top (default: ${TOP_PATH})
  -h, --help        Show this help message and exit

Examples:
  ${SCRIPT_NAME}
  ${SCRIPT_NAME} --threshold 80
  ${SCRIPT_NAME} --top 10 --path /var/log

Notes:
  --top uses 'du' under --path and can be slow on large directory trees.
EOF
}

log()  { printf '[disk-usage] %s\n' "$*"; }
err()  { printf '[disk-usage] ERROR: %s\n' "$*" >&2; }

require_cmd() {
  if ! command -v "$1" >/dev/null 2>&1; then
    err "required command not found: $1"
    exit 1
  fi
}

while [ "$#" -gt 0 ]; do
  case "$1" in
    --threshold)
      [ "$#" -ge 2 ] || { err "--threshold requires a value"; exit 1; }
      THRESHOLD="$2"
      shift
      ;;
    --top)
      [ "$#" -ge 2 ] || { err "--top requires a value"; exit 1; }
      TOP_N="$2"
      shift
      ;;
    --path)
      [ "$#" -ge 2 ] || { err "--path requires a value"; exit 1; }
      TOP_PATH="$2"
      shift
      ;;
    -h|--help) usage; exit 0 ;;
    *)
      err "Unknown option: $1"
      usage
      exit 1
      ;;
  esac
  shift
done

case "$THRESHOLD" in
  ''|*[!0-9]*) err "--threshold must be a non-negative integer, got: $THRESHOLD"; exit 1 ;;
esac
case "$TOP_N" in
  ''|*[!0-9]*) err "--top must be a non-negative integer, got: $TOP_N"; exit 1 ;;
esac

require_cmd df

log "Disk usage per mounted filesystem (threshold: ${THRESHOLD}%):"
df -hP

ALERTED=false
# Parse percentage and mount point from the end of each line (not fixed
# field positions), since the filesystem/source column can contain spaces.
while read -r pcent mount; do
  pct="${pcent%\%}"
  case "$pct" in
    ''|*[!0-9]*) continue ;;
  esac
  if [ "$pct" -ge "$THRESHOLD" ]; then
    err "Mount ${mount} at ${pcent} usage (>= ${THRESHOLD}% threshold)"
    ALERTED=true
  fi
done <<EOF
$(df -P | tail -n +2 | awk '{print $(NF-1), $NF}')
EOF

if [ "$TOP_N" -gt 0 ]; then
  require_cmd du
  if [ ! -d "$TOP_PATH" ]; then
    err "--path is not a directory: $TOP_PATH"
    exit 1
  fi
  log "Top ${TOP_N} largest directories under ${TOP_PATH}:"
  du -h --max-depth=1 "$TOP_PATH" 2>/dev/null | sort -rh | head -n "$TOP_N"
fi

if [ "$ALERTED" = true ]; then
  err "One or more mounts exceeded the ${THRESHOLD}% threshold."
  exit 1
fi

log "All mounts are below the ${THRESHOLD}% threshold."
