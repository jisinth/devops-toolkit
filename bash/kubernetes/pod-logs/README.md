# pod-logs

Export logs for pods in a namespace matching a label selector to gzip-compressed files, one per pod/container.

## Purpose

Quickly grab a consistent, compressed snapshot of logs for a group of pods (e.g. all pods for a deployment) without manually running `kubectl logs` per pod/container and managing files by hand. Supports fetching crashed-container logs via `--previous`.

## Requirements

- `kubectl` CLI on `PATH`
- A reachable, correctly configured cluster (`kubectl cluster-info` must succeed)
- `gzip` on `PATH`
- Bash 4+

## Usage

```bash
./pod-logs.sh --namespace <ns> --selector <selector> --output-dir <dir> [options]
```

| Option | Description |
|---|---|
| `-n`, `--namespace <ns>` | Namespace to search (required) |
| `-l`, `--selector <selector>` | Label selector, e.g. `app=myapp` (required) |
| `-o`, `--output-dir <dir>` | Directory to write logs into, created if missing (required) |
| `--since <duration>` | Only return logs newer than this duration (e.g. `1h`, `30m`) |
| `--previous` | Fetch logs from the previously terminated container (crash logs) |
| `-h`, `--help` | Show usage |

Running with no arguments prints usage and exits `0`.

## Examples

See [example.md](example.md).

## Output

- One file per pod/container: `<output-dir>/<namespace>_<pod>_<container>.log.gz` (or `..._previous.log.gz` with `--previous`).
- Summary line with counts of exported and failed exports.
- Exits non-zero if `kubectl`/cluster aren't available, or if any pod/container log export failed.

## Troubleshooting

| Symptom | Cause | Fix |
|---|---|---|
| `kubectl CLI not found on PATH` | kubectl not installed / not on PATH | Install kubectl, or fix `PATH` |
| `Kubernetes cluster is not reachable` | No/incorrect kubeconfig, VPN down, cluster unreachable | Check `kubectl config current-context` and connectivity |
| `No pods found matching selector` | Selector or namespace typo, or no matching pods | Verify with `kubectl get pods -n <ns> -l <selector>` |
| Failed to export logs for a pod/container | Container never started, or `--previous` requested but no prior restart | Check `kubectl describe pod` for container state |

## References

- [`kubectl logs`](https://kubernetes.io/docs/reference/generated/kubectl/kubectl-commands#logs)
- [Label selectors](https://kubernetes.io/docs/concepts/overview/working-with-objects/labels/#label-selectors)
