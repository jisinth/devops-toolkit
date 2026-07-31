# docker-logs examples

## Export logs for all running containers

```bash
./docker-logs.sh
```

```
[docker-logs] Exporting logs for web -> ./docker-logs/web-20260731-140501.log.gz
[docker-logs] Exporting logs for worker -> ./docker-logs/worker-20260731-140501.log.gz
[docker-logs] Done. Logs written to ./docker-logs
```

## Export logs for one container from the last hour

```bash
./docker-logs.sh --container web --since 1h
```

## Export the last 500 lines to a custom directory

```bash
./docker-logs.sh --tail 500 --output-dir /tmp/logs
```
