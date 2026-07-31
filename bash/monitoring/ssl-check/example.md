# ssl-check examples

## Single domain

```bash
./ssl-check.sh example.com
```

```
[ssl-check] example.com:443 — expires Sep 21 08:40:18 2026 GMT (52 days) — subject: /CN=example.com — issuer: /C=US/O=Let's Encrypt/CN=R3
[ssl-check] All certificates are valid for at least 14 days.
```

## Multiple domains, custom port, longer warning window

```bash
./ssl-check.sh --days 30 example.com api.example.com:8443
```

## From cron, with logging and a webhook

```bash
0 6 * * * /opt/devops-toolkit/bash/monitoring/ssl-check/ssl-check.sh --days 21 --log-file /var/log/ssl-check.log --webhook https://hooks.example.com/alert example.com
```

```
[ssl-check] example.com:443 — expires Aug 05 00:00:00 2026 GMT (5 days) — subject: /CN=example.com — issuer: /C=US/O=Let's Encrypt/CN=R3
[ssl-check] ERROR: example.com:443 certificate expires in 5 days (< 21 day threshold), on Aug 05 00:00:00 2026 GMT
```
