#!/usr/bin/env bash
#
# memory-alert.sh — sample current memory usage % (via /proc/meminfo) and
# alert (non-zero exit) if it exceeds --threshold. Built for cron/monitoring
# wrappers: --log-file appends results, --webhook POSTs a best-effort alert.
#
# Usage: ./memory-alert.sh [options]
# Run with --help for full usage.

set -euo pipefail

SCRIPT_NAME="$(basename "$0")"
SCRIPT_TAG="memory-alert"

THRESHOLD=90
LOG_FILE=""
WEBHOOK=""

usage() {
  cat <<EOF
Usage: ${SCRIPT_NAME} [options]

Sample current memory usage percentage (via /proc/meminfo) and exit non-zero
if usage is at or above --threshold.

Options:
  --threshold PCT   Alert threshold as a percentage (default: ${THRESHOLD})
  --log-file PATH   Append timestamped results to this file
  --webhook URL     POST a JSON alert to this URL when the threshold is breached
  -h, --help        Show this help message and exit

Examples:
  ${SCRIPT_NAME}
  ${SCRIPT_NAME} --threshold 85
  ${SCRIPT_NAME} --log-file /var/log/memory-alert.log --webhook https://hooks.example.com/alert

Notes:
  Requires a Linux-style /proc/meminfo. Uses MemAvailable when present
  (kernel 3.14+); falls back to MemFree otherwise. The webhook POST is
  best-effort: a failed POST is logged as a warning but does not change the
  exit code.
EOF
}

log() {
  printf '[%s] %s\n' "$SCRIPT_TAG" "$*"
  if [ -n "$LOG_FILE" ]; then
    printf '%s [%s] %s\n' "$(date '+%Y-%m-%d %H:%M:%S')" "$SCRIPT_TAG" "$*" >> "$LOG_FILE"
  fi
}

err() {
  printf '[%s] ERROR: %s\n' "$SCRIPT_TAG" "$*" >&2
  if [ -n "$LOG_FILE" ]; then
    printf '%s [%s] ERROR: %s\n' "$(date '+%Y-%m-%d %H:%M:%S')" "$SCRIPT_TAG" "$*" >> "$LOG_FILE"
  fi
}

require_cmd() {
  if ! command -v "$1" >/dev/null 2>&1; then
    err "required command not found: $1"
    exit 1
  fi
}

notify_webhook() {
  local message="$1"
  [ -n "$WEBHOOK" ] || return 0
  if ! command -v curl >/dev/null 2>&1; then
    err "curl not found; skipping webhook notification"
    return 0
  fi
  local payload
  payload=$(printf '{"text":"%s"}' "$(printf '%s' "$message" | sed 's/\\/\\\\/g; s/"/\\"/g')")
  if ! curl -fsS -m 10 -X POST -H 'Content-Type: application/json' -d "$payload" "$WEBHOOK" >/dev/null 2>&1; then
    err "webhook POST failed (best-effort, continuing)"
  fi
}

while [ "$#" -gt 0 ]; do
  case "$1" in
    --threshold)
      [ "$#" -ge 2 ] || { err "--threshold requires a value"; exit 1; }
      THRESHOLD="$2"
      shift
      ;;
    --log-file)
      [ "$#" -ge 2 ] || { err "--log-file requires a value"; exit 1; }
      LOG_FILE="$2"
      shift
      ;;
    --webhook)
      [ "$#" -ge 2 ] || { err "--webhook requires a value"; exit 1; }
      WEBHOOK="$2"
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

case "$THRESHOLD" in ''|*[!0-9]*) err "--threshold must be a non-negative integer, got: $THRESHOLD"; exit 1 ;; esac

require_cmd awk

if [ ! -r /proc/meminfo ]; then
  err "/proc/meminfo not readable; this script requires a Linux-style /proc filesystem."
  exit 1
fi

mem_total_kb=$(awk '/^MemTotal:/ {print $2}' /proc/meminfo)
mem_available_kb=$(awk '/^MemAvailable:/ {print $2}' /proc/meminfo)

if [ -z "$mem_total_kb" ]; then
  err "Could not read MemTotal from /proc/meminfo"
  exit 1
fi

if [ -z "$mem_available_kb" ]; then
  mem_available_kb=$(awk '/^MemFree:/ {print $2}' /proc/meminfo)
  if [ -z "$mem_available_kb" ]; then
    err "Could not read MemAvailable or MemFree from /proc/meminfo"
    exit 1
  fi
  log "MemAvailable not present in /proc/meminfo; falling back to MemFree (less accurate)."
fi

usage_pct=$(awk -v total="$mem_total_kb" -v avail="$mem_available_kb" 'BEGIN { printf "%.1f", (1 - (avail / total)) * 100 }')

log "Memory usage: ${usage_pct}% (threshold: ${THRESHOLD}%)"

if awk -v u="$usage_pct" -v t="$THRESHOLD" 'BEGIN { exit !(u >= t) }'; then
  msg="Memory usage ${usage_pct}% is at or above threshold ${THRESHOLD}%"
  err "$msg"
  notify_webhook "$msg"
  exit 1
fi

log "Memory usage is below the ${THRESHOLD}% threshold."
