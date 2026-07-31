#!/usr/bin/env bash
#
# restart-deployment.sh — trigger a rolling restart of a deployment and poll
# rollout status until it succeeds, fails, or times out.
#
# Usage: ./restart-deployment.sh --namespace <ns> --deployment <name> [options]
# Run with --help for full usage.

set -euo pipefail

SCRIPT_NAME="$(basename "$0")"

NAMESPACE=""
DEPLOYMENT=""
TIMEOUT="300s"

usage() {
  cat <<EOF
Usage: ${SCRIPT_NAME} --namespace <ns> --deployment <name> [options]

Run 'kubectl rollout restart deployment/<name>' in a namespace, then poll
'kubectl rollout status' until it completes, fails, or the timeout elapses.
Reports success/failure clearly and exits non-zero on failure or timeout.

Required:
  -n, --namespace <ns>     Namespace containing the deployment
  -d, --deployment <name>  Deployment name to restart

Options:
  --timeout <duration>     Max time to wait for rollout (default: ${TIMEOUT}), passed to kubectl rollout status --timeout
  -h, --help                Show this help message and exit

Examples:
  ${SCRIPT_NAME} -n prod -d api
  ${SCRIPT_NAME} -n prod -d api --timeout 120s
EOF
}

log()  { printf '[restart-deployment] %s\n' "$*"; }
err()  { printf '[restart-deployment] ERROR: %s\n' "$*" >&2; }

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

if [ "$#" -eq 0 ]; then
  usage
  exit 0
fi

while [ "$#" -gt 0 ]; do
  case "$1" in
    -n|--namespace) NAMESPACE="${2:-}"; shift 2 ;;
    -d|--deployment) DEPLOYMENT="${2:-}"; shift 2 ;;
    --timeout) TIMEOUT="${2:-}"; shift 2 ;;
    -h|--help) usage; exit 0 ;;
    *)
      err "Unknown option: $1"
      usage
      exit 1
      ;;
  esac
done

if [ -z "$NAMESPACE" ]; then
  err "--namespace is required."
  usage
  exit 1
fi

if [ -z "$DEPLOYMENT" ]; then
  err "--deployment is required."
  usage
  exit 1
fi

require_kubectl

if ! kubectl get deployment "$DEPLOYMENT" -n "$NAMESPACE" >/dev/null 2>&1; then
  err "Deployment '${DEPLOYMENT}' not found in namespace '${NAMESPACE}'."
  exit 1
fi

log "Restarting deployment/${DEPLOYMENT} in namespace '${NAMESPACE}'..."
if ! kubectl rollout restart "deployment/${DEPLOYMENT}" -n "$NAMESPACE"; then
  err "Failed to trigger rollout restart."
  exit 1
fi

log "Waiting for rollout to complete (timeout: ${TIMEOUT})..."
if kubectl rollout status "deployment/${DEPLOYMENT}" -n "$NAMESPACE" --timeout "$TIMEOUT"; then
  log "SUCCESS: deployment/${DEPLOYMENT} rolled out successfully."
  exit 0
else
  err "FAILURE: rollout of deployment/${DEPLOYMENT} did not complete successfully (failed or timed out)."
  exit 1
fi
