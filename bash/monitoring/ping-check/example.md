# ping-check examples

## Single host

```bash
./ping-check.sh 8.8.8.8
```

```
[ping-check] 8.8.8.8 — 0% loss, avg 12.4ms (5 packets)
[ping-check] All hosts are within the packet loss and latency thresholds.
```

## Multiple hosts with a latency threshold

```bash
./ping-check.sh --count 10 --max-loss 10 --max-latency-ms 100 example.com 1.1.1.1
```

## From cron, with logging and a webhook

```bash
*/5 * * * * /opt/devops-toolkit/bash/monitoring/ping-check/ping-check.sh --log-file /var/log/ping-check.log --webhook https://hooks.example.com/alert example.com
```

```
[ping-check] example.com — 40% loss, avg 210ms (5 packets)
[ping-check] ERROR: example.com — packet loss 40% exceeds 20% threshold
[ping-check] ERROR: One or more hosts breached the loss or latency threshold.
```
