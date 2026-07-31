#!/usr/bin/env bash
#
# docker-network.sh — read-only report of Docker networks, flagging unused
# (zero attached container) networks.
#
# Usage: ./docker-network.sh [options]
# Run with --help for full usage.

set -euo pipefail

SCRIPT_NAME="$(basename "$0")"

UNUSED_ONLY=false

usage() {
  cat <<EOF
Usage: ${SCRIPT_NAME} [options]

Report Docker networks (name, driver, scope, attached container count),
flagging networks with zero attached containers.

Options:
  --unused-only   Only show networks with zero attached containers
  -h, --help      Show this help message and exit

Examples:
  ${SCRIPT_NAME}
  ${SCRIPT_NAME} --unused-only
EOF
}

log()  { printf '[docker-network] %s\n' "$*"; }
err()  { printf '[docker-network] ERROR: %s\n' "$*" >&2; }

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
    --unused-only) UNUSED_ONLY=true ;;
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

mapfile -t network_ids < <(docker network ls --format '{{.ID}}')

printf '%-20s %-15s %-10s %-10s %s\n' "NAME" "DRIVER" "SCOPE" "CONTAINERS" "UNUSED"

unused_count=0

for id in "${network_ids[@]}"; do
  name=$(docker network inspect --format '{{.Name}}' "$id")
  driver=$(docker network inspect --format '{{.Driver}}' "$id")
  scope=$(docker network inspect --format '{{.Scope}}' "$id")
  count=$(docker network inspect --format '{{len .Containers}}' "$id")

  is_unused="no"
  if [ "$count" -eq 0 ]; then
    is_unused="yes"
    unused_count=$((unused_count + 1))
  fi

  if [ "$UNUSED_ONLY" = true ] && [ "$is_unused" = "no" ]; then
    continue
  fi

  printf '%-20s %-15s %-10s %-10s %s\n' "$name" "$driver" "$scope" "$count" "$is_unused"
done

log "${unused_count} unused network(s) found."
