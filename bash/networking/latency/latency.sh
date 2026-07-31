#!/usr/bin/env bash
#
# latency.sh — ping one or more hosts N times and report min/avg/max/stddev
# latency and packet loss per host.
#
# Works with both GNU/BSD ping (Linux/macOS) and Windows ping.exe (as found
# on Git Bash / MSYS2), auto-detected via 'uname'.
#
# Usage: ./latency.sh [options] host [host ...]
# Run with --help for full usage.

set -euo pipefail

SCRIPT_NAME="$(basename "$0")"

COUNT=10
OUTPUT_FORMAT="table"
HOSTS=()

usage() {
  cat <<EOF
Usage: ${SCRIPT_NAME} [options] host [host ...]

Ping one or more hosts --count times and report packet loss percentage and
min/avg/max/stddev round-trip latency for each.

Options:
  --hosts host1,host2   Comma-separated hosts (in addition to any positional hosts)
  --count N             Number of ping packets per host (default: ${COUNT})
  --output FORMAT       table (default) or csv
  -h, --help            Show this help message and exit

Examples:
  ${SCRIPT_NAME} 8.8.8.8
  ${SCRIPT_NAME} --count 20 example.com 1.1.1.1
  ${SCRIPT_NAME} --hosts example.com,1.1.1.1 --output csv

Notes:
  Auto-detects Windows ping.exe (Git Bash / MSYS2) vs GNU/BSD ping and
  parses accordingly.
EOF
}

log()  { printf '[latency] %s\n' "$*"; }
err()  { printf '[latency] ERROR: %s\n' "$*" >&2; }

while [ "$#" -gt 0 ]; do
  case "$1" in
    --hosts)
      [ "$#" -ge 2 ] || { err "--hosts requires a value"; exit 1; }
      IFS=',' read -ra extra_hosts <<< "$2"
      HOSTS+=("${extra_hosts[@]}")
      shift
      ;;
    --count)
      [ "$#" -ge 2 ] || { err "--count requires a value"; exit 1; }
      COUNT="$2"
      shift
      ;;
    --output)
      [ "$#" -ge 2 ] || { err "--output requires a value"; exit 1; }
      OUTPUT_FORMAT="$2"
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
case "$OUTPUT_FORMAT" in table|csv) ;; *) err "Invalid --output format: $OUTPUT_FORMAT"; exit 1 ;; esac

if [ "${#HOSTS[@]}" -eq 0 ]; then
  err "No hosts given."
  usage
  exit 1
fi

if ! command -v ping >/dev/null 2>&1; then
  err "required command not found: ping"
  exit 1
fi

WINDOWS_PING=false
case "$(uname -s 2>/dev/null || echo unknown)" in
  MINGW*|MSYS*|CYGWIN*) WINDOWS_PING=true ;;
esac

[ "$OUTPUT_FORMAT" = "csv" ] && printf 'host,loss_pct,min_ms,avg_ms,max_ms,stddev_ms\n'

for host in "${HOSTS[@]}"; do
  if [ "$WINDOWS_PING" = true ]; then
    output=$(ping -n "$COUNT" -w 2000 "$host" 2>&1) || true
    loss_match=$(printf '%s\n' "$output" | grep -oE '\([0-9]+% loss\)' | head -1)
    loss_pct="${loss_match#(}"
    loss_pct="${loss_pct%\% loss)}"
    stats_line=$(printf '%s\n' "$output" | grep -oE 'Minimum = [0-9]+ ?ms, Maximum = [0-9]+ ?ms, Average = [0-9]+ ?ms' | head -1)
    min_ms=$(printf '%s' "$stats_line" | grep -oE 'Minimum = [0-9]+' | grep -oE '[0-9]+')
    max_ms=$(printf '%s' "$stats_line" | grep -oE 'Maximum = [0-9]+' | grep -oE '[0-9]+')
    avg_ms=$(printf '%s' "$stats_line" | grep -oE 'Average = [0-9]+' | grep -oE '[0-9]+')
    stddev_ms="N/A"
  else
    output=$(ping -c "$COUNT" -W 2 "$host" 2>&1) || true
    loss_match=$(printf '%s\n' "$output" | grep -oE '[0-9]+(\.[0-9]+)?% packet loss' | head -1)
    loss_pct="${loss_match%\%*}"
    rtt_match=$(printf '%s\n' "$output" | grep -oE '[0-9]+\.[0-9]+/[0-9]+\.[0-9]+/[0-9]+\.[0-9]+/[0-9]+\.[0-9]+' | head -1)
    min_ms="${rtt_match%%/*}"
    rest="${rtt_match#*/}"
    avg_ms="${rest%%/*}"
    rest="${rest#*/}"
    max_ms="${rest%%/*}"
    stddev_ms="${rest#*/}"
  fi

  loss_pct="${loss_pct:-N/A}"
  min_ms="${min_ms:-N/A}"
  avg_ms="${avg_ms:-N/A}"
  max_ms="${max_ms:-N/A}"
  stddev_ms="${stddev_ms:-N/A}"

  if [ "$OUTPUT_FORMAT" = "csv" ]; then
    printf '%s,%s,%s,%s,%s,%s\n' "$host" "$loss_pct" "$min_ms" "$avg_ms" "$max_ms" "$stddev_ms"
  else
    log "${host} — loss: ${loss_pct}%  min/avg/max/stddev: ${min_ms}/${avg_ms}/${max_ms}/${stddev_ms} ms"
  fi
done
