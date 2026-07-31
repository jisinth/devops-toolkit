# service-status examples

## Report all failed services

```bash
./service-status.sh
```

```
[service-status] Failed services:
  nginx.service
  worker.service
[service-status] 2 matching failed service(s).
```
(exits 1 — two services are failed)

## Restart only failed services matching a name

```bash
./service-status.sh --name worker --fix
```

```
[service-status] Failed services:
  worker.service
[service-status] 1 matching failed service(s).
Restart 1 failed service(s)? [y/N] y
[service-status] Restarting worker.service
```

## Restart all failed services without prompting

```bash
./service-status.sh --fix -y
```
