#!/usr/bin/env bash
#
# ping-check.sh — ping one or more hosts, report packet loss % and average
# latency, and alert (non-zero exit) if loss exceeds --max-loss or latency
# exceeds --max-latency-ms. Built for cron/monitoring wrappers: --log-file
# appends results, --webhook POSTs a best-effort alert.
#
# Works with both GNU/BSD ping (Linux/macOS) and Windows ping.exe (as found
# on Git Bash / MSYS2), auto-detected via 'uname'.
#
# Usage: ./ping-check.sh [options] host [host ...]
# Run with --help for full usage.

set -euo pipefail

SCRIPT_NAME="$(basename "$0")"
SCRIPT_TAG="ping-check"

COUNT=5
MAX_LOSS=20
MAX_LATENCY_MS=""
LOG_FILE=""
WEBHOOK=""
HOSTS=()

usage() {
  cat <<EOF
Usage: ${SCRIPT_NAME} [options] host [host ...]

Ping one or more hosts and report packet loss percentage and average
round-trip latency. Exits non-zero if any host's loss exceeds --max-loss,
or (when set) its average latency exceeds --max-latency-ms.

Options:
  --count N            Number of ping packets to send per host (default: ${COUNT})
  --max-loss PCT        Alert if packet loss exceeds this percentage (default: ${MAX_LOSS})
  --max-latency-ms MS   Alert if average latency exceeds this many milliseconds (default: unset, not checked)
  --log-file PATH       Append timestamped results to this file
  --webhook URL          POST a JSON alert to this URL when a host breaches a threshold
  -h, --help             Show this help message and exit

Examples:
  ${SCRIPT_NAME} 8.8.8.8
  ${SCRIPT_NAME} --count 10 --max-loss 10 --max-latency-ms 100 example.com 1.1.1.1
  ${SCRIPT_NAME} --log-file /var/log/ping-check.log --webhook https://hooks.example.com/alert example.com

Notes:
  Auto-detects Windows ping.exe (Git Bash / MSYS2) vs GNU/BSD ping and
  parses accordingly. The webhook POST is best-effort: a failed POST is
  logged as a warning but does not change the exit code.
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
    --count)
      [ "$#" -ge 2 ] || { err "--count requires a value"; exit 1; }
      COUNT="$2"
      shift
      ;;
    --max-loss)
      [ "$#" -ge 2 ] || { err "--max-loss requires a value"; exit 1; }
      MAX_LOSS="$2"
      shift
      ;;
    --max-latency-ms)
      [ "$#" -ge 2 ] || { err "--max-latency-ms requires a value"; exit 1; }
      MAX_LATENCY_MS="$2"
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
      HOSTS+=("$1")
      ;;
  esac
  shift
done

case "$COUNT" in ''|*[!0-9]*) err "--count must be a non-negative integer, got: $COUNT"; exit 1 ;; esac
case "$MAX_LOSS" in ''|*[!0-9]*) err "--max-loss must be a non-negative integer, got: $MAX_LOSS"; exit 1 ;; esac
if [ -n "$MAX_LATENCY_MS" ]; then
  case "$MAX_LATENCY_MS" in ''|*[!0-9]*) err "--max-latency-ms must be a non-negative integer, got: $MAX_LATENCY_MS"; exit 1 ;; esac
fi

if [ "${#HOSTS[@]}" -eq 0 ]; then
  err "No hosts given."
  usage
  exit 1
fi

require_cmd ping
require_cmd awk

WINDOWS_PING=false
case "$(uname -s 2>/dev/null || echo unknown)" in
  MINGW*|MSYS*|CYGWIN*) WINDOWS_PING=true ;;
esac

ALERTED=false

for host in "${HOSTS[@]}"; do
  if [ "$WINDOWS_PING" = true ]; then
    output=$(ping -n "$COUNT" -w 2000 "$host" 2>&1) || true
    loss_match=$(printf '%s\n' "$output" | grep -oE '\([0-9]+% loss\)' | head -1)
    loss_pct="${loss_match#(}"
    loss_pct="${loss_pct%\% loss)}"
    avg_match=$(printf '%s\n' "$output" | grep -oE 'Average = [0-9]+ ?ms' | head -1)
    avg_ms="${avg_match#Average = }"
    avg_ms="${avg_ms%ms}"
    avg_ms="${avg_ms% }"
  else
    output=$(ping -c "$COUNT" -W 2 "$host" 2>&1) || true
    loss_match=$(printf '%s\n' "$output" | grep -oE '[0-9]+(\.[0-9]+)?% packet loss' | head -1)
    loss_pct="${loss_match%\%*}"
    rtt_match=$(printf '%s\n' "$output" | grep -oE '[0-9]+\.[0-9]+/[0-9]+\.[0-9]+/[0-9]+\.[0-9]+' | head -1)
    avg_ms="${rtt_match#*/}"
    avg_ms="${avg_ms%%/*}"
  fi

  if [ -z "$loss_pct" ]; then
    msg="${host} — could not determine packet loss (unresolvable host or unexpected ping output)"
    err "$msg"
    notify_webhook "$msg"
    ALERTED=true
    continue
  fi

  if [ -n "$avg_ms" ]; then
    log "${host} — ${loss_pct}% loss, avg ${avg_ms}ms (${COUNT} packets)"
  else
    log "${host} — ${loss_pct}% loss, avg N/A (${COUNT} packets)"
  fi

  host_alerted=false

  if awk -v l="$loss_pct" -v m="$MAX_LOSS" 'BEGIN { exit !(l > m) }'; then
    msg="${host} — packet loss ${loss_pct}% exceeds ${MAX_LOSS}% threshold"
    err "$msg"
    notify_webhook "$msg"
    host_alerted=true
  fi

  if [ -n "$MAX_LATENCY_MS" ] && [ -n "$avg_ms" ]; then
    if awk -v a="$avg_ms" -v m="$MAX_LATENCY_MS" 'BEGIN { exit !(a > m) }'; then
      msg="${host} — average latency ${avg_ms}ms exceeds ${MAX_LATENCY_MS}ms threshold"
      err "$msg"
      notify_webhook "$msg"
      host_alerted=true
    fi
  fi

  [ "$host_alerted" = true ] && ALERTED=true
done

if [ "$ALERTED" = true ]; then
  err "One or more hosts breached the loss or latency threshold."
  exit 1
fi

log "All hosts are within the packet loss and latency thresholds."
