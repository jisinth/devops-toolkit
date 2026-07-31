# ingress-report examples

## Cluster-wide

```bash
./ingress-report.sh
```

```
[ingress-report] Found 1 ingress(es):

=== prod/web-ingress ===
  host: app.example.com  ->  /api => api-svc:8080
  host: app.example.com  ->  / => web-svc:80
  TLS secret 'app-example-com-tls': present

[ingress-report] Done. Reported on 1 ingress(es).
```

## Scoped to one namespace, with a missing TLS secret

```bash
./ingress-report.sh --namespace staging
```

```
=== staging/staging-ingress ===
  host: staging.example.com  ->  / => web-svc:80
  TLS secret 'staging-example-com-tls': MISSING
```
