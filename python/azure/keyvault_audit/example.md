# keyvault_audit examples

## Full audit, default 30-day window

```bash
python3 keyvault_audit.py
```

```
Name       ResourceGroup  AuthorizationModel  Location
---------  -------------  ------------------  --------
prod-kv    prod-rg        RBAC                eastus
legacy-kv  dev-rg         Access policies     westus2

Secrets/certificates expiring within 30 day(s):
Vault      Kind    Name          ExpiresOn                  DaysUntilExpiry
---------  ------  ------------  -------------------------  ---------------
legacy-kv  secret  db-password   2026-08-10 00:00:00+00:00  10
```

## Wider window, vault-level only

```bash
python3 keyvault_audit.py --days 90 --skip-expiry-check
```
