#!/usr/bin/env bash
#
# docker-volumes.sh — read-only report of Docker volumes: name, driver,
# mountpoint, and whether each volume is currently attached to any
# container (running or stopped).
#
# Usage: ./docker-volumes.sh [options]
# Run with --help for full usage.

set -euo pipefail

SCRIPT_NAME="$(basename "$0")"

UNATTACHED_ONLY=false
OUTPUT_FORMAT="table"

usage() {
  cat <<EOF
Usage: ${SCRIPT_NAME} [options]

Read-only report of local Docker volumes: name, driver, mountpoint, and
whether the volume is attached to any container (running or stopped).
Makes no changes to Docker state.

Options:
  --unattached-only   Show only volumes not attached to any container
  --output FORMAT      Output format: table (default), csv, or json
  -h, --help           Show this help message and exit

Examples:
  ${SCRIPT_NAME}
  ${SCRIPT_NAME} --unattached-only
  ${SCRIPT_NAME} --output json
EOF
}

log()  { printf '[docker-volumes] %s\n' "$*"; }
err()  { printf '[docker-volumes] ERROR: %s\n' "$*" >&2; }

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

json_escape() {
  printf '%s' "$1" | sed 's/\\/\\\\/g; s/"/\\"/g'
}

while [ "$#" -gt 0 ]; do
  case "$1" in
    --unattached-only) UNATTACHED_ONLY=true ;;
    --output)
      [ "$#" -ge 2 ] || { err "--output requires an argument (table|csv|json)"; exit 1; }
      OUTPUT_FORMAT="$2"
      shift
      ;;
    --output=*) OUTPUT_FORMAT="${1#*=}" ;;
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
  *)
    err "Invalid --output value: ${OUTPUT_FORMAT} (expected table, csv, or json)"
    exit 1
    ;;
esac

require_docker

NAMES="$(docker volume ls --format '{{.Name}}')"

if [ -z "$NAMES" ]; then
  log "No volumes found."
  exit 0
fi

rows=()
while IFS= read -r name; do
  [ -z "$name" ] && continue
  driver="$(docker volume inspect "$name" --format '{{.Driver}}' 2>/dev/null || echo unknown)"
  mountpoint="$(docker volume inspect "$name" --format '{{.Mountpoint}}' 2>/dev/null || echo unknown)"
  attached_containers="$(docker ps -a --filter "volume=${name}" --format '{{.Names}}')"
  if [ -n "$attached_containers" ]; then
    attached="true"
  else
    attached="false"
  fi

  if [ "$UNATTACHED_ONLY" = true ] && [ "$attached" = "true" ]; then
    continue
  fi

  rows+=("${name}	${driver}	${mountpoint}	${attached}")
done <<< "$NAMES"

if [ "${#rows[@]}" -eq 0 ]; then
  log "No volumes match the given filters."
  exit 0
fi

case "$OUTPUT_FORMAT" in
  table)
    {
      printf 'NAME\tDRIVER\tMOUNTPOINT\tATTACHED\n'
      for row in "${rows[@]}"; do
        printf '%s\n' "$row"
      done
    } | column -t -s $'\t'
    ;;
  csv)
    printf 'Name,Driver,Mountpoint,Attached\n'
    for row in "${rows[@]}"; do
      IFS=$'\t' read -r name driver mountpoint attached <<< "$row"
      printf '%s,%s,%s,%s\n' "$name" "$driver" "$mountpoint" "$attached"
    done
    ;;
  json)
    printf '[\n'
    total="${#rows[@]}"
    i=0
    for row in "${rows[@]}"; do
      i=$((i + 1))
      IFS=$'\t' read -r name driver mountpoint attached <<< "$row"
      printf '  {"name": "%s", "driver": "%s", "mountpoint": "%s", "attached": %s}' \
        "$(json_escape "$name")" "$(json_escape "$driver")" "$(json_escape "$mountpoint")" "$attached"
      if [ "$i" -lt "$total" ]; then printf ','; fi
      printf '\n'
    done
    printf ']\n'
    ;;
esac
