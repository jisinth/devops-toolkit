#!/usr/bin/env bash
#
# cleanup.sh — clean temp files, old logs, and package manager caches.
# Dry-run by default; reports what would be removed and only actually
# cleans with --yes.
#
# Usage: ./cleanup.sh [options]
# Run with --help for full usage.

set -euo pipefail

SCRIPT_NAME="$(basename "$0")"

DAYS=7
ASSUME_YES=false
DO_TMP=true
DO_LOGS=true
DO_PKG_CACHE=true
TMP_DIR="/tmp"
LOG_DIR="/var/log"

usage() {
  cat <<EOF
Usage: ${SCRIPT_NAME} [options]

Clean temporary files older than --days, old rotated logs, and package
manager caches (apt/yum/dnf, auto-detected). Reports what would be
removed by default (dry-run); pass --yes to actually clean.

Options:
  --days N          Age threshold in days for temp files/logs (default: ${DAYS})
  --tmp-dir PATH    Directory to scan for old temp files (default: ${TMP_DIR})
  --log-dir PATH    Directory to scan for old rotated logs (default: ${LOG_DIR})
  --skip-tmp        Skip cleaning temp files
  --skip-logs       Skip cleaning old logs
  --skip-pkg-cache  Skip cleaning package manager caches
  -y, --yes         Actually perform the cleanup (default: dry-run report only)
  -h, --help        Show this help message and exit

Examples:
  ${SCRIPT_NAME}
  ${SCRIPT_NAME} --days 14 -y
  ${SCRIPT_NAME} --skip-pkg-cache --yes

Notes:
  Without --yes, this only reports what would be removed and how much
  space would be reclaimed; nothing is deleted.
EOF
}

log()  { printf '[cleanup] %s\n' "$*"; }
err()  { printf '[cleanup] ERROR: %s\n' "$*" >&2; }

while [ "$#" -gt 0 ]; do
  case "$1" in
    --days)
      [ "$#" -ge 2 ] || { err "--days requires a value"; exit 1; }
      DAYS="$2"
      shift
      ;;
    --tmp-dir)
      [ "$#" -ge 2 ] || { err "--tmp-dir requires a value"; exit 1; }
      TMP_DIR="$2"
      shift
      ;;
    --log-dir)
      [ "$#" -ge 2 ] || { err "--log-dir requires a value"; exit 1; }
      LOG_DIR="$2"
      shift
      ;;
    --skip-tmp) DO_TMP=false ;;
    --skip-logs) DO_LOGS=false ;;
    --skip-pkg-cache) DO_PKG_CACHE=false ;;
    -y|--yes) ASSUME_YES=true ;;
    -h|--help) usage; exit 0 ;;
    *)
      err "Unknown option: $1"
      usage
      exit 1
      ;;
  esac
  shift
done

case "$DAYS" in ''|*[!0-9]*) err "--days must be a non-negative integer, got: $DAYS"; exit 1 ;; esac

TOTAL_BYTES=0
TOTAL_FILES=0

report_and_maybe_remove() {
  local desc="$1"; shift
  local -a files=("$@")
  if [ "${#files[@]}" -eq 0 ]; then
    return 0
  fi
  local bytes=0
  for f in "${files[@]}"; do
    [ -f "$f" ] || continue
    sz=$(stat -c%s "$f" 2>/dev/null || stat -f%z "$f" 2>/dev/null || echo 0)
    bytes=$((bytes + sz))
  done
  TOTAL_BYTES=$((TOTAL_BYTES + bytes))
  TOTAL_FILES=$((TOTAL_FILES + ${#files[@]}))
  log "${desc}: ${#files[@]} file(s), $((bytes / 1024)) KB"
  if [ "$ASSUME_YES" = true ]; then
    for f in "${files[@]}"; do
      rm -f "$f"
    done
  fi
}

if [ "$DO_TMP" = true ]; then
  if [ -d "$TMP_DIR" ]; then
    mapfile -t tmp_files < <(find "$TMP_DIR" -type f -mtime "+${DAYS}" 2>/dev/null)
    report_and_maybe_remove "${TMP_DIR} files older than ${DAYS}d" "${tmp_files[@]:-}"
  else
    log "${TMP_DIR} not present, skipping."
  fi
fi

if [ "$DO_LOGS" = true ]; then
  if [ -d "$LOG_DIR" ]; then
    mapfile -t log_files < <(find "$LOG_DIR" -type f \( -name '*.log.*' -o -name '*.gz' -o -name '*.old' \) -mtime "+${DAYS}" 2>/dev/null)
    report_and_maybe_remove "Rotated logs under ${LOG_DIR} older than ${DAYS}d" "${log_files[@]:-}"
  else
    log "${LOG_DIR} not present, skipping."
  fi
fi

if [ "$DO_PKG_CACHE" = true ]; then
  if command -v apt-get >/dev/null 2>&1; then
    log "Detected apt. Package cache cleanup: apt-get clean"
    if [ "$ASSUME_YES" = true ]; then
      apt-get clean
    else
      log "(dry-run) would run: apt-get clean"
    fi
  elif command -v dnf >/dev/null 2>&1; then
    log "Detected dnf. Package cache cleanup: dnf clean all"
    if [ "$ASSUME_YES" = true ]; then
      dnf clean all
    else
      log "(dry-run) would run: dnf clean all"
    fi
  elif command -v yum >/dev/null 2>&1; then
    log "Detected yum. Package cache cleanup: yum clean all"
    if [ "$ASSUME_YES" = true ]; then
      yum clean all
    else
      log "(dry-run) would run: yum clean all"
    fi
  else
    log "No supported package manager (apt/dnf/yum) detected, skipping."
  fi
fi

log "Total: ${TOTAL_FILES} file(s), $((TOTAL_BYTES / 1024)) KB $([ "$ASSUME_YES" = true ] && echo "removed" || echo "would be removed (dry-run, use --yes to clean)")"
