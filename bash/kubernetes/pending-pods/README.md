# pending-pods

List pods stuck in `Pending` phase and show recent Events explaining why.

## Purpose

Quickly answer "why won't this pod schedule?" across a namespace or the whole cluster, without manually running `kubectl describe pod` on each one.

## Requirements

- `kubectl` on `PATH`, configured with a reachable cluster/context

## Usage

```bash
./pending-pods.sh [options]
```

| Option | Description |
|---|---|
| `-n`, `--namespace <ns>` | Only list pending pods in this namespace (default: all namespaces) |
| `-h`, `--help` | Show usage |

## Examples

See [example.md](example.md).

## Output

For each pending pod, prints its namespace/name followed by recent Events (time, type, reason, message) — typically showing reasons like `Unschedulable`, `FailedScheduling`, or `ImagePullBackOff`.

## Troubleshooting

| Symptom | Cause | Fix |
|---|---|---|
| `kubectl CLI not found on PATH` | kubectl not installed | Install kubectl |
| `Kubernetes cluster is not reachable` | No/invalid kubeconfig, wrong context | Check `kubectl config current-context` and connectivity |
| "No events found for this pod" | Events have expired (default TTL ~1h) or were never recorded | Investigate sooner after the pod is created |

## References

- [`kubectl get events`](https://kubernetes.io/docs/reference/kubectl/generated/kubectl_get/)
- [Debugging Pending Pods](https://kubernetes.io/docs/tasks/debug/debug-application/debug-pods/)
