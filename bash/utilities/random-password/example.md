# random-password examples

## Generate a single password (default: 16 chars, alnum-symbols)

```bash
./random-password.sh
```

```
Bp8frAiGKpKnIwRW
```

## Generate several longer passwords

```bash
./random-password.sh --count 3 --length 24
```

```
B!w}prrN(Lr&ZX?Hb?Xih0>y
y27dKcke5FqA3]7+u(-NJ$1q
fsAyZ}hd^14aY<rWD2#MRDEU
```

## Alphanumeric only, no visually-ambiguous characters

```bash
./random-password.sh --charset alnum --no-ambiguous --length 32
```

```
Ahj7eP7UiqxBeqNF2KjUdZaGtst6fpCZ
```
