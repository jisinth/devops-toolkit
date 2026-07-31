# traceroute examples

## Default

```bash
./traceroute.sh example.com
```

```
[traceroute] Tracing route to example.com (max 30 hops) via 'traceroute'...
traceroute to example.com (93.184.216.34), 30 hops max, 60 byte packets
 1  gateway (192.168.1.1)  1.123 ms
 2  10.0.0.1 (10.0.0.1)  8.451 ms
 ...
14  93.184.216.34 (93.184.216.34)  22.301 ms
```

## Shorter hop limit

```bash
./traceroute.sh --max-hops 15 8.8.8.8
```
