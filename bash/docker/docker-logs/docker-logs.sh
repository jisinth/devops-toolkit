#!/usr/bin/env bash
#
# docker-logs.sh — export logs for one or all containers to gzip-compressed
# files under an output directory.
#
# Usage: ./docker-logs.sh [options]
# Run with --help for full usage.

set -euo pipefail

SCRIPT_NAME="$(basename "$0")"

CONTAINER=""
SINCE=""
TAIL=""
OUTPUT_DIR="./docker-logs"

usage() {
  cat <<EOF
Usage: ${SCRIPT_NAME} [options]

Export logs for one container (--container) or all containers to
gzip-compressed files under --output-dir.

Options:
  --container NAME   Export logs for a single container (default: all running containers)
  --since TIME       Only return logs since this time (passed through to 'docker logs --since')
  --tail N           Only return the last N lines (passed through to 'docker logs --tail')
  --output-dir PATH  Directory to write log files to (default: ${OUTPUT_DIR})
  -h, --help         Show this help message and exit

Examples:
  ${SCRIPT_NAME}
  ${SCRIPT_NAME} --container web --since 1h
  ${SCRIPT_NAME} --tail 500 --output-dir /tmp/logs
EOF
}

log()  { printf '[docker-logs] %s\n' "$*"; }
err()  { printf '[docker-logs] ERROR: %s\n' "$*" >&2; }

require_docker() {
  if ! command -v docker >/dev/null 2>&1; then
    err "docker CLI not found on PATH."
    exit 1
  fi
  if ! docker info >/dev/null 2>&1; then
    err "Docker daemon is not reachable (is it running? do you have permission?)."
    exit 1
  fi
}

while [ "$#" -gt 0 ]; do
  case "$1" in
    --container)
      [ "$#" -ge 2 ] || { err "--container requires a value"; exit 1; }
      CONTAINER="$2"
      shift
      ;;
    --since)
      [ "$#" -ge 2 ] || { err "--since requires a value"; exit 1; }
      SINCE="$2"
      shift
      ;;
    --tail)
      [ "$#" -ge 2 ] || { err "--tail requires a value"; exit 1; }
      TAIL="$2"
      shift
      ;;
    --output-dir)
      [ "$#" -ge 2 ] || { err "--output-dir requires a value"; exit 1; }
      OUTPUT_DIR="$2"
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

require_docker

mkdir -p "$OUTPUT_DIR"

if [ -n "$CONTAINER" ]; then
  containers=("$CONTAINER")
else
  mapfile -t containers < <(docker ps --format '{{.Names}}')
fi

if [ "${#containers[@]}" -eq 0 ]; then
  log "No running containers to export logs from."
  exit 0
fi

docker_log_args=()
[ -n "$SINCE" ] && docker_log_args+=(--since "$SINCE")
[ -n "$TAIL" ] && docker_log_args+=(--tail "$TAIL")

timestamp="$(date '+%Y%m%d-%H%M%S')"

for name in "${containers[@]}"; do
  if ! docker inspect "$name" >/dev/null 2>&1; then
    err "No such container: $name"
    continue
  fi
  outfile="${OUTPUT_DIR}/${name}-${timestamp}.log.gz"
  log "Exporting logs for $name -> $outfile"
  docker logs "${docker_log_args[@]}" "$name" 2>&1 | gzip > "$outfile"
done

log "Done. Logs written to ${OUTPUT_DIR}"
