# restart-deployment

Trigger a rolling restart of a Kubernetes deployment and wait for it to complete, with a clear success/failure report.

## Purpose

Wraps `kubectl rollout restart` + `kubectl rollout status` into a single command that blocks until the rollout finishes and gives an unambiguous exit code, so it's safe to use in scripts, runbooks, or CI without hand-parsing rollout output.

## Requirements

- `kubectl` CLI on `PATH`
- A reachable, correctly configured cluster (`kubectl cluster-info` must succeed)
- Sufficient RBAC permissions to patch/restart the target deployment
- Bash 4+

## Usage

```bash
./restart-deployment.sh --namespace <ns> --deployment <name> [options]
```

| Option | Description |
|---|---|
| `-n`, `--namespace <ns>` | Namespace containing the deployment (required) |
| `-d`, `--deployment <name>` | Deployment name to restart (required) |
| `--timeout <duration>` | Max time to wait for rollout to complete, e.g. `120s`, `5m` (default: `300s`) |
| `-h`, `--help` | Show usage |

Running with no arguments prints usage and exits `0`.

## Examples

See [example.md](example.md).

## Output

- Confirms the deployment exists before restarting it.
- Prints progress while polling `kubectl rollout status`.
- Prints a clear `SUCCESS:` or `FAILURE:` line at the end.
- Exits `0` only on a successful rollout; exits non-zero on missing deployment, restart failure, rollout failure, or timeout.

## Troubleshooting

| Symptom | Cause | Fix |
|---|---|---|
| `kubectl CLI not found on PATH` | kubectl not installed / not on PATH | Install kubectl, or fix `PATH` |
| `Kubernetes cluster is not reachable` | No/incorrect kubeconfig, VPN down, cluster unreachable | Check `kubectl config current-context` and connectivity |
| `Deployment '<name>' not found` | Wrong name/namespace | Verify with `kubectl get deployments -n <ns>` |
| `FAILURE: rollout ... did not complete` | New pods crash-looping, insufficient resources, image pull errors, or timeout too short | Inspect `kubectl describe deployment` / `kubectl get pods -n <ns>`, increase `--timeout` if rollout is just slow |

## References

- [`kubectl rollout restart`](https://kubernetes.io/docs/reference/generated/kubectl/kubectl-commands#rollout)
- [`kubectl rollout status`](https://kubernetes.io/docs/reference/generated/kubectl/kubectl-commands#rollout)
