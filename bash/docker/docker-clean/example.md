# docker-clean examples

## Preview everything that would be cleaned, without changing anything

```bash
./docker-clean.sh --all --dry-run
```

```
[docker-clean] Docker disk usage before cleanup:
TYPE            TOTAL     ACTIVE    SIZE      RECLAIMABLE
Images          12        3         4.2GB     3.1GB (73%)
Containers      5         1         120MB     95MB (79%)
Local Volumes   4         2         800MB     300MB (37%)
Build Cache     20        0         1.1GB     1.1GB (100%)
[docker-clean] DRY-RUN: would run: docker container prune -f
[docker-clean] DRY-RUN: would run: docker image prune -a -f
[docker-clean] DRY-RUN: would run: docker volume prune -f
[docker-clean] DRY-RUN: would run: docker network prune -f
[docker-clean] DRY-RUN: would run: docker builder prune -f
[docker-clean] Dry run complete. No changes were made.
```

## Clean only images and volumes, skipping the confirmation prompt

```bash
./docker-clean.sh --images --volumes -y
```

## Clean everything, with confirmation for volume deletion

```bash
./docker-clean.sh --all
```

```
[docker-clean] Docker disk usage before cleanup:
...
This will remove unused volumes, which can delete data. Continue? [y/N] y
[docker-clean] Removing stopped containers
...
[docker-clean] Docker disk usage after cleanup:
...
```

## Just remove stopped containers

```bash
./docker-clean.sh --containers -y
```
