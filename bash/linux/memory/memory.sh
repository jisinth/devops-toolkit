#!/usr/bin/env bash
#
# memory.sh — report memory usage (total/used/free/available/cached/swap)
# from free(1) or /proc/meminfo, alert when usage crosses a threshold, and
# optionally show the top memory-consuming processes.
#
# Usage: ./memory.sh [options]
# Run with --help for full usage.

set -euo pipefail

SCRIPT_NAME="$(basename "$0")"

THRESHOLD=90
TOP_N=0

usage() {
  cat <<EOF
Usage: ${SCRIPT_NAME} [options]

Report memory usage via free(1) (falling back to /proc/meminfo), and exit
non-zero if used-memory percentage is at or above --threshold. Optionally
list the top memory-consuming processes.

Options:
  --threshold PCT   Alert threshold as a percentage of memory used (default: ${THRESHOLD})
  --top N           Show the N top memory-consuming processes
  -h, --help        Show this help message and exit

Examples:
  ${SCRIPT_NAME}
  ${SCRIPT_NAME} --threshold 85
  ${SCRIPT_NAME} --top 10
EOF
}

log()  { printf '[memory] %s\n' "$*"; }
err()  { printf '[memory] ERROR: %s\n' "$*" >&2; }

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

USED_PCT=""

if command -v free >/dev/null 2>&1; then
  log "Memory usage (threshold: ${THRESHOLD}%):"
  free -h
  echo
  log "Swap usage:"
  free -h | awk 'NR==1 || /^Swap/'

  # Use free -b for precise percentage math.
  read -r _ total used free_ shared buffcache available < <(free -b | awk '/^Mem:/')
  if [ "${total:-0}" -gt 0 ]; then
    USED_PCT=$(( used * 100 / total ))
  fi
elif [ -r /proc/meminfo ]; then
  log "free(1) not found; falling back to /proc/meminfo"
  total_kb=$(awk '/^MemTotal:/ {print $2}' /proc/meminfo)
  avail_kb=$(awk '/^MemAvailable:/ {print $2}' /proc/meminfo)
  free_kb=$(awk '/^MemFree:/ {print $2}' /proc/meminfo)
  cached_kb=$(awk '/^Cached:/ {print $2; exit}' /proc/meminfo)
  swaptotal_kb=$(awk '/^SwapTotal:/ {print $2}' /proc/meminfo)
  swapfree_kb=$(awk '/^SwapFree:/ {print $2}' /proc/meminfo)
  used_kb=$(( total_kb - free_kb ))
  log "Total: $((total_kb / 1024)) MiB  Used: $((used_kb / 1024)) MiB  Free: $((free_kb / 1024)) MiB  Available: $((avail_kb / 1024)) MiB  Cached: $((cached_kb / 1024)) MiB"
  log "Swap total: $((swaptotal_kb / 1024)) MiB  Swap free: $((swapfree_kb / 1024)) MiB"
  if [ "${total_kb:-0}" -gt 0 ]; then
    USED_PCT=$(( used_kb * 100 / total_kb ))
  fi
else
  err "Neither 'free' nor a readable /proc/meminfo is available on this system."
  exit 1
fi

if [ "$TOP_N" -gt 0 ]; then
  if ! command -v ps >/dev/null 2>&1; then
    err "--top requires 'ps', which was not found."
    exit 1
  fi
  log "Top ${TOP_N} memory-consuming processes:"
  ps -eo pid,ppid,%mem,%cpu,comm --sort=-%mem | head -n "$((TOP_N + 1))"
fi

if [ -z "$USED_PCT" ]; then
  err "Could not determine memory used percentage."
  exit 1
fi

if [ "$USED_PCT" -ge "$THRESHOLD" ]; then
  err "Memory usage at ${USED_PCT}% (>= ${THRESHOLD}% threshold)"
  exit 1
fi

log "Memory usage at ${USED_PCT}%, below the ${THRESHOLD}% threshold."
