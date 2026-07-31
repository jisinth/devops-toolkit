# memory examples

## Default report (90% threshold)

```bash
./memory.sh
```

```
[memory] Memory usage (threshold: 90%):
              total        used        free      shared  buff/cache   available
Mem:           15Gi       6.1Gi       2.3Gi       412Mi       6.8Gi       8.4Gi
Swap:         2.0Gi          0B       2.0Gi

[memory] Swap usage:
              total        used        free      shared  buff/cache   available
Swap:         2.0Gi          0B       2.0Gi
[memory] Memory usage at 41%, below the 90% threshold.
```

## Alert on high memory usage

```bash
./memory.sh --threshold 75
```

```
[memory] Memory usage (threshold: 75%):
...
[memory] ERROR: Memory usage at 88% (>= 75% threshold)
```

Exits `1`.

## Show the 10 top memory-consuming processes

```bash
./memory.sh --top 10
```

```
[memory] Memory usage (threshold: 90%):
...
[memory] Top 10 memory-consuming processes:
    PID    PPID %MEM %CPU COMMAND
   1842       1  12.4  3.1 java
   2011    1842   6.7  0.5 node
   ...
```

## No free(1) installed — fallback to /proc/meminfo

```bash
./memory.sh --threshold 90
```

```
[memory] free(1) not found; falling back to /proc/meminfo
[memory] Total: 16064 MiB  Used: 7200 MiB  Free: 2300 MiB  Available: 8400 MiB  Cached: 3100 MiB
[memory] Swap total: 2048 MiB  Swap free: 2048 MiB
[memory] Memory usage at 44%, below the 90% threshold.
```
