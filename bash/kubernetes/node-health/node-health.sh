#!/usr/bin/env bash
#
# node-health.sh — report node status/conditions (Ready, MemoryPressure,
# DiskPressure, PIDPressure, NetworkUnavailable). Flags NotReady/unhealthy
# nodes and exits non-zero if any are found, so it's usable in alerting/CI.
#
# Usage: ./node-health.sh [options]
# Run with --help for full usage.

set -euo pipefail

SCRIPT_NAME="$(basename "$0")"

NODE=""

usage() {
  cat <<EOF
Usage: ${SCRIPT_NAME} [options]

Report node status and key conditions (Ready, MemoryPressure, DiskPressure,
PIDPressure, NetworkUnavailable) for every node in the cluster, or a single
node with --node. Flags unhealthy nodes and exits non-zero if any are found.

Options:
  --node <name>   Only report on this node (default: all nodes)
  -h, --help      Show this help message and exit

Examples:
  ${SCRIPT_NAME}
  ${SCRIPT_NAME} --node worker-3
EOF
}

log()  { printf '[node-health] %s\n' "$*"; }
err()  { printf '[node-health] ERROR: %s\n' "$*" >&2; }

require_kubectl() {
  if ! command -v kubectl >/dev/null 2>&1; then
    err "kubectl CLI not found on PATH."
    exit 1
  fi
  if ! kubectl cluster-info >/dev/null 2>&1; then
    err "Kubernetes cluster is not reachable (check your kubeconfig/context)."
    exit 1
  fi
}

while [ "$#" -gt 0 ]; do
  case "$1" in
    --node) NODE="${2:-}"; shift 2 ;;
    -h|--help) usage; exit 0 ;;
    *)
      err "Unknown option: $1"
      usage
      exit 1
      ;;
  esac
done

require_kubectl

if [ -n "$NODE" ]; then
  if ! kubectl get node "$NODE" >/dev/null 2>&1; then
    err "Node '${NODE}' not found."
    exit 1
  fi
  nodes="$NODE"
else
  nodes="$(kubectl get nodes -o jsonpath='{.items[*].metadata.name}')"
fi

if [ -z "$nodes" ]; then
  log "No nodes found."
  exit 0
fi

printf 'NODE\tREADY\tMEMORY_PRESSURE\tDISK_PRESSURE\tPID_PRESSURE\tNETWORK_UNAVAILABLE\tSTATUS\n'

unhealthy_count=0
total_count=0

for node in $nodes; do
  total_count=$((total_count + 1))

  conditions="$(kubectl get node "$node" -o jsonpath='{range .status.conditions[*]}{.type}={.status}{"\n"}{end}')"

  ready="Unknown"
  mem_pressure="Unknown"
  disk_pressure="Unknown"
  pid_pressure="Unknown"
  net_unavailable="Unknown"

  while IFS='=' read -r ctype cstatus; do
    case "$ctype" in
      Ready) ready="$cstatus" ;;
      MemoryPressure) mem_pressure="$cstatus" ;;
      DiskPressure) disk_pressure="$cstatus" ;;
      PIDPressure) pid_pressure="$cstatus" ;;
      NetworkUnavailable) net_unavailable="$cstatus" ;;
    esac
  done <<< "$conditions"

  status="Healthy"
  if [ "$ready" != "True" ] || [ "$mem_pressure" = "True" ] || [ "$disk_pressure" = "True" ] || \
     [ "$pid_pressure" = "True" ] || [ "$net_unavailable" = "True" ]; then
    status="UNHEALTHY"
    unhealthy_count=$((unhealthy_count + 1))
  fi

  printf '%s\t%s\t%s\t%s\t%s\t%s\t%s\n' "$node" "$ready" "$mem_pressure" "$disk_pressure" "$pid_pressure" "$net_unavailable" "$status"
done

log "Checked ${total_count} node(s). Unhealthy: ${unhealthy_count}."

if [ "$unhealthy_count" -gt 0 ]; then
  exit 1
fi
