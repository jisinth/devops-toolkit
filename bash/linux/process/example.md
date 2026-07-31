# process examples

## Full process list

```bash
./process.sh
```

```
[process] Process list:
  PID  PPID   %CPU   %MEM USER       COMMAND
    1     0    0.0    0.1 root       systemd
  842     1    0.2    1.4 www-data   nginx
 1103   842    0.0    0.9 www-data   nginx
```

## Filter by user

```bash
./process.sh --user www-data
```

## Find and reap zombie processes

```bash
./process.sh --zombie
```

```
[process] Zombie/defunct processes:
  PID  PPID USER     COMMAND
 5521  1103 www-data php-fpm <defunct>
[process] 1 zombie process(es) found.
```

```bash
./process.sh --zombie --fix -y
```

```
[process] 1 zombie process(es) found.
[process] Sending SIGCHLD to parent PID 1103
```
