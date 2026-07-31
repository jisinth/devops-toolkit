#!/usr/bin/env bash
#
# permission-check.sh — scan a path for world-writable files/dirs, SUID/SGID
# binaries, and files with no valid owner (orphaned UID/GID). Read-only.
#
# Usage: ./permission-check.sh [options]
# Run with --help for full usage.

set -euo pipefail

SCRIPT_NAME="$(basename "$0")"

SCAN_PATH="/"

usage() {
  cat <<EOF
Usage: ${SCRIPT_NAME} [options]

Scan --path for world-writable files/directories, SUID/SGID binaries, and
files with no valid owner (orphaned UID/GID). Read-only.

Options:
  --path PATH   Path to scan (default: ${SCAN_PATH})
  -h, --help    Show this help message and exit

Examples:
  ${SCRIPT_NAME}
  ${SCRIPT_NAME} --path /var/www

Notes:
  Scanning --path=/ can be slow on a large filesystem; scope --path to
  the area you actually care about when possible.
EOF
}

log()  { printf '[permission-check] %s\n' "$*"; }
err()  { printf '[permission-check] ERROR: %s\n' "$*" >&2; }

while [ "$#" -gt 0 ]; do
  case "$1" in
    --path)
      [ "$#" -ge 2 ] || { err "--path requires a value"; exit 1; }
      SCAN_PATH="$2"
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

if ! command -v find >/dev/null 2>&1; then
  err "required command not found: find"
  exit 1
fi

if [ ! -d "$SCAN_PATH" ]; then
  err "--path is not a directory: $SCAN_PATH"
  exit 1
fi

log "Scanning ${SCAN_PATH} (this may take a while on large filesystems)..."

log "World-writable files/directories:"
count=0
while IFS= read -r -d '' f; do
  echo "  $f"
  count=$((count + 1))
done < <(find "$SCAN_PATH" -xdev -perm -0002 -print0 2>/dev/null)
[ "$count" -eq 0 ] && echo "  (none found)"
log "  ${count} world-writable path(s) found."

log "SUID/SGID binaries:"
count=0
while IFS= read -r -d '' f; do
  echo "  $f"
  count=$((count + 1))
done < <(find "$SCAN_PATH" -xdev \( -perm -4000 -o -perm -2000 \) -type f -print0 2>/dev/null)
[ "$count" -eq 0 ] && echo "  (none found)"
log "  ${count} SUID/SGID binarie(s) found."

log "Files with no valid owner (orphaned UID/GID):"
count=0
while IFS= read -r -d '' f; do
  echo "  $f"
  count=$((count + 1))
done < <(find "$SCAN_PATH" -xdev \( -nouser -o -nogroup \) -print0 2>/dev/null)
[ "$count" -eq 0 ] && echo "  (none found)"
log "  ${count} orphaned-owner path(s) found."
