# memory-alert examples

## Default check

```bash
./memory-alert.sh
```

```
[memory-alert] Memory usage: 41.7% (threshold: 90%)
[memory-alert] Memory usage is below the 90% threshold.
```

## Lower threshold, run from cron

```bash
*/5 * * * * /opt/devops-toolkit/bash/monitoring/memory-alert/memory-alert.sh --threshold 85 --log-file /var/log/memory-alert.log
```

## With a webhook alert

```bash
./memory-alert.sh --threshold 80 --webhook https://hooks.example.com/alert
```

```
[memory-alert] Memory usage: 88.3% (threshold: 80%)
[memory-alert] ERROR: Memory usage 88.3% is at or above threshold 80%
```
(exits 1, and a JSON payload is POSTed to the webhook)
