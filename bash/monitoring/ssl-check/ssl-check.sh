#!/usr/bin/env bash
#
# ssl-check.sh — check TLS certificate expiry for one or more domains, and
# alert (non-zero exit) if any certificate expires within --days. Reports
# issuer/subject/expiry per domain. Built for cron/monitoring wrappers:
# --log-file appends results, --webhook POSTs a best-effort alert.
#
# Usage: ./ssl-check.sh [options] domain[:port] [domain[:port] ...]
# Run with --help for full usage.

set -euo pipefail

SCRIPT_NAME="$(basename "$0")"
SCRIPT_TAG="ssl-check"

DAYS=14
LOG_FILE=""
WEBHOOK=""
DOMAINS=()

usage() {
  cat <<EOF
Usage: ${SCRIPT_NAME} [options] domain[:port] [domain[:port] ...]

Check TLS certificate expiry for one or more domains via 'openssl s_client'
and exit non-zero if any certificate expires within --days (or is otherwise
unreachable / unparsable). Reports issuer, subject, and expiry per domain.

Options:
  --days N          Alert if expiry is within N days (default: ${DAYS})
  --log-file PATH   Append timestamped results to this file
  --webhook URL     POST a JSON alert to this URL when any cert breaches the threshold
  -h, --help        Show this help message and exit

Examples:
  ${SCRIPT_NAME} example.com
  ${SCRIPT_NAME} --days 30 example.com api.example.com:8443
  ${SCRIPT_NAME} --log-file /var/log/ssl-check.log --webhook https://hooks.example.com/alert example.com

Notes:
  Ports default to 443. The webhook POST is best-effort: a failed POST is
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

# Convert an X.509 notAfter date string (e.g. "Sep 21 08:40:18 2026 GMT") to
# epoch seconds. Tries GNU date first, then BSD/macOS date.
to_epoch() {
  local datestr="$1"
  if date -d "$datestr" +%s 2>/dev/null; then
    return 0
  fi
  date -j -f "%b %d %T %Y %Z" "$datestr" +%s 2>/dev/null
}

while [ "$#" -gt 0 ]; do
  case "$1" in
    --days)
      [ "$#" -ge 2 ] || { err "--days requires a value"; exit 1; }
      DAYS="$2"
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
    --)
      shift
      while [ "$#" -gt 0 ]; do DOMAINS+=("$1"); shift; done
      ;;
    -*)
      err "Unknown option: $1"
      usage
      exit 1
      ;;
    *)
      DOMAINS+=("$1")
      ;;
  esac
  shift
done

case "$DAYS" in ''|*[!0-9]*) err "--days must be a non-negative integer, got: $DAYS"; exit 1 ;; esac

if [ "${#DOMAINS[@]}" -eq 0 ]; then
  err "No domains given."
  usage
  exit 1
fi

require_cmd openssl

ALERTED=false
now_epoch=$(date +%s)

for entry in "${DOMAINS[@]}"; do
  host="${entry%%:*}"
  if [ "$entry" = "$host" ]; then
    port=443
  else
    port="${entry#*:}"
  fi

  cert=$(timeout 10 openssl s_client -connect "${host}:${port}" -servername "$host" 2>/dev/null </dev/null | openssl x509 -noout -enddate -issuer -subject 2>/dev/null) || cert=""

  if [ -z "$cert" ]; then
    err "${host}:${port} — could not retrieve certificate (connection failed or no cert presented)"
    ALERTED=true
    continue
  fi

  enddate=$(printf '%s\n' "$cert" | awk -F= '/^notAfter=/ {print $2}')
  issuer=$(printf '%s\n' "$cert" | awk -F= '/^issuer=/ {sub(/^issuer=/,""); print}')
  subject=$(printf '%s\n' "$cert" | awk -F= '/^subject=/ {sub(/^subject=/,""); print}')

  if [ -z "$enddate" ]; then
    err "${host}:${port} — could not parse certificate expiry"
    ALERTED=true
    continue
  fi

  exp_epoch=$(to_epoch "$enddate") || exp_epoch=""
  if [ -z "$exp_epoch" ]; then
    err "${host}:${port} — could not parse expiry date: ${enddate}"
    ALERTED=true
    continue
  fi

  days_left=$(( (exp_epoch - now_epoch) / 86400 ))

  log "${host}:${port} — expires ${enddate} (${days_left} days) — subject: ${subject} — issuer: ${issuer}"

  if [ "$days_left" -lt "$DAYS" ]; then
    msg="${host}:${port} certificate expires in ${days_left} days (< ${DAYS} day threshold), on ${enddate}"
    err "$msg"
    notify_webhook "$msg"
    ALERTED=true
  fi
done

if [ "$ALERTED" = true ]; then
  err "One or more certificates are expiring within ${DAYS} days or could not be checked."
  exit 1
fi

log "All certificates are valid for at least ${DAYS} days."
