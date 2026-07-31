#!/usr/bin/env bash
#
# docker-prune.sh — blunt, one-shot "nuke everything unused" wrapper around
# `docker system prune -a --volumes --force`, with a dry-run mode and a
# before/after disk usage report.
#
# Distinct from docker-clean.sh's granular flag-based cleanup: this is the
# simple "just clean everything" button, no per-resource selection.
#
# Usage: ./docker-prune.sh [options]
# Run with --help for full usage.

set -euo pipefail

SCRIPT_NAME="$(basename "$0")"

DRY_RUN=false
ASSUME_YES=false

usage() {
  cat <<EOF
Usage: ${SCRIPT_NAME} [options]

Remove ALL unused Docker data: stopped containers, dangling and unused
images, unused networks, unused volumes, and build cache. Equivalent to
docker system prune -a --volumes --force. Prints a before/after
docker system df report.

Options:
  --dry-run     Show what would be removed without removing anything
  -y, --yes     Do not prompt for confirmation
  -h, --help    Show this help message and exit

Examples:
  ${SCRIPT_NAME} --dry-run
  ${SCRIPT_NAME} -y

Notes:
  This removes ALL unused images (not just dangling ones) and ALL unused
  volumes, which can delete data that is not attached to any container.
  Review the --dry-run output before running destructively.
EOF
}

log()  { printf '[docker-prune] %s\n' "$*"; }
err()  { printf '[docker-prune] ERROR: %s\n' "$*" >&2; }

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

require_docker

log "Docker disk usage before prune:"
docker system df

if [ "$DRY_RUN" = true ]; then
  log "DRY-RUN: would run: docker system prune -a --volumes --force"
  log "Dry run complete. No changes were made."
  exit 0
fi

if ! confirm "This will remove ALL unused containers, images, volumes, and networks. Continue?"; then
  log "Aborted (not confirmed). No changes were made."
  exit 1
fi

log "Removing all unused containers, images, volumes, and networks"
docker system prune -a --volumes --force

log "Docker disk usage after prune:"
docker system df
