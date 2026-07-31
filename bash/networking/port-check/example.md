# port-check examples

## A few well-known ports

```bash
./port-check.sh --host example.com --ports 22,80,443
```

```
[port-check] Checking example.com (timeout: 3s per port)

  22     filtered   timed out after 3s
  80     open       connect time: 41 ms
  443    open       connect time: 38 ms
```

## A port range on localhost

```bash
./port-check.sh --host 127.0.0.1 --ports 20-25
```

## Single port with a longer timeout

```bash
./port-check.sh --host example.com --ports 443 --timeout 5
```
