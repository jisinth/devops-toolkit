# latency examples

## Single host

```bash
./latency.sh 8.8.8.8
```

```
[latency] 8.8.8.8 — loss: 0%  min/avg/max/stddev: 11.2/12.8/15.1/1.3 ms
```

## Multiple hosts, more samples

```bash
./latency.sh --count 20 example.com 1.1.1.1
```

## CSV output for a fleet of hosts

```bash
./latency.sh --hosts example.com,1.1.1.1,8.8.8.8 --output csv > latency-report.csv
```

```
host,loss_pct,min_ms,avg_ms,max_ms,stddev_ms
example.com,0,9.1,10.4,12.0,0.8
1.1.1.1,0,4.2,5.1,6.8,0.6
8.8.8.8,0,11.2,12.8,15.1,1.3
```
