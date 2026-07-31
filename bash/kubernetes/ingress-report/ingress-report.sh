#!/usr/bin/env bash
#
# ingress-report.sh — list ingresses with hosts, backend services/ports, and
# TLS secret presence, flagging ingresses that reference a missing TLS
# secret.
#
# Usage: ./ingress-report.sh [--namespace <ns>]
# Run with --help for full usage.

set -euo pipefail

SCRIPT_NAME="$(basename "$0")"

NAMESPACE=""

usage() {
  cat <<EOF
Usage: ${SCRIPT_NAME} [options]

List ingresses (all namespaces by default, or a single --namespace) with
their hosts, backend services/ports, and whether each referenced TLS
secret actually exists. Flags ingresses referencing a missing TLS secret.

Options:
  -n, --namespace <ns>   Only report ingresses in this namespace (default: all namespaces)
  -h, --help              Show this help message and exit

Examples:
  ${SCRIPT_NAME}
  ${SCRIPT_NAME} --namespace prod
EOF
}

log()  { printf '[ingress-report] %s\n' "$*"; }
err()  { printf '[ingress-report] ERROR: %s\n' "$*" >&2; }

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
    -n|--namespace)
      [ "$#" -ge 2 ] || { err "--namespace requires a value"; exit 1; }
      NAMESPACE="$2"
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

require_kubectl

if [ -n "$NAMESPACE" ]; then
  ns_flag=(-n "$NAMESPACE")
else
  ns_flag=(--all-namespaces)
fi

ingress_json="$(kubectl get ingress "${ns_flag[@]}" -o json)"

count=$(printf '%s' "$ingress_json" | jq -r '.items | length' 2>/dev/null || echo "")

if [ -z "$count" ]; then
  err "Failed to query ingresses (is jq installed? does this cluster have any Ingress resources?)."
  exit 1
fi

if [ "$count" -eq 0 ]; then
  log "No ingresses found."
  exit 0
fi

log "Found ${count} ingress(es):"
echo

printf '%s' "$ingress_json" | jq -c '.items[]' | while IFS= read -r item; do
  ns=$(printf '%s' "$item" | jq -r '.metadata.namespace')
  name=$(printf '%s' "$item" | jq -r '.metadata.name')
  echo "=== ${ns}/${name} ==="

  printf '%s' "$item" | jq -r '.spec.rules[]? | "  host: \(.host // "*")  ->  " + ((.http.paths[]? | "\(.path // "/") => \(.backend.service.name // .backend.serviceName // "?"):\(.backend.service.port.number // .backend.servicePort // "?")") // "no paths")'

  tls_hosts=$(printf '%s' "$item" | jq -r '.spec.tls[]?.secretName // empty')
  if [ -z "$tls_hosts" ]; then
    echo "  TLS: none configured"
  else
    while IFS= read -r secret; do
      [ -z "$secret" ] && continue
      if kubectl get secret "$secret" -n "$ns" >/dev/null 2>&1; then
        echo "  TLS secret '${secret}': present"
      else
        echo "  TLS secret '${secret}': MISSING"
      fi
    done <<< "$tls_hosts"
  fi
  echo
done

log "Done. Reported on ${count} ingress(es)."
