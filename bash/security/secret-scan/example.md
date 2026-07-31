# secret-scan examples

## Scan the current directory

```bash
./secret-scan.sh
```

```
./config/settings.py:14: Generic Password Assignment: password = "hunter2hunter2"
./deploy/keys.pem:1: Private Key Header: -----BEGIN RSA PRIVATE KEY-----
[secret-scan] Scanned 128 file(s) under '.'.
[secret-scan] Found 2 potential secret(s). Review each match above.
```

## Scan a specific project directory, excluding vendored code

```bash
./secret-scan.sh --path ./my-app --exclude node_modules --exclude vendor
```

```
./my-app/src/aws.js:8: AWS Access Key ID: const key = "AKIAABCDEFGHIJKLMNOP";
[secret-scan] Scanned 342 file(s) under './my-app'.
[secret-scan] Found 1 potential secret(s). Review each match above.
```

## Scan and exclude both .git and a build output directory

```bash
./secret-scan.sh --path . --exclude .git --exclude dist
```

## Clean directory, no matches

```bash
./secret-scan.sh --path ./docs
```

```
[secret-scan] Scanned 15 file(s) under './docs'.
[secret-scan] No likely secrets found.
```
