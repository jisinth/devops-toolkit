# cpu-alert examples

## Default check

```bash
./cpu-alert.sh
```

```
[cpu-alert] CPU usage: 23.4% (threshold: 90%)
[cpu-alert] CPU usage is below the 90% threshold.
```

## Lower threshold, logged to a file, run from cron

```bash
*/5 * * * * /opt/devops-toolkit/bash/monitoring/cpu-alert/cpu-alert.sh --threshold 80 --log-file /var/log/cpu-alert.log
```

## With a webhook alert

```bash
./cpu-alert.sh --threshold 75 --webhook https://hooks.example.com/alert
```

```
[cpu-alert] CPU usage: 91.2% (threshold: 75%)
[cpu-alert] ERROR: CPU usage 91.2% is at or above threshold 75%
```
(exits 1, and a JSON payload is POSTed to the webhook)
