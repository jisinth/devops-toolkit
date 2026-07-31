#!/usr/bin/env bash
#
# docker-clean.sh — remove unused Docker containers, images, volumes, networks,
# and build cache, with a dry-run mode and a before/after disk usage report.
#
# Usage: ./docker-clean.sh [options]
# Run with --help for full usage.

set -euo pipefail

SCRIPT_NAME="$(basename "$0")"

# Defaults: nothing is cleaned unless explicitly selected, except --all.
CLEAN_CONTAINERS=false
CLEAN_IMAGES=false
CLEAN_VOLUMES=false
CLEAN_NETWORKS=false
CLEAN_BUILD_CACHE=false
DRY_RUN=false
ASSUME_YES=false

usage() {
  cat <<EOF
Usage: ${SCRIPT_NAME} [options]

Detect Docker, collect current disk usage, perform the requested cleanup,
and print a before/after report.

Options:
  --containers      Remove stopped containers
  --images          Remove dangling and unused images
  --volumes         Remove unused (unmounted) volumes
  --networks        Remove unused networks
  --build-cache     Remove the builder cache
  --all             Clean containers, images, volumes, networks, and build cache
  --dry-run         Show what would be removed without removing anything
  -y, --yes         Do not prompt for confirmation
  -h, --help        Show this help message and exit

Examples:
  ${SCRIPT_NAME} --all --dry-run
  ${SCRIPT_NAME} --images --volumes -y
  ${SCRIPT_NAME} --containers

Notes:
  --volumes can delete data that is not attached to any container. Review
  the --dry-run output before running destructively.
EOF
}

log()  { printf '[docker-clean] %s\n' "$*"; }
err()  { printf '[docker-clean] ERROR: %s\n' "$*" >&2; }

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

run() {
  # run <description> -- <command...>
  local desc="$1"
  shift
  if [ "$DRY_RUN" = true ]; then
    log "DRY-RUN: would run: $*"
    return 0
  fi
  log "$desc"
  "$@"
}

if [ "$#" -eq 0 ]; then
  usage
  exit 0
fi

while [ "$#" -gt 0 ]; do
  case "$1" in
    --containers) CLEAN_CONTAINERS=true ;;
    --images) CLEAN_IMAGES=true ;;
    --volumes) CLEAN_VOLUMES=true ;;
    --networks) CLEAN_NETWORKS=true ;;
    --build-cache) CLEAN_BUILD_CACHE=true ;;
    --all)
      CLEAN_CONTAINERS=true
      CLEAN_IMAGES=true
      CLEAN_VOLUMES=true
      CLEAN_NETWORKS=true
      CLEAN_BUILD_CACHE=true
      ;;
    --dry-run) DRY_RUN=true ;;
    -y|--yes) ASSUME_YES=true ;;
    -h|--help) usage; exit 0 ;;
    *)
      err "Unknown option: $1"
      usage
      exit 1
      ;;
  esac
  shift
done

if ! { [ "$CLEAN_CONTAINERS" = true ] || [ "$CLEAN_IMAGES" = true ] || \
       [ "$CLEAN_VOLUMES" = true ] || [ "$CLEAN_NETWORKS" = true ] || \
       [ "$CLEAN_BUILD_CACHE" = true ]; }; then
  err "Nothing selected to clean. Use --all or one of --containers/--images/--volumes/--networks/--build-cache."
  usage
  exit 1
fi

require_docker

log "Docker disk usage before cleanup:"
docker system df

if [ "$CLEAN_VOLUMES" = true ] && [ "$DRY_RUN" = false ]; then
  if ! confirm "This will remove unused volumes, which can delete data. Continue?"; then
    log "Skipping volume cleanup (not confirmed)."
    CLEAN_VOLUMES=false
  fi
fi

if [ "$CLEAN_CONTAINERS" = true ]; then
  run "Removing stopped containers" docker container prune -f
fi

if [ "$CLEAN_IMAGES" = true ]; then
  run "Removing dangling and unused images" docker image prune -a -f
fi

if [ "$CLEAN_VOLUMES" = true ]; then
  run "Removing unused volumes" docker volume prune -f
fi

if [ "$CLEAN_NETWORKS" = true ]; then
  run "Removing unused networks" docker network prune -f
fi

if [ "$CLEAN_BUILD_CACHE" = true ]; then
  run "Removing build cache" docker builder prune -f
fi

if [ "$DRY_RUN" = true ]; then
  log "Dry run complete. No changes were made."
  exit 0
fi

log "Docker disk usage after cleanup:"
docker system df
