#!/usr/bin/env bash
#
# pod-logs.sh — export logs for pods in a namespace matching a label selector
# to gzip-compressed files under --output-dir.
#
# Usage: ./pod-logs.sh --namespace <ns> --selector <selector> --output-dir <dir> [options]
# Run with --help for full usage.

set -euo pipefail

SCRIPT_NAME="$(basename "$0")"

NAMESPACE=""
SELECTOR=""
OUTPUT_DIR=""
SINCE=""
PREVIOUS=false

usage() {
  cat <<EOF
Usage: ${SCRIPT_NAME} --namespace <ns> --selector <selector> --output-dir <dir> [options]

Export logs for pods in a namespace matching a label selector to
gzip-compressed files under --output-dir, one file per pod/container.

Required:
  -n, --namespace <ns>       Namespace to search
  -l, --selector <selector>  Label selector (e.g. app=myapp)
  -o, --output-dir <dir>     Directory to write logs into (created if missing)

Options:
  --since <duration>         Only return logs newer than this (e.g. 1h, 30m), passed to kubectl logs --since
  --previous                 Fetch logs from the previously terminated container (crash logs)
  -h, --help                 Show this help message and exit

Examples:
  ${SCRIPT_NAME} -n prod -l app=api -o ./logs
  ${SCRIPT_NAME} -n prod -l app=api -o ./logs --since 1h
  ${SCRIPT_NAME} -n prod -l app=api -o ./logs --previous
EOF
}

log()  { printf '[pod-logs] %s\n' "$*"; }
err()  { printf '[pod-logs] ERROR: %s\n' "$*" >&2; }

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
    -l|--selector) SELECTOR="${2:-}"; shift 2 ;;
    -o|--output-dir) OUTPUT_DIR="${2:-}"; shift 2 ;;
    --since) SINCE="${2:-}"; shift 2 ;;
    --previous) PREVIOUS=true; shift ;;
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

if [ -z "$SELECTOR" ]; then
  err "--selector is required."
  usage
  exit 1
fi

if [ -z "$OUTPUT_DIR" ]; then
  err "--output-dir is required."
  usage
  exit 1
fi

require_kubectl

mkdir -p "$OUTPUT_DIR"

log "Finding pods in namespace '${NAMESPACE}' matching selector '${SELECTOR}'..."
pods="$(kubectl get pods -n "$NAMESPACE" -l "$SELECTOR" -o jsonpath='{.items[*].metadata.name}')"

if [ -z "$pods" ]; then
  log "No pods found matching selector. Nothing to export."
  exit 0
fi

exported=0
failed=0

for pod in $pods; do
  containers="$(kubectl get pod "$pod" -n "$NAMESPACE" -o jsonpath='{.spec.containers[*].name}')"
  for container in $containers; do
    suffix=""
    [ "$PREVIOUS" = true ] && suffix="_previous"
    outfile="${OUTPUT_DIR}/${NAMESPACE}_${pod}_${container}${suffix}.log.gz"

    log_args=(-n "$NAMESPACE" "$pod" -c "$container")
    [ -n "$SINCE" ] && log_args+=(--since "$SINCE")
    [ "$PREVIOUS" = true ] && log_args+=(--previous)

    log "Exporting logs: pod=${pod} container=${container}${suffix:+ (previous)} -> ${outfile}"
    if kubectl logs "${log_args[@]}" 2>/dev/null | gzip > "$outfile"; then
      exported=$((exported + 1))
    else
      err "Failed to export logs for pod=${pod} container=${container}"
      rm -f "$outfile"
      failed=$((failed + 1))
    fi
  done
done

log "Done. Exported: ${exported}  Failed: ${failed}"

if [ "$failed" -gt 0 ]; then
  exit 1
fi
