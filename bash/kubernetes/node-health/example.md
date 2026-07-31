# node-health examples

## Report health for all nodes

```bash
./node-health.sh
```

```
NODE	READY	MEMORY_PRESSURE	DISK_PRESSURE	PID_PRESSURE	NETWORK_UNAVAILABLE	STATUS
control-plane-1	True	False	False	False	False	Healthy
worker-1	True	False	False	False	False	Healthy
worker-2	True	False	False	False	False	Healthy
[node-health] Checked 3 node(s). Unhealthy: 0.
```

(exits `0`)

## A node with disk pressure

```bash
./node-health.sh
```

```
NODE	READY	MEMORY_PRESSURE	DISK_PRESSURE	PID_PRESSURE	NETWORK_UNAVAILABLE	STATUS
control-plane-1	True	False	False	False	False	Healthy
worker-1	True	False	True	False	False	UNHEALTHY
worker-2	True	False	False	False	False	Healthy
[node-health] Checked 3 node(s). Unhealthy: 1.
```

(exits `1`, useful as an alert trigger)

## Check a single node

```bash
./node-health.sh --node worker-1
```

```
NODE	READY	MEMORY_PRESSURE	DISK_PRESSURE	PID_PRESSURE	NETWORK_UNAVAILABLE	STATUS
worker-1	True	False	False	False	False	Healthy
[node-health] Checked 1 node(s). Unhealthy: 0.
```

## Use in a CI/alerting gate

```bash
./node-health.sh || echo "ALERT: one or more nodes are unhealthy"
```
