# restart-deployment examples

## Restart a deployment and wait for it with the default timeout

```bash
./restart-deployment.sh --namespace prod --deployment api
```

```
[restart-deployment] Restarting deployment/api in namespace 'prod'...
deployment.apps/api restarted
[restart-deployment] Waiting for rollout to complete (timeout: 300s)...
Waiting for deployment "api" rollout to finish: 1 out of 3 new replicas have been updated...
Waiting for deployment "api" rollout to finish: 2 out of 3 new replicas have been updated...
deployment "api" successfully rolled out
[restart-deployment] SUCCESS: deployment/api rolled out successfully.
```

## Restart with a shorter custom timeout

```bash
./restart-deployment.sh -n prod -d api --timeout 90s
```

## Rollout fails or times out

```bash
./restart-deployment.sh -n prod -d worker --timeout 60s
```

```
[restart-deployment] Restarting deployment/worker in namespace 'prod'...
deployment.apps/worker restarted
[restart-deployment] Waiting for rollout to complete (timeout: 60s)...
Waiting for deployment "worker" rollout to finish: 0 out of 2 new replicas have been updated...
error: timed out waiting for the condition
[restart-deployment] ERROR: FAILURE: rollout of deployment/worker did not complete successfully (failed or timed out).
```

(exits non-zero, suitable for alerting on the result of `$?`)
