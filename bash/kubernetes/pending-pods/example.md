# pending-pods examples

## Cluster-wide

```bash
./pending-pods.sh
```

```
[pending-pods] Finding pods in Pending phase...
[pending-pods] Found 1 pending pod(s):

=== prod/worker-7f8d9c-abcde ===
  2026-07-31T14:00:01Z  Warning  FailedScheduling  0/3 nodes are available: 3 Insufficient memory.

[pending-pods] Done. Reported on 1 pending pod(s).
```

## Scoped to one namespace

```bash
./pending-pods.sh --namespace staging
```
