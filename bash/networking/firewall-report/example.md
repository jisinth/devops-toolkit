# firewall-report examples

## ufw host

```bash
sudo ./firewall-report.sh
```

```
[firewall-report] Detected: ufw
Status: active
Logging: on (low)
Default: deny (incoming), allow (outgoing), disabled (routed)

To                         Action      From
--                         ------      ----
22/tcp                     ALLOW IN    Anywhere
80,443/tcp                 ALLOW IN    Anywhere
```

## iptables host

```bash
sudo ./firewall-report.sh
```

```
[firewall-report] Detected: iptables
Chain INPUT (policy ACCEPT 0 packets, 0 bytes)
 pkts bytes target     prot opt in     out     source               destination
```
