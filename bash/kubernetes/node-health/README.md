# node-health

Report node status and key conditions (`Ready`, `MemoryPressure`, `DiskPressure`, `PIDPressure`, `NetworkUnavailable`), flag unhealthy nodes, and exit non-zero if any are found.

## Purpose

Gives a quick, scriptable view of cluster node health without manually reading through `kubectl describe node` output for each node. Designed to be used directly in alerting or CI: a non-zero exit means at least one node needs attention.

## Requirements

- `kubectl` CLI on `PATH`
- A reachable, correctly configured cluster (`kubectl cluster-info` must succeed)
- Bash 4+

## Usage

```bash
./node-health.sh [options]
```

| Option | Description |
|---|---|
| `--node <name>` | Only report on this node (default: all nodes) |
| `-h`, `--help` | Show usage |

Running with no arguments reports on all nodes in the cluster (this is the primary use case, not a usage prompt).

## Examples

See [example.md](example.md).

## Output

- Tab-separated table: `NODE READY MEMORY_PRESSURE DISK_PRESSURE PID_PRESSURE NETWORK_UNAVAILABLE STATUS`.
- `STATUS` is `UNHEALTHY` if `Ready` is not `True`, or if any pressure condition is `True`, or if `NetworkUnavailable` is `True`; otherwise `Healthy`.
- Summary line with counts checked/unhealthy.
- Exits non-zero if any node is unhealthy, or if `kubectl`/cluster aren't available — suitable for alerting/CI gating.

## Troubleshooting

| Symptom | Cause | Fix |
|---|---|---|
| `kubectl CLI not found on PATH` | kubectl not installed / not on PATH | Install kubectl, or fix `PATH` |
| `Kubernetes cluster is not reachable` | No/incorrect kubeconfig, VPN down, cluster unreachable | Check `kubectl config current-context` and connectivity |
| `Node '<name>' not found` | Wrong node name | Verify with `kubectl get nodes` |
| A condition shows `Unknown` | Kubelet not reporting status (node may be down/unreachable) | Investigate the node directly; `Unknown` for `Ready` is treated as unhealthy |

## References

- [Node conditions](https://kubernetes.io/docs/concepts/architecture/nodes/#condition)
- [`kubectl describe node`](https://kubernetes.io/docs/reference/generated/kubectl/kubectl-commands#describe)
