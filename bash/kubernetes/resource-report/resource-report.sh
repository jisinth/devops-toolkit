#!/usr/bin/env bash
#
# resource-report.sh — report CPU/memory requests & limits vs actual usage
# (kubectl top) per namespace or pod. Flags containers with no requests or
# no limits set.
#
# Usage: ./resource-report.sh (--namespace <ns> | --all-namespaces) [--pod <name>]
# Run with --help for full usage.

set -euo pipefail

SCRIPT_NAME="$(basename "$0")"

NAMESPACE=""
ALL_NAMESPACES=false
POD=""

usage() {
  cat <<EOF
Usage: ${SCRIPT_NAME} (--namespace <ns> | --all-namespaces) [--pod <name>]

Report each container's CPU/memory requests and limits alongside actual
usage from 'kubectl top pod --containers', per namespace or cluster-wide.
Flags containers that have no requests and/or no limits set.

One of these is required:
  -n, --namespace <ns>   Namespace to report on
  --all-namespaces         Report across all namespaces

Options:
  --pod <name>            Restrict the report to a single pod (requires --namespace)
  -h, --help              Show this help message and exit

Examples:
  ${SCRIPT_NAME} --namespace prod
  ${SCRIPT_NAME} --all-namespaces
  ${SCRIPT_NAME} --namespace prod --pod api-6f9c8d7b4-abc12

Notes:
  Usage figures require the metrics-server (or equivalent) to be installed
  in the cluster. If it isn't, usage columns show N/A but requests/limits
  and flags are still reported.
EOF
}

log()  { printf '[resource-report] %s\n' "$*"; }
err()  { printf '[resource-report] ERROR: %s\n' "$*" >&2; }

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
    --all-namespaces) ALL_NAMESPACES=true; shift ;;
    --pod) POD="${2:-}"; shift 2 ;;
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

if [ -n "$POD" ] && [ "$ALL_NAMESPACES" = true ]; then
  err "--pod requires --namespace (not --all-namespaces)."
  usage
  exit 1
fi

require_kubectl

log "Collecting pod list..."
if [ -n "$POD" ]; then
  if ! kubectl get pod "$POD" -n "$NAMESPACE" >/dev/null 2>&1; then
    err "Pod '${POD}' not found in namespace '${NAMESPACE}'."
    exit 1
  fi
  pod_list="$(printf '%s\t%s' "$NAMESPACE" "$POD")"
elif [ "$ALL_NAMESPACES" = true ]; then
  pod_list="$(kubectl get pods --all-namespaces -o jsonpath='{range .items[*]}{.metadata.namespace}{"\t"}{.metadata.name}{"\n"}{end}')"
else
  pod_list="$(kubectl get pods -n "$NAMESPACE" -o jsonpath='{range .items[*]}{.metadata.namespace}{"\t"}{.metadata.name}{"\n"}{end}')"
fi

if [ -z "$pod_list" ]; then
  log "No pods found."
  exit 0
fi

metrics_available=true
if [ "$ALL_NAMESPACES" = true ]; then
  usage_raw="$(kubectl top pod --all-namespaces --containers --no-headers 2>/dev/null)" || metrics_available=false
else
  usage_raw="$(kubectl top pod -n "$NAMESPACE" --containers --no-headers 2>/dev/null)" || metrics_available=false
fi

if [ "$metrics_available" = false ]; then
  log "WARNING: metrics unavailable (metrics-server not installed?). Usage columns will show N/A."
fi

get_usage() {
  local ns="$1" pod="$2" container="$3"
  [ "$metrics_available" = true ] || { printf 'N/A\tN/A'; return; }
  if [ "$ALL_NAMESPACES" = true ]; then
    printf '%s\n' "$usage_raw" | awk -v ns="$ns" -v pod="$pod" -v c="$container" \
      '$1==ns && $2==pod && $3==c {print $4"\t"$5; found=1} END{if(!found) print "N/A\tN/A"}'
  else
    printf '%s\n' "$usage_raw" | awk -v pod="$pod" -v c="$container" \
      '$1==pod && $2==c {print $3"\t"$4; found=1} END{if(!found) print "N/A\tN/A"}'
  fi
}

printf 'NAMESPACE\tPOD\tCONTAINER\tCPU_REQUEST\tCPU_LIMIT\tCPU_USAGE\tMEM_REQUEST\tMEM_LIMIT\tMEM_USAGE\tFLAGS\n'

flagged=0
total_containers=0

while IFS=$'\t' read -r ns pod; do
  [ -z "$pod" ] && continue

  containers_raw="$(kubectl get pod "$pod" -n "$ns" -o jsonpath='{range .spec.containers[*]}{.name}{"\t"}{.resources.requests.cpu}{"\t"}{.resources.limits.cpu}{"\t"}{.resources.requests.memory}{"\t"}{.resources.limits.memory}{"\n"}{end}' 2>/dev/null)"

  while IFS=$'\t' read -r cname cpu_req cpu_lim mem_req mem_lim; do
    [ -z "$cname" ] && continue
    total_containers=$((total_containers + 1))

    cpu_req_disp="${cpu_req:--}"
    cpu_lim_disp="${cpu_lim:--}"
    mem_req_disp="${mem_req:--}"
    mem_lim_disp="${mem_lim:--}"

    usage="$(get_usage "$ns" "$pod" "$cname")"
    cpu_usage="$(printf '%s' "$usage" | cut -f1)"
    mem_usage="$(printf '%s' "$usage" | cut -f2)"

    flags=""
    [ -z "$cpu_req" ] && flags="${flags}NO_CPU_REQUEST,"
    [ -z "$mem_req" ] && flags="${flags}NO_MEM_REQUEST,"
    [ -z "$cpu_lim" ] && flags="${flags}NO_CPU_LIMIT,"
    [ -z "$mem_lim" ] && flags="${flags}NO_MEM_LIMIT,"
    flags="${flags%,}"
    if [ -n "$flags" ]; then
      flagged=$((flagged + 1))
    else
      flags="-"
    fi

    printf '%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\n' \
      "$ns" "$pod" "$cname" "$cpu_req_disp" "$cpu_lim_disp" "$cpu_usage" "$mem_req_disp" "$mem_lim_disp" "$mem_usage" "$flags"
  done <<< "$containers_raw"
done <<< "$pod_list"

log "Checked ${total_containers} container(s) across the reported pods. Flagged (missing requests/limits): ${flagged}."
