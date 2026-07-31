#!/usr/bin/env bash
#
# pending-pods.sh — list pods in Pending phase (cluster-wide or
# --namespace), and for each pull recent Events explaining why
# (Unschedulable, ImagePullBackOff, etc.).
#
# Usage: ./pending-pods.sh [--namespace <ns>]
# Run with --help for full usage.

set -euo pipefail

SCRIPT_NAME="$(basename "$0")"

NAMESPACE=""

usage() {
  cat <<EOF
Usage: ${SCRIPT_NAME} [options]

List pods in Pending phase, cluster-wide by default or scoped to a single
namespace, and for each print recent Events (e.g. Unschedulable,
ImagePullBackOff, FailedScheduling) explaining why.

Options:
  -n, --namespace <ns>   Only list pending pods in this namespace (default: all namespaces)
  -h, --help              Show this help message and exit

Examples:
  ${SCRIPT_NAME}
  ${SCRIPT_NAME} --namespace prod
EOF
}

log()  { printf '[pending-pods] %s\n' "$*"; }
err()  { printf '[pending-pods] ERROR: %s\n' "$*" >&2; }

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
    -n|--namespace) NAMESPACE="${2:-}"; shift 2 ;;
    -h|--help) usage; exit 0 ;;
    *)
      err "Unknown option: $1"
      usage
      exit 1
      ;;
  esac
done

require_kubectl

if [ -n "$NAMESPACE" ]; then
  ns_flag=(-n "$NAMESPACE")
else
  ns_flag=(--all-namespaces)
fi

log "Finding pods in Pending phase..."
pending="$(kubectl get pods "${ns_flag[@]}" --field-selector=status.phase=Pending -o jsonpath='{range .items[*]}{.metadata.namespace}{"\t"}{.metadata.name}{"\n"}{end}')"

if [ -z "$pending" ]; then
  log "No pending pods found."
  exit 0
fi

count="$(printf '%s\n' "$pending" | wc -l)"
log "Found ${count} pending pod(s):"
echo

while IFS=$'\t' read -r ns pod; do
  [ -z "$pod" ] && continue
  echo "=== ${ns}/${pod} ==="
  events="$(kubectl get events -n "$ns" --field-selector "involvedObject.name=${pod}" --sort-by='.lastTimestamp' \
    -o custom-columns='TIME:.lastTimestamp,TYPE:.type,REASON:.reason,MESSAGE:.message' --no-headers 2>/dev/null || true)"
  if [ -z "$events" ]; then
    echo "  No events found for this pod."
  else
    printf '%s\n' "$events" | sed 's/^/  /'
  fi
  echo
done <<< "$pending"

log "Done. Reported on ${count} pending pod(s)."
