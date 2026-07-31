# ingress-report

List ingresses with hosts, backend services/ports, and TLS secret presence — flagging ingresses that reference a missing TLS secret.

## Purpose

Get a fast overview of ingress routing and TLS configuration across a namespace or the whole cluster, and catch dangling TLS secret references before they cause a certificate error in production.

## Requirements

- `kubectl` on `PATH`, configured with a reachable cluster/context
- `jq`

## Usage

```bash
./ingress-report.sh [options]
```

| Option | Description |
|---|---|
| `-n`, `--namespace <ns>` | Only report ingresses in this namespace (default: all namespaces) |
| `-h`, `--help` | Show usage |

## Examples

See [example.md](example.md).

## Output

For each ingress: its host → path → backend service:port mappings, and for each referenced TLS secret, whether it actually exists in that namespace (flagged `MISSING` if not).

## Troubleshooting

| Symptom | Cause | Fix |
|---|---|---|
| `kubectl CLI not found on PATH` | kubectl not installed | Install kubectl |
| `Kubernetes cluster is not reachable` | No/invalid kubeconfig, wrong context | Check `kubectl config current-context` |
| `Failed to query ingresses` | `jq` missing, or no Ingress API available on this cluster | Install `jq`; verify `kubectl get ingress --all-namespaces` works |

## References

- [Kubernetes Ingress](https://kubernetes.io/docs/concepts/services-networking/ingress/)
- [`jq`](https://jqlang.org/)
