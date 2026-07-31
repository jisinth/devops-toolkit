#!/usr/bin/env bash
#
# service-status.sh — report systemd service status, list failed services,
# and optionally restart failed services matching a name filter.
#
# Usage: ./service-status.sh [options]
# Run with --help for full usage.

set -euo pipefail

SCRIPT_NAME="$(basename "$0")"

FIX=false
ASSUME_YES=false
FILTER_NAME=""

usage() {
  cat <<EOF
Usage: ${SCRIPT_NAME} [options]

Report systemd services in a failed state (systemctl --failed). With
--fix, restart failed services matching --name (or all failed services
if --name is omitted), gated by confirmation or -y.

Options:
  --name PATTERN   Only consider failed services whose unit name matches this pattern
  --fix            Restart matching failed services
  -y, --yes        Do not prompt for confirmation before --fix acts
  -h, --help       Show this help message and exit

Examples:
  ${SCRIPT_NAME}
  ${SCRIPT_NAME} --name nginx --fix
  ${SCRIPT_NAME} --fix -y
EOF
}

log()  { printf '[service-status] %s\n' "$*"; }
err()  { printf '[service-status] ERROR: %s\n' "$*" >&2; }

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
    --name)
      [ "$#" -ge 2 ] || { err "--name requires a value"; exit 1; }
      FILTER_NAME="$2"
      shift
      ;;
    --fix) FIX=true ;;
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

if ! command -v systemctl >/dev/null 2>&1; then
  err "systemctl not found; this script requires a systemd-based Linux host."
  exit 1
fi

log "Failed services:"
failed_raw="$(systemctl --failed --no-legend --plain 2>/dev/null || true)"

if [ -z "$failed_raw" ]; then
  log "No failed services."
  exit 0
fi

mapfile -t failed_units < <(printf '%s\n' "$failed_raw" | awk '{print $1}')

matched_units=()
for unit in "${failed_units[@]}"; do
  if [ -n "$FILTER_NAME" ] && ! printf '%s' "$unit" | grep -q -- "$FILTER_NAME"; then
    continue
  fi
  matched_units+=("$unit")
  echo "  $unit"
done

log "${#matched_units[@]} matching failed service(s)."

if [ "${#matched_units[@]}" -eq 0 ]; then
  exit 0
fi

if [ "$FIX" = true ]; then
  if confirm "Restart ${#matched_units[@]} failed service(s)?"; then
    for unit in "${matched_units[@]}"; do
      log "Restarting $unit"
      systemctl restart "$unit" || err "Failed to restart $unit"
    done
  else
    log "Skipping restart (not confirmed)."
  fi
else
  exit 1
fi
