# json-pretty examples

## Pretty-print a file

```bash
./json-pretty.sh --file data.json
```

```
{
    "name": "devops-toolkit",
    "version": 1,
    "tags": [
        "bash",
        "utilities"
    ]
}
```

## Pretty-print from stdin

```bash
echo '{"a":1,"b":2}' | ./json-pretty.sh
```

```
{
    "a": 1,
    "b": 2
}
```

## Pipe a curl response through it

```bash
curl -s https://api.example.com/status | ./json-pretty.sh
```

## Invalid JSON is rejected

```bash
echo '{bad json' | ./json-pretty.sh
```

```
Expecting property name enclosed in double quotes: line 1 column 2 (char 1)
[json-pretty] ERROR: Invalid JSON.
```

Exit code: `1`.
