#!/usr/bin/env bash
#
# disk-alert.sh — check disk usage (df) for a mount point or all mounts, and
# alert (non-zero exit) if usage exceeds --threshold. Built for cron/
# monitoring wrappers: --log-file appends results, --webhook POSTs a
# best-effort alert.
#
# Usage: ./disk-alert.sh [options]
# Run with --help for full usage.

set -euo pipefail

SCRIPT_NAME="$(basename "$0")"
SCRIPT_TAG="disk-alert"

THRESHOLD=90
MOUNT="/"
ALL_MOUNTS=false
LOG_FILE=""
WEBHOOK=""

usage() {
  cat <<EOF
Usage: ${SCRIPT_NAME} [options]

Check disk usage via 'df' for a single mount (--mount, default ${MOUNT}) or
every mounted filesystem (--all), and exit non-zero if any checked mount's
usage is at or above --threshold.

Options:
  --mount PATH      Mount point to check (default: ${MOUNT})
  --all             Check every mounted filesystem instead of a single mount
  --threshold PCT   Alert threshold as a percentage (default: ${THRESHOLD})
  --log-file PATH   Append timestamped results to this file
  --webhook URL     POST a JSON alert to this URL when the threshold is breached
  -h, --help        Show this help message and exit

Examples:
  ${SCRIPT_NAME}
  ${SCRIPT_NAME} --mount /var --threshold 85
  ${SCRIPT_NAME} --all --log-file /var/log/disk-alert.log --webhook https://hooks.example.com/alert

Notes:
  --mount and --all are mutually exclusive; --all wins if both are given.
  The webhook POST is best-effort: a failed POST is logged as a warning but
  does not change the exit code.
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
    --mount)
      [ "$#" -ge 2 ] || { err "--mount requires a value"; exit 1; }
      MOUNT="$2"
      shift
      ;;
    --all) ALL_MOUNTS=true ;;
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

require_cmd df

ALERTED=false
CHECKED=0

if [ "$ALL_MOUNTS" = true ]; then
  df_output="$(df --output=target,pcent,source)"
else
  if [ ! -e "$MOUNT" ]; then
    err "--mount path does not exist: $MOUNT"
    exit 1
  fi
  df_output="$(df --output=target,pcent,source "$MOUNT")"
fi

while read -r mount pcent fs; do
  pct="${pcent%\%}"
  pct="${pct# }"
  case "$pct" in
    ''|*[!0-9]*) continue ;;
  esac
  CHECKED=$((CHECKED + 1))
  log "${mount} (${fs}) — ${pcent} used"
  if [ "$pct" -ge "$THRESHOLD" ]; then
    msg="Mount ${mount} at ${pcent} usage (>= ${THRESHOLD}% threshold)"
    err "$msg"
    notify_webhook "$msg"
    ALERTED=true
  fi
done <<< "$df_output"

if [ "$CHECKED" -eq 0 ]; then
  err "No mounts matched; nothing was checked."
  exit 1
fi

if [ "$ALERTED" = true ]; then
  err "One or more mounts exceeded the ${THRESHOLD}% threshold."
  exit 1
fi

log "All checked mounts are below the ${THRESHOLD}% threshold."
