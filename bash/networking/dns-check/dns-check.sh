#!/usr/bin/env bash
#
# dns-check.sh — resolve a hostname across multiple DNS record types,
# reporting results and query time per type. Prefers `dig`, falls back to
# `host`, then `nslookup`.
#
# Usage: ./dns-check.sh --host <hostname> [options]
# Run with --help for full usage.

set -euo pipefail

SCRIPT_NAME="$(basename "$0")"

HOST=""
TYPES="A,AAAA,MX,TXT,NS"
RESOLVER=""

usage() {
  cat <<EOF
Usage: ${SCRIPT_NAME} --host <hostname> [options]

Resolve a hostname for one or more DNS record types and report the result
and query time for each. Uses 'dig' if available, otherwise falls back to
'host', then 'nslookup'.

Options:
  --host <hostname>   Hostname to resolve (required)
  --types <list>      Comma-separated record types to query
                       (default: A,AAAA,MX,TXT,NS)
  --resolver <ip>     Query this DNS server instead of the system default
  -h, --help          Show this help message and exit

Examples:
  ${SCRIPT_NAME} --host example.com
  ${SCRIPT_NAME} --host example.com --types A,MX --resolver 8.8.8.8
  ${SCRIPT_NAME} --host example.com --types TXT

Notes:
  Query time is measured as wall-clock time around the underlying lookup
  command, so it includes process startup overhead in addition to the
  actual network round trip.
EOF
}

log()  { printf '[dns-check] %s\n' "$*"; }
err()  { printf '[dns-check] ERROR: %s\n' "$*" >&2; }

while [ "$#" -gt 0 ]; do
  case "$1" in
    --host) HOST="${2:-}"; shift 2 ;;
    --types) TYPES="${2:-}"; shift 2 ;;
    --resolver) RESOLVER="${2:-}"; shift 2 ;;
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

TOOL=""
if command -v dig >/dev/null 2>&1; then
  TOOL=dig
elif command -v host >/dev/null 2>&1; then
  TOOL=host
elif command -v nslookup >/dev/null 2>&1; then
  TOOL=nslookup
else
  err "No DNS lookup tool found (need one of: dig, host, nslookup)."
  exit 1
fi

log "Using '${TOOL}' for lookups against ${HOST}${RESOLVER:+ (resolver: $RESOLVER)}"

query_dig() {
  local type="$1"
  dig ${RESOLVER:+"@${RESOLVER}"} -t "$type" "$HOST" +noall +answer 2>&1
}

query_host() {
  local type="$1"
  host -t "$type" "$HOST" ${RESOLVER:+"$RESOLVER"} 2>&1
}

query_nslookup() {
  local type="$1"
  nslookup -type="$type" "$HOST" ${RESOLVER:+"$RESOLVER"} 2>&1
}

IFS=',' read -ra TYPE_LIST <<< "$TYPES"

for type in "${TYPE_LIST[@]}"; do
  type="$(printf '%s' "$type" | tr '[:lower:]' '[:upper:]' | xargs)"
  [ -z "$type" ] && continue

  echo
  log "== ${type} records for ${HOST} =="

  start=$(date +%s%N)
  case "$TOOL" in
    dig) result="$(query_dig "$type" || true)" ;;
    host) result="$(query_host "$type" || true)" ;;
    nslookup) result="$(query_nslookup "$type" || true)" ;;
  esac
  end=$(date +%s%N)
  elapsed_ms=$(( (end - start) / 1000000 ))

  result="$(printf '%s' "$result" | sed '/^[[:space:]]*$/d')"
  if [ -z "$result" ]; then
    echo "  No records found."
  else
    printf '%s\n' "$result" | sed 's/^/  /'
  fi
  printf '  Query time: %d ms\n' "$elapsed_ms"
done
