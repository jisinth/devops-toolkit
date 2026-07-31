# yaml-validate examples

## Validate a single file

```bash
./yaml-validate.sh config.yaml
```

```
[yaml-validate] PASS - config.yaml
[yaml-validate] All inputs are valid YAML.
```

## Validate multiple files

```bash
./yaml-validate.sh deploy.yaml service.yaml ingress.yaml
```

```
[yaml-validate] PASS - deploy.yaml
[yaml-validate] PASS - service.yaml
[yaml-validate] FAIL - ingress.yaml
  while parsing a flow sequence
    in "ingress.yaml", line 1, column 4
  expected ',' or ']', but got ':'
    in "ingress.yaml", line 2, column 2
[yaml-validate] ERROR: 1 file(s) failed validation.
```

Exit code: `1` (because at least one file failed).

## Validate a document from stdin

```bash
cat config.yaml | ./yaml-validate.sh
```

```
[yaml-validate] PASS - stdin
[yaml-validate] All inputs are valid YAML.
```
