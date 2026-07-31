#!/usr/bin/env bash
#
# port-scan.sh — scan a single host across a port range using bash's
# /dev/tcp, with a short connect timeout, and report open ports.
#
# AUTHORIZED USE ONLY: only scan hosts you own or are explicitly
# authorized to test. Unauthorized port scanning may be illegal.
#
# Usage: ./port-scan.sh --host <host> [options]
# Run with --help for full usage.

set -euo pipefail

SCRIPT_NAME="$(basename "$0")"

HOST=""
RANGE="1-1024"
TIMEOUT=1

usage() {
  cat <<EOF
Usage: ${SCRIPT_NAME} --host <host> [options]

Scan a single host over a range of TCP ports using bash's /dev/tcp, with a
short per-port connect timeout, and report which ports are open.

  *** AUTHORIZED USE ONLY ***
  Only scan hosts you own or are explicitly authorized to test.
  Unauthorized port scanning may violate laws or acceptable-use policies.

Options:
  --host <host>        Target host (hostname or IP) — required
  --range <start-end>  Port range to scan (default: 1-1024)
  --timeout <seconds>  Per-port connect timeout in seconds (default: 1)
  -h, --help           Show this help message and exit

Examples:
  ${SCRIPT_NAME} --host 127.0.0.1
  ${SCRIPT_NAME} --host 127.0.0.1 --range 1-100 --timeout 1
  ${SCRIPT_NAME} --host example-internal.mycompany.com --range 8000-8100

Output:
  One line per open port. A summary line reports the total scanned and
  how many were found open.
EOF
}

log()  { printf '[port-scan] %s\n' "$*"; }
err()  { printf '[port-scan] ERROR: %s\n' "$*" >&2; }

while [ "$#" -gt 0 ]; do
  case "$1" in
    --host)
      [ "$#" -ge 2 ] || { err "--host requires a value"; exit 1; }
      HOST="$2"
      shift 2
      ;;
    --range)
      [ "$#" -ge 2 ] || { err "--range requires a value"; exit 1; }
      RANGE="$2"
      shift 2
      ;;
    --timeout)
      [ "$#" -ge 2 ] || { err "--timeout requires a value"; exit 1; }
      TIMEOUT="$2"
      shift 2
      ;;
    -h|--help) usage; exit 0 ;;
    *)
      err "Unknown option: $1"
      usage
      exit 1
      ;;
  esac
done

if [ -z "$HOST" ]; then
  err "--host is required."
  usage
  exit 1
fi

if [[ ! "$RANGE" =~ ^[0-9]+-[0-9]+$ ]]; then
  err "--range must be in the form <start-end>, e.g. 1-1024"
  exit 1
fi

START_PORT="${RANGE%-*}"
END_PORT="${RANGE#*-}"

if [ "$START_PORT" -lt 1 ] || [ "$END_PORT" -gt 65535 ] || [ "$START_PORT" -gt "$END_PORT" ]; then
  err "Invalid port range: $RANGE (must be within 1-65535, start <= end)"
  exit 1
fi

if [[ ! "$TIMEOUT" =~ ^[0-9]+(\.[0-9]+)?$ ]]; then
  err "--timeout must be a positive number"
  exit 1
fi

log "AUTHORIZED USE ONLY: only scan hosts you own or are explicitly authorized to test."
log "Scanning $HOST, ports $START_PORT-$END_PORT (timeout ${TIMEOUT}s/port)..."

HAVE_TIMEOUT_CMD=false
if command -v timeout >/dev/null 2>&1; then
  HAVE_TIMEOUT_CMD=true
fi

check_port() {
  local port="$1"
  if [ "$HAVE_TIMEOUT_CMD" = true ]; then
    timeout "$TIMEOUT" bash -c "exec 3<>\"/dev/tcp/${HOST}/${port}\"" 2>/dev/null
  else
    (exec 3<>"/dev/tcp/${HOST}/${port}") 2>/dev/null
  fi
}

open_ports=()
total=$((END_PORT - START_PORT + 1))

if [ "$HAVE_TIMEOUT_CMD" = false ]; then
  log "WARNING: 'timeout' command not found; --timeout will not be enforced (relying on OS connect timeout)."
fi

for ((port = START_PORT; port <= END_PORT; port++)); do
  if check_port "$port"; then
    open_ports+=("$port")
    log "Port $port: OPEN"
  fi
done

log "Scan complete: ${#open_ports[@]} open of $total scanned."
if [ "${#open_ports[@]}" -eq 0 ]; then
  log "No open ports found in range $START_PORT-$END_PORT."
fi
exit 0
