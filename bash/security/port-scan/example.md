# port-scan examples

Only scan hosts you own or are explicitly authorized to test.

## Scan the local machine's well-known ports (default range)

```bash
./port-scan.sh --host 127.0.0.1
```

```
[port-scan] AUTHORIZED USE ONLY: only scan hosts you own or are explicitly authorized to test.
[port-scan] Scanning 127.0.0.1, ports 1-1024 (timeout 1s/port)...
[port-scan] Port 22: OPEN
[port-scan] Port 80: OPEN
[port-scan] Scan complete: 2 open of 1024 scanned.
```

## Scan a narrow, fast range

```bash
./port-scan.sh --host 127.0.0.1 --range 1-100 --timeout 1
```

```
[port-scan] AUTHORIZED USE ONLY: only scan hosts you own or are explicitly authorized to test.
[port-scan] Scanning 127.0.0.1, ports 1-100 (timeout 1s/port)...
[port-scan] Scan complete: 0 open of 100 scanned.
[port-scan] No open ports found in range 1-100.
```

## Scan a high port range on an internal host you're authorized to test

```bash
./port-scan.sh --host internal-app.example.internal --range 8000-8100 --timeout 2
```

## Check a single common port by giving a range of one

```bash
./port-scan.sh --host 127.0.0.1 --range 443-443
```
