#!/usr/bin/env bash
#
# cpu.sh — report overall CPU usage percentage and load average, alert when
# usage crosses a threshold, and optionally show the top CPU-consuming
# processes.
#
# Usage: ./cpu.sh [options]
# Run with --help for full usage.

set -euo pipefail

SCRIPT_NAME="$(basename "$0")"

THRESHOLD=90
TOP_N=0
INTERVAL=1

usage() {
  cat <<EOF
Usage: ${SCRIPT_NAME} [options]

Report overall CPU usage (sampled from /proc/stat over --interval seconds)
and load average, and exit non-zero if usage is at or above --threshold.
Optionally list the top CPU-consuming processes.

Options:
  --threshold PCT   Alert threshold as a percentage of CPU used (default: ${THRESHOLD})
  --top N           Show the N top CPU-consuming processes
  --interval SEC    Sampling interval in seconds for CPU usage (default: ${INTERVAL})
  -h, --help        Show this help message and exit

Examples:
  ${SCRIPT_NAME}
  ${SCRIPT_NAME} --threshold 80
  ${SCRIPT_NAME} --top 10 --interval 2
EOF
}

log()  { printf '[cpu] %s\n' "$*"; }
err()  { printf '[cpu] ERROR: %s\n' "$*" >&2; }

while [ "$#" -gt 0 ]; do
  case "$1" in
    --threshold)
      [ "$#" -ge 2 ] || { err "--threshold requires a value"; exit 1; }
      THRESHOLD="$2"
      shift
      ;;
    --top)
      [ "$#" -ge 2 ] || { err "--top requires a value"; exit 1; }
      TOP_N="$2"
      shift
      ;;
    --interval)
      [ "$#" -ge 2 ] || { err "--interval requires a value"; exit 1; }
      INTERVAL="$2"
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

case "$THRESHOLD" in
  ''|*[!0-9]*) err "--threshold must be a non-negative integer, got: $THRESHOLD"; exit 1 ;;
esac
case "$TOP_N" in
  ''|*[!0-9]*) err "--top must be a non-negative integer, got: $TOP_N"; exit 1 ;;
esac
case "$INTERVAL" in
  ''|*[!0-9]*) err "--interval must be a non-negative integer, got: $INTERVAL"; exit 1 ;;
esac

if [ ! -r /proc/stat ]; then
  err "/proc/stat is not readable. This script requires Linux's /proc filesystem."
  exit 1
fi

read_cpu_total_idle() {
  # First line of /proc/stat: cpu user nice system idle iowait irq softirq ...
  local line
  line=$(awk '/^cpu / {print; exit}' /proc/stat)
  local -a fields
  read -r -a fields <<<"$line"
  local total=0
  local i
  for i in "${fields[@]:1}"; do
    total=$((total + i))
  done
  local idle="${fields[4]}"
  printf '%s %s\n' "$total" "$idle"
}

log "Sampling CPU usage over ${INTERVAL}s..."
read -r total1 idle1 <<<"$(read_cpu_total_idle)"
sleep "$INTERVAL"
read -r total2 idle2 <<<"$(read_cpu_total_idle)"

total_delta=$((total2 - total1))
idle_delta=$((idle2 - idle1))

CPU_PCT=0
if [ "$total_delta" -gt 0 ]; then
  CPU_PCT=$(( (100 * (total_delta - idle_delta)) / total_delta ))
fi

log "Overall CPU usage: ${CPU_PCT}% (threshold: ${THRESHOLD}%)"

if [ -r /proc/loadavg ]; then
  read -r one five fifteen _ < /proc/loadavg
  log "Load average: 1m=${one} 5m=${five} 15m=${fifteen}"
elif command -v uptime >/dev/null 2>&1; then
  log "Load average: $(uptime | sed 's/.*load average: //')"
else
  log "Load average: unavailable (no /proc/loadavg or uptime)"
fi

if [ "$TOP_N" -gt 0 ]; then
  if ! command -v ps >/dev/null 2>&1; then
    err "--top requires 'ps', which was not found."
    exit 1
  fi
  log "Top ${TOP_N} CPU-consuming processes:"
  ps -eo pid,ppid,%cpu,%mem,comm --sort=-%cpu | head -n "$((TOP_N + 1))"
fi

if [ "$CPU_PCT" -ge "$THRESHOLD" ]; then
  err "CPU usage at ${CPU_PCT}% (>= ${THRESHOLD}% threshold)"
  exit 1
fi

log "CPU usage below the ${THRESHOLD}% threshold."
