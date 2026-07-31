#!/usr/bin/env bash
#
# website-health.sh — curl one or more URLs, check HTTP status code and
# response time, and alert (non-zero exit) on non-2xx status or a response
# slower than --timeout seconds. Built for cron/monitoring wrappers:
# --log-file appends results, --webhook POSTs a best-effort alert.
#
# Usage: ./website-health.sh [options] [url ...]
# Run with --help for full usage.

set -euo pipefail

SCRIPT_NAME="$(basename "$0")"
SCRIPT_TAG="website-health"

TIMEOUT=10
URL_FILE=""
LOG_FILE=""
WEBHOOK=""
URLS=()

usage() {
  cat <<EOF
Usage: ${SCRIPT_NAME} [options] [url ...]

Check one or more URLs with curl, reporting HTTP status code and response
time for each. Exits non-zero if any URL returns a non-2xx status, fails to
connect, or takes longer than --timeout seconds to respond.

Options:
  --url-file PATH   Read additional URLs from PATH (one per line, '#' comments allowed)
  --timeout SEC     Max response time in seconds before it counts as a failure (default: ${TIMEOUT})
  --log-file PATH   Append timestamped results to this file
  --webhook URL     POST a JSON alert to this URL when a check fails
  -h, --help        Show this help message and exit

Examples:
  ${SCRIPT_NAME} https://example.com
  ${SCRIPT_NAME} --timeout 5 https://example.com https://api.example.com/health
  ${SCRIPT_NAME} --url-file /etc/website-health/urls.txt --log-file /var/log/website-health.log

Notes:
  URLs may be given positionally, via --url-file, or both. The webhook POST
  is best-effort: a failed POST is logged as a warning but does not change
  the exit code.
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
  local payload
  payload=$(printf '{"text":"%s"}' "$(printf '%s' "$message" | sed 's/\\/\\\\/g; s/"/\\"/g')")
  if ! curl -fsS -m 10 -X POST -H 'Content-Type: application/json' -d "$payload" "$WEBHOOK" >/dev/null 2>&1; then
    err "webhook POST failed (best-effort, continuing)"
  fi
}

while [ "$#" -gt 0 ]; do
  case "$1" in
    --url-file)
      [ "$#" -ge 2 ] || { err "--url-file requires a value"; exit 1; }
      URL_FILE="$2"
      shift
      ;;
    --timeout)
      [ "$#" -ge 2 ] || { err "--timeout requires a value"; exit 1; }
      TIMEOUT="$2"
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
    -*)
      err "Unknown option: $1"
      usage
      exit 1
      ;;
    *)
      URLS+=("$1")
      ;;
  esac
  shift
done

case "$TIMEOUT" in ''|*[!0-9]*) err "--timeout must be a non-negative integer, got: $TIMEOUT"; exit 1 ;; esac

if [ -n "$URL_FILE" ]; then
  if [ ! -r "$URL_FILE" ]; then
    err "--url-file not readable: $URL_FILE"
    exit 1
  fi
  while IFS= read -r line || [ -n "$line" ]; do
    line="${line%%#*}"
    line="$(printf '%s' "$line" | sed 's/^[[:space:]]*//; s/[[:space:]]*$//')"
    [ -n "$line" ] && URLS+=("$line")
  done < "$URL_FILE"
fi

if [ "${#URLS[@]}" -eq 0 ]; then
  err "No URLs given. Provide URLs as arguments and/or via --url-file."
  usage
  exit 1
fi

require_cmd curl

ALERTED=false

for url in "${URLS[@]}"; do
  set +e
  result=$(curl -s -o /dev/null -m "$TIMEOUT" -w '%{http_code} %{time_total}' "$url" 2>/dev/null)
  curl_exit=$?
  set -e

  if [ "$curl_exit" -ne 0 ]; then
    if [ "$curl_exit" -eq 28 ]; then
      msg="${url} — timed out after ${TIMEOUT}s"
    else
      msg="${url} — curl failed (exit code ${curl_exit})"
    fi
    err "$msg"
    notify_webhook "$msg"
    ALERTED=true
    continue
  fi

  status="${result%% *}"
  time_total="${result#* }"

  log "${url} — status ${status}, ${time_total}s"

  case "$status" in
    2??) : ;;
    *)
      msg="${url} — non-2xx status: ${status}"
      err "$msg"
      notify_webhook "$msg"
      ALERTED=true
      continue
      ;;
  esac

  if awk -v t="$time_total" -v max="$TIMEOUT" 'BEGIN { exit !(t > max) }'; then
    msg="${url} — response time ${time_total}s exceeds ${TIMEOUT}s threshold"
    err "$msg"
    notify_webhook "$msg"
    ALERTED=true
  fi
done

if [ "$ALERTED" = true ]; then
  err "One or more URLs failed the health check."
  exit 1
fi

log "All URLs passed the health check."
