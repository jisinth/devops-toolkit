#!/usr/bin/env bash
#
# namespace-cleanup.sh — find resources stuck in Terminating state in a
# namespace (or --all-namespaces) and report them. --fix attempts to resolve
# stuck terminations by stripping finalizers; this is destructive and
# defaults to a dry-run report, requiring -y/--yes to actually act.
#
# Usage: ./namespace-cleanup.sh (--namespace <ns> | --all-namespaces) [options]
# Run with --help for full usage.

set -euo pipefail

SCRIPT_NAME="$(basename "$0")"

NAMESPACE=""
ALL_NAMESPACES=false
FIX=false
ASSUME_YES=false

usage() {
  cat <<EOF
Usage: ${SCRIPT_NAME} (--namespace <ns> | --all-namespaces) [options]

Find resources (pods, and namespaces themselves) stuck in Terminating state
and report them. By default this is a read-only report; nothing is changed.

--fix attempts to resolve stuck terminations by stripping finalizers via
'kubectl patch'. This is destructive: it still only performs a dry-run
report unless combined with -y/--yes.

One of these is required:
  -n, --namespace <ns>   Namespace to inspect
  --all-namespaces        Inspect all namespaces

Options:
  --fix                   Attempt to fix stuck terminations (requires -y to act)
  -y, --yes               Confirm destructive actions requested by --fix
  -h, --help              Show this help message and exit

Examples:
  ${SCRIPT_NAME} --namespace staging
  ${SCRIPT_NAME} --all-namespaces
  ${SCRIPT_NAME} --namespace staging --fix -y

Notes:
  Stripping finalizers can leave orphaned cloud resources (e.g. LoadBalancers,
  PVs) if the finalizer existed to clean them up first. Review the report
  before using --fix -y.
EOF
}

log()  { printf '[namespace-cleanup] %s\n' "$*"; }
err()  { printf '[namespace-cleanup] ERROR: %s\n' "$*" >&2; }

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

if [ "$#" -eq 0 ]; then
  usage
  exit 0
fi

while [ "$#" -gt 0 ]; do
  case "$1" in
    -n|--namespace) NAMESPACE="${2:-}"; shift 2 ;;
    --all-namespaces) ALL_NAMESPACES=true; shift ;;
    --fix) FIX=true; shift ;;
    -y|--yes) ASSUME_YES=true; shift ;;
    -h|--help) usage; exit 0 ;;
    *)
      err "Unknown option: $1"
      usage
      exit 1
      ;;
  esac
done

if [ "$ALL_NAMESPACES" = false ] && [ -z "$NAMESPACE" ]; then
  err "Either --namespace or --all-namespaces is required."
  usage
  exit 1
fi

if [ "$ALL_NAMESPACES" = true ] && [ -n "$NAMESPACE" ]; then
  err "--namespace and --all-namespaces are mutually exclusive."
  usage
  exit 1
fi

require_kubectl

if [ "$ALL_NAMESPACES" = true ]; then
  ns_flag=(--all-namespaces)
else
  ns_flag=(-n "$NAMESPACE")
fi

log "Scanning for pods stuck in Terminating state..."
stuck_pods="$(kubectl get pods "${ns_flag[@]}" -o jsonpath='{range .items[*]}{.metadata.namespace}{"\t"}{.metadata.name}{"\t"}{.metadata.deletionTimestamp}{"\n"}{end}' 2>/dev/null | awk -F'\t' '$3 != ""')"

stuck_pod_count=0
if [ -n "$stuck_pods" ]; then
  stuck_pod_count="$(printf '%s\n' "$stuck_pods" | wc -l)"
  log "Found ${stuck_pod_count} pod(s) stuck Terminating:"
  printf 'NAMESPACE\tNAME\tDELETION_TIMESTAMP\n'
  printf '%s\n' "$stuck_pods"
else
  log "No pods stuck Terminating."
fi

stuck_namespaces=""
stuck_ns_count=0
if [ "$ALL_NAMESPACES" = true ]; then
  log "Scanning for namespaces stuck in Terminating phase..."
  stuck_namespaces="$(kubectl get namespaces -o jsonpath='{range .items[*]}{.metadata.name}{"\t"}{.status.phase}{"\n"}{end}' 2>/dev/null | awk -F'\t' '$2 == "Terminating"')"
  if [ -n "$stuck_namespaces" ]; then
    stuck_ns_count="$(printf '%s\n' "$stuck_namespaces" | wc -l)"
    log "Found ${stuck_ns_count} namespace(s) stuck Terminating:"
    printf 'NAMESPACE\tPHASE\n'
    printf '%s\n' "$stuck_namespaces"
  else
    log "No namespaces stuck Terminating."
  fi
else
  ns_phase="$(kubectl get namespace "$NAMESPACE" -o jsonpath='{.status.phase}' 2>/dev/null || true)"
  if [ "$ns_phase" = "Terminating" ]; then
    stuck_namespaces="$(printf '%s\tTerminating' "$NAMESPACE")"
    stuck_ns_count=1
    log "Namespace '${NAMESPACE}' itself is stuck Terminating."
  fi
fi

total=$((stuck_pod_count + stuck_ns_count))

if [ "$FIX" = false ]; then
  log "Report complete (dry-run only; pass --fix -y to attempt repairs). Stuck resources found: ${total}."
  exit 0
fi

if [ "$total" -eq 0 ]; then
  log "Nothing to fix."
  exit 0
fi

if ! confirm "This will strip finalizers from ${total} stuck resource(s), which can orphan cloud resources. Continue?"; then
  log "--fix requested but not confirmed (use -y/--yes). No changes made."
  exit 0
fi

fixed=0
failed=0

if [ -n "$stuck_pods" ]; then
  while IFS=$'\t' read -r pod_ns pod_name _; do
    [ -z "$pod_name" ] && continue
    log "Stripping finalizers from pod ${pod_ns}/${pod_name}..."
    if kubectl patch pod "$pod_name" -n "$pod_ns" --type=merge -p '{"metadata":{"finalizers":[]}}' >/dev/null 2>&1; then
      fixed=$((fixed + 1))
    else
      err "Failed to patch pod ${pod_ns}/${pod_name}"
      failed=$((failed + 1))
    fi
  done <<< "$stuck_pods"
fi

if [ -n "$stuck_namespaces" ]; then
  while IFS=$'\t' read -r ns_name _; do
    [ -z "$ns_name" ] && continue
    if ! command -v jq >/dev/null 2>&1; then
      err "jq not found on PATH; cannot safely strip finalizers from namespace '${ns_name}'. Skipping (do it manually via the /finalize subresource)."
      failed=$((failed + 1))
      continue
    fi
    log "Stripping finalizers from namespace ${ns_name} via /finalize subresource..."
    if kubectl get namespace "$ns_name" -o json | jq '.spec.finalizers = []' | kubectl replace --raw "/api/v1/namespaces/${ns_name}/finalize" -f - >/dev/null 2>&1; then
      fixed=$((fixed + 1))
    else
      err "Failed to strip finalizers from namespace ${ns_name}"
      failed=$((failed + 1))
    fi
  done <<< "$stuck_namespaces"
fi

log "Fix complete. Fixed: ${fixed}  Failed: ${failed}"

if [ "$failed" -gt 0 ]; then
  exit 1
fi
