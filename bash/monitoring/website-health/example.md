# website-health examples

## Single URL

```bash
./website-health.sh https://example.com
```

```
[website-health] https://example.com — status 200, 0.183s
[website-health] All URLs passed the health check.
```

## Multiple URLs with a tight timeout

```bash
./website-health.sh --timeout 3 https://example.com https://api.example.com/health
```

## URL list file, from cron with logging and a webhook

```
# /etc/website-health/urls.txt
https://example.com
https://api.example.com/health
```

```bash
*/5 * * * * /opt/devops-toolkit/bash/monitoring/website-health/website-health.sh --url-file /etc/website-health/urls.txt --log-file /var/log/website-health.log --webhook https://hooks.example.com/alert
```

```
[website-health] https://api.example.com/health — status 503, 0.412s
[website-health] ERROR: https://api.example.com/health — non-2xx status: 503
```
