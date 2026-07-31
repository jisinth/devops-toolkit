# cpu examples

## Default check

```bash
./cpu.sh
```

```
[cpu] Sampling CPU usage over 1s...
[cpu] Overall CPU usage: 18% (threshold: 90%)
[cpu] Load average: 1m=0.42 5m=0.51 15m=0.48
[cpu] CPU usage below the 90% threshold.
```

## Lower threshold with top processes

```bash
./cpu.sh --threshold 75 --top 5
```

```
[cpu] Overall CPU usage: 82% (threshold: 75%)
[cpu] Load average: 1m=3.10 5m=2.05 15m=1.20
[cpu] Top 5 CPU-consuming processes:
  PID  PPID %CPU %MEM COMMAND
 4821     1 44.0  2.1 stress
    1     0  0.1  0.0 systemd
...
[cpu] ERROR: CPU usage at 82% (>= 75% threshold)
```
