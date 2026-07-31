#!/usr/bin/env bash
#
# port-check.sh — check whether specific TCP port(s) on a host are open,
# reporting open/closed/filtered with connect latency. Uses bash's built-in
# /dev/tcp, so no nc/ncat dependency.
#
# This is a small, targeted check for a handful of known ports. For a
# broader range sweep, see bash/security/port-scan.sh instead.
#
# Usage: ./port-check.sh --host <hostname> --ports <list> [options]
# Run with --help for full usage.

set -euo pipefail

SCRIPT_NAME="$(basename "$0")"

HOST=""
PORTS=""
TIMEOUT=3

usage() {
  cat <<EOF
Usage: ${SCRIPT_NAME} --host <hostname> --ports <list> [options]

Check whether specific TCP ports on a host are open. Reports each port as
open, closed, or filtered, along with connect latency for open ports.

Options:
  --host <hostname>   Host to check (required)
  --ports <list>      Comma-separated ports and/or ranges, e.g. 22,80,443
                       or 20-25 (required)
  --timeout <secs>    Per-port connect timeout in seconds (default: 3)
  -h, --help          Show this help message and exit

Examples:
  ${SCRIPT_NAME} --host example.com --ports 22,80,443
  ${SCRIPT_NAME} --host 127.0.0.1 --ports 20-25
  ${SCRIPT_NAME} --host example.com --ports 443 --timeout 5

Notes:
  - open:     TCP handshake completed within the timeout.
  - closed:   remote host actively refused the connection (fast failure).
  - filtered: no response before the timeout (likely dropped by a firewall).
EOF
}

log()  { printf '[port-check] %s\n' "$*"; }
err()  { printf '[port-check] ERROR: %s\n' "$*" >&2; }

while [ "$#" -gt 0 ]; do
  case "$1" in
    --host) HOST="${2:-}"; shift 2 ;;
    --ports) PORTS="${2:-}"; shift 2 ;;
    --timeout) TIMEOUT="${2:-}"; shift 2 ;;
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

if [ -z "$PORTS" ]; then
  err "--ports is required."
  usage
  exit 1
fi

if ! command -v timeout >/dev/null 2>&1; then
  err "'timeout' command not found (part of GNU coreutils)."
  exit 1
fi

case "$TIMEOUT" in
  ''|*[!0-9]*) err "--timeout must be a positive integer."; exit 1 ;;
esac

parse_ports() {
  local spec="$1" part start end p
  IFS=',' read -ra parts <<< "$spec"
  for part in "${parts[@]}"; do
    part="$(printf '%s' "$part" | xargs)"
    if [[ "$part" =~ ^([0-9]+)-([0-9]+)$ ]]; then
      start="${BASH_REMATCH[1]}"
      end="${BASH_REMATCH[2]}"
      if [ "$start" -gt "$end" ]; then
        err "Invalid port range: $part"
        exit 1
      fi
      for ((p = start; p <= end; p++)); do
        echo "$p"
      done
    elif [[ "$part" =~ ^[0-9]+$ ]]; then
      echo "$part"
    else
      err "Invalid port spec: $part"
      exit 1
    fi
  done
}

check_port() {
  local port="$1" start end elapsed_ms rc
  start=$(date +%s%N)
  rc=0
  timeout "$TIMEOUT" bash -c "exec 3<>/dev/tcp/${HOST}/${port}" 2>/dev/null || rc=$?
  end=$(date +%s%N)
  elapsed_ms=$(( (end - start) / 1000000 ))

  if [ "$rc" -eq 0 ]; then
    exec 3>&- 3<&- 2>/dev/null || true
    printf '  %-6s open       connect time: %d ms\n' "$port" "$elapsed_ms"
  elif [ "$rc" -eq 124 ]; then
    printf '  %-6s filtered   timed out after %ss\n' "$port" "$TIMEOUT"
  else
    printf '  %-6s closed     connection refused (%d ms)\n' "$port" "$elapsed_ms"
  fi
}

PORT_LIST="$(parse_ports "$PORTS")"

log "Checking ${HOST} (timeout: ${TIMEOUT}s per port)"
echo

while IFS= read -r port; do
  [ -z "$port" ] && continue
  check_port "$port"
done <<< "$PORT_LIST"
