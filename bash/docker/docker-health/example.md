# docker-health examples

## Default table report

```bash
./docker-health.sh
```

```
CONTAINER                      HEALTH
web                            healthy
worker                         unhealthy
cache                          none
[docker-health] 1 unhealthy container(s): worker
```

## JSON output for scripting

```bash
./docker-health.sh --output json
```

```json
[{"container":"web","health":"healthy"},{"container":"worker","health":"unhealthy"},{"container":"cache","health":"none"}]
```

## Restart unhealthy containers without prompting

```bash
./docker-health.sh --fix -y
```

```
[docker-health] 1 unhealthy container(s): worker
[docker-health] Restarting worker
```
