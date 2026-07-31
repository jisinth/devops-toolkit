#!/usr/bin/env bash
#
# docker-health.sh — report container health-check status (healthy/
# unhealthy/starting/none), and optionally restart unhealthy containers.
#
# Usage: ./docker-health.sh [options]
# Run with --help for full usage.

set -euo pipefail

SCRIPT_NAME="$(basename "$0")"

FIX=false
ASSUME_YES=false
OUTPUT_FORMAT="table"

usage() {
  cat <<EOF
Usage: ${SCRIPT_NAME} [options]

Report the Docker health-check status (healthy, unhealthy, starting, or
none) of every running container. With --fix, restart any unhealthy
containers.

Options:
  --fix             Restart containers reported as unhealthy
  -y, --yes         Do not prompt for confirmation before restarting
  --output FORMAT   Output format: table (default), csv, or json
  -h, --help        Show this help message and exit

Examples:
  ${SCRIPT_NAME}
  ${SCRIPT_NAME} --output json
  ${SCRIPT_NAME} --fix -y

Notes:
  Containers with no HEALTHCHECK defined are reported as "none" and are
  never restarted by --fix.
EOF
}

log()  { printf '[docker-health] %s\n' "$*"; }
err()  { printf '[docker-health] ERROR: %s\n' "$*" >&2; }

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

confirm() {
  local prompt="$1"
  if [ "$ASSUME_YES" = true ]; then
    return 0
  fi
  read -r -p "${prompt} [y/N] " reply
  case "$reply" in
    [yY][eE][sS]|[yY]) return 0 ;;
    *) return 1 ;;
  esac
}

while [ "$#" -gt 0 ]; do
  case "$1" in
    --fix) FIX=true ;;
    -y|--yes) ASSUME_YES=true ;;
    --output)
      [ "$#" -ge 2 ] || { err "--output requires a value"; exit 1; }
      OUTPUT_FORMAT="$2"
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

case "$OUTPUT_FORMAT" in
  table|csv|json) ;;
  *) err "Invalid --output format: $OUTPUT_FORMAT (expected table, csv, or json)"; exit 1 ;;
esac

require_docker

mapfile -t containers < <(docker ps --format '{{.Names}}')

if [ "${#containers[@]}" -eq 0 ]; then
  log "No running containers."
  exit 0
fi

names=()
statuses=()
unhealthy=()

for name in "${containers[@]}"; do
  health=$(docker inspect --format '{{if .State.Health}}{{.State.Health.Status}}{{else}}none{{end}}' "$name" 2>/dev/null || echo "unknown")
  names+=("$name")
  statuses+=("$health")
  if [ "$health" = "unhealthy" ]; then
    unhealthy+=("$name")
  fi
done

case "$OUTPUT_FORMAT" in
  table)
    printf '%-30s %s\n' "CONTAINER" "HEALTH"
    for i in "${!names[@]}"; do
      printf '%-30s %s\n' "${names[$i]}" "${statuses[$i]}"
    done
    ;;
  csv)
    printf 'container,health\n'
    for i in "${!names[@]}"; do
      printf '%s,%s\n' "${names[$i]}" "${statuses[$i]}"
    done
    ;;
  json)
    printf '['
    for i in "${!names[@]}"; do
      [ "$i" -gt 0 ] && printf ','
      printf '{"container":"%s","health":"%s"}' "${names[$i]}" "${statuses[$i]}"
    done
    printf ']\n'
    ;;
esac

if [ "${#unhealthy[@]}" -eq 0 ]; then
  log "No unhealthy containers."
  exit 0
fi

log "${#unhealthy[@]} unhealthy container(s): ${unhealthy[*]}"

if [ "$FIX" = true ]; then
  if confirm "Restart ${#unhealthy[@]} unhealthy container(s)?"; then
    for name in "${unhealthy[@]}"; do
      log "Restarting $name"
      docker restart "$name"
    done
  else
    log "Skipping restart (not confirmed)."
  fi
fi
