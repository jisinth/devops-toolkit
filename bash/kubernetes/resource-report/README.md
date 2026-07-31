# resource-report

Report CPU/memory requests & limits vs actual usage per namespace or pod, and flag containers with no requests or limits set.

## Purpose

Requests/limits misconfiguration (or omission) is one of the most common causes of noisy-neighbor and OOM problems in Kubernetes. This script gives a single table combining declared requests/limits with live usage (`kubectl top`) so gaps are obvious at a glance.

## Requirements

- `kubectl` CLI on `PATH`
- A reachable, correctly configured cluster (`kubectl cluster-info` must succeed)
- `metrics-server` (or compatible metrics API) installed for usage columns to populate — without it, usage shows `N/A` but requests/limits/flags still work
- Bash 4+

## Usage

```bash
./resource-report.sh (--namespace <ns> | --all-namespaces) [--pod <name>]
```

| Option | Description |
|---|---|
| `-n`, `--namespace <ns>` | Namespace to report on (required unless `--all-namespaces`) |
| `--all-namespaces` | Report across all namespaces (required unless `--namespace`) |
| `--pod <name>` | Restrict the report to a single pod (requires `--namespace`) |
| `-h`, `--help` | Show usage |

Running with no arguments prints usage and exits `0`.

## Examples

See [example.md](example.md).

## Output

Tab-separated table:

```
NAMESPACE  POD  CONTAINER  CPU_REQUEST  CPU_LIMIT  CPU_USAGE  MEM_REQUEST  MEM_LIMIT  MEM_USAGE  FLAGS
```

- `FLAGS` lists any of `NO_CPU_REQUEST`, `NO_MEM_REQUEST`, `NO_CPU_LIMIT`, `NO_MEM_LIMIT` that apply, or `-` if none.
- Usage columns show `N/A` when the metrics API is unavailable.
- Summary line with total containers checked and how many were flagged.

## Troubleshooting

| Symptom | Cause | Fix |
|---|---|---|
| `kubectl CLI not found on PATH` | kubectl not installed / not on PATH | Install kubectl, or fix `PATH` |
| `Kubernetes cluster is not reachable` | No/incorrect kubeconfig, VPN down, cluster unreachable | Check `kubectl config current-context` and connectivity |
| `WARNING: metrics unavailable` | `metrics-server` not installed or not ready | Install/wait for metrics-server; requests/limits/flags are still accurate without it |
| `Pod '<name>' not found` | Wrong pod/namespace | Verify with `kubectl get pods -n <ns>` |
| Usage shows `N/A` for one container but not others | Container just started and hasn't reported metrics yet | Re-run after a short delay |

## References

- [Managing resources for containers](https://kubernetes.io/docs/concepts/configuration/manage-resources-containers/)
- [`kubectl top pod`](https://kubernetes.io/docs/reference/generated/kubectl/kubectl-commands#top)
- [metrics-server](https://github.com/kubernetes-sigs/metrics-server)
