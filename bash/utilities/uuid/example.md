# uuid examples

## Generate a single UUID

```bash
./uuid.sh
```

```
f72029fb-588b-4cbe-831e-0acb9425f022
```

## Generate several UUIDs

```bash
./uuid.sh --count 3
```

```
0786f1bf-7c08-484f-98e6-d6891429e836
7d40a890-0bcf-4c21-a819-160bacca6eb6
e35a2eee-c241-41ae-a446-22a7253c5911
```

## Uppercase, no dashes (e.g. for a compact ID)

```bash
./uuid.sh --upper --no-dashes
```

```
7FBC77ACEAFF4CC98D5E80473C8ECCB6
```
