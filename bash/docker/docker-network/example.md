# docker-network examples

## Default report

```bash
./docker-network.sh
```

```
NAME                 DRIVER          SCOPE      CONTAINERS UNUSED
bridge               bridge          local      2          no
my-old-network        bridge          local      0          yes
[docker-network] 1 unused network(s) found.
```

## Only show unused networks

```bash
./docker-network.sh --unused-only
```

```
NAME                 DRIVER          SCOPE      CONTAINERS UNUSED
my-old-network        bridge          local      0          yes
[docker-network] 1 unused network(s) found.
```
