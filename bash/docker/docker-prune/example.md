# docker-prune examples

## Preview everything that would be removed, without changing anything

```bash
./docker-prune.sh --dry-run
```

```
[docker-prune] Docker disk usage before prune:
TYPE            TOTAL     ACTIVE    SIZE      RECLAIMABLE
Images          12        3         4.2GB     3.1GB (73%)
Containers      5         1         120MB     95MB (79%)
Local Volumes   4         2         800MB     300MB (37%)
Build Cache     20        0         1.1GB     1.1GB (100%)
[docker-prune] DRY-RUN: would run: docker system prune -a --volumes --force
[docker-prune] Dry run complete. No changes were made.
```

## Prune everything, skipping the confirmation prompt

```bash
./docker-prune.sh -y
```

```
[docker-prune] Docker disk usage before prune:
...
[docker-prune] Removing all unused containers, images, volumes, and networks
Deleted Containers: ...
Deleted Networks: ...
Deleted Images: ...
Deleted Volumes: ...
Total reclaimed space: 4.5GB
[docker-prune] Docker disk usage after prune:
...
```

## Prune interactively (confirmation required)

```bash
./docker-prune.sh
```

```
[docker-prune] Docker disk usage before prune:
...
This will remove ALL unused containers, images, volumes, and networks. Continue? [y/N] y
[docker-prune] Removing all unused containers, images, volumes, and networks
...
```

## Decline the confirmation

```bash
./docker-prune.sh
```

```
[docker-prune] Docker disk usage before prune:
...
This will remove ALL unused containers, images, volumes, and networks. Continue? [y/N] n
[docker-prune] Aborted (not confirmed). No changes were made.
```
