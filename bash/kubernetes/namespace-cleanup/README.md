# namespace-cleanup

Find resources stuck in `Terminating` state in a namespace (or across all namespaces) and report them. Optionally attempt to fix stuck terminations by stripping finalizers.

## Purpose

Pods and namespaces sometimes get stuck `Terminating` indefinitely because a finalizer never completes (e.g. a controller that owned it is gone). This script reports what's stuck, and — only when explicitly confirmed — can strip finalizers to let Kubernetes garbage-collect them.

## Requirements

- `kubectl` CLI on `PATH`
- A reachable, correctly configured cluster (`kubectl cluster-info` must succeed)
- Sufficient RBAC permissions to `get`/`patch` pods and namespaces for `--fix`
- `jq` on `PATH` if you need `--fix` to also clear a stuck namespace's finalizers (pod fixes don't need `jq`)
- Bash 4+

## Usage

```bash
./namespace-cleanup.sh (--namespace <ns> | --all-namespaces) [options]
```

| Option | Description |
|---|---|
| `-n`, `--namespace <ns>` | Namespace to inspect (required unless `--all-namespaces`) |
| `--all-namespaces` | Inspect all namespaces (required unless `--namespace`) |
| `--fix` | Attempt to fix stuck terminations by stripping finalizers (still dry-run without `-y`) |
| `-y`, `--yes` | Confirm the destructive action requested by `--fix` |
| `-h`, `--help` | Show usage |

Running with no arguments prints usage and exits `0`.

## Examples

See [example.md](example.md).

## Output

- Lists stuck pods as `NAMESPACE\tNAME\tDELETION_TIMESTAMP`.
- With `--all-namespaces`, also lists namespaces whose `status.phase` is `Terminating`; with a single `--namespace`, checks whether that namespace itself is stuck.
- Default mode (no `--fix`) is always a read-only report; it never modifies cluster state.
- `--fix` without `-y` prints what would be fixed but still makes no changes.
- `--fix -y` prompts once more (unless `-y` is given, which skips the prompt) before stripping finalizers, then reports fixed/failed counts and exits non-zero if any fix failed.

## Troubleshooting

| Symptom | Cause | Fix |
|---|---|---|
| `kubectl CLI not found on PATH` | kubectl not installed / not on PATH | Install kubectl, or fix `PATH` |
| `Kubernetes cluster is not reachable` | No/incorrect kubeconfig, VPN down, cluster unreachable | Check `kubectl config current-context` and connectivity |
| `--namespace and --all-namespaces are mutually exclusive` | Both flags passed | Use only one |
| `jq not found on PATH; cannot safely strip finalizers from namespace` | `--fix -y` hit a stuck namespace but `jq` is missing | Install `jq`, or clear the namespace's finalizers manually via the `/finalize` subresource |
| Resource still stuck after `--fix -y` | Finalizer was recreated by a controller, or fix failed | Re-run the report; check `kubectl describe` for the resource's remaining finalizers/owner |

## References

- [Kubernetes finalizers](https://kubernetes.io/docs/concepts/overview/working-with-objects/finalizers/)
- [Force-deleting stuck resources](https://kubernetes.io/docs/tasks/administer-cluster/namespaces/#deleting-a-namespace)
