# base64 examples

## Encode an inline string

```bash
./base64.sh --encode "hello world"
```

```
aGVsbG8gd29ybGQ=
```

## Decode an inline string

```bash
./base64.sh --decode "aGVsbG8gd29ybGQ="
```

```
hello world
```

## Encode a file

```bash
./base64.sh --encode -i secret.txt
```

```
c2VjcmV0LWNyZWRlbnRpYWwtdmFsdWU=
```

## Encode piped stdin

```bash
echo -n "hello" | ./base64.sh --encode
```

```
aGVsbG8=
```
