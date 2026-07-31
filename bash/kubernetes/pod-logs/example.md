# pod-logs examples

## Export logs for all pods matching a selector

```bash
./pod-logs.sh --namespace prod --selector app=api --output-dir ./logs
```

```
[pod-logs] Finding pods in namespace 'prod' matching selector 'app=api'...
[pod-logs] Exporting logs: pod=api-6f9c8d7b4-abc12 container=api -> ./logs/prod_api-6f9c8d7b4-abc12_api.log.gz
[pod-logs] Exporting logs: pod=api-6f9c8d7b4-xyz99 container=api -> ./logs/prod_api-6f9c8d7b4-xyz99_api.log.gz
[pod-logs] Done. Exported: 2  Failed: 0
```

## Only logs from the last hour

```bash
./pod-logs.sh -n prod -l app=api -o ./logs --since 1h
```

## Fetch crash logs from a previously terminated container

```bash
./pod-logs.sh -n prod -l app=worker -o ./crash-logs --previous
```

```
[pod-logs] Finding pods in namespace 'prod' matching selector 'app=worker'...
[pod-logs] Exporting logs: pod=worker-7d9f6c5b8-lm3n2 container=worker (previous) -> ./crash-logs/prod_worker-7d9f6c5b8-lm3n2_worker_previous.log.gz
[pod-logs] Done. Exported: 1  Failed: 0
```

## No pods match the selector

```bash
./pod-logs.sh -n prod -l app=nonexistent -o ./logs
```

```
[pod-logs] Finding pods in namespace 'prod' matching selector 'app=nonexistent'...
[pod-logs] No pods found matching selector. Nothing to export.
```
