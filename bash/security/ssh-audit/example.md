# ssh-audit examples

## Default config

```bash
sudo ./ssh-audit.sh
```

```
[ssh-audit] Auditing /etc/ssh/sshd_config:

  FAIL  Root login disabled          PermitRootLogin      (found/assumed: yes)
  PASS  Password auth disabled       PasswordAuthentication (no)
  PASS  Empty passwords disabled     PermitEmptyPasswords (no)
  PASS  X11 forwarding disabled      X11Forwarding        (no)
  PASS  Protocol 1 not in use        Protocol             (2)

[ssh-audit] 1 check(s) failed.
```
(exits 1)

## Custom config path (e.g. testing a candidate config before deploying it)

```bash
./ssh-audit.sh --config ./sshd_config.candidate
```
