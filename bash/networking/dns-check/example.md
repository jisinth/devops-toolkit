# dns-check examples

## Default record types

```bash
./dns-check.sh --host example.com
```

```
[dns-check] Using 'dig' for lookups against example.com

[dns-check] == A records for example.com ==
  example.com.  86400  IN  A  93.184.216.34
  Query time: 42 ms

[dns-check] == MX records for example.com ==
  No records found.
  Query time: 38 ms
```

## Specific types against a chosen resolver

```bash
./dns-check.sh --host example.com --types A,MX --resolver 8.8.8.8
```

## TXT records only

```bash
./dns-check.sh --host example.com --types TXT
```
