# namespace-cleanup examples

## Report stuck resources in one namespace (read-only)

```bash
./namespace-cleanup.sh --namespace staging
```

```
[namespace-cleanup] Scanning for pods stuck in Terminating state...
[namespace-cleanup] Found 2 pod(s) stuck Terminating:
NAMESPACE	NAME	DELETION_TIMESTAMP
staging	worker-7d9f6c5b8-lm3n2	2026-07-31T10:15:02Z
staging	worker-7d9f6c5b8-qq1a9	2026-07-31T10:15:02Z
[namespace-cleanup] Report complete (dry-run only; pass --fix -y to attempt repairs). Stuck resources found: 2.
```

## Report across all namespaces, including stuck namespaces themselves

```bash
./namespace-cleanup.sh --all-namespaces
```

```
[namespace-cleanup] Scanning for pods stuck in Terminating state...
[namespace-cleanup] No pods stuck Terminating.
[namespace-cleanup] Scanning for namespaces stuck in Terminating phase...
[namespace-cleanup] Found 1 namespace(s) stuck Terminating:
NAMESPACE	PHASE
old-demo	Terminating
[namespace-cleanup] Report complete (dry-run only; pass --fix -y to attempt repairs). Stuck resources found: 1.
```

## Preview what --fix would do, without acting

```bash
./namespace-cleanup.sh --namespace staging --fix
```

```
[namespace-cleanup] Scanning for pods stuck in Terminating state...
[namespace-cleanup] Found 2 pod(s) stuck Terminating:
NAMESPACE	NAME	DELETION_TIMESTAMP
staging	worker-7d9f6c5b8-lm3n2	2026-07-31T10:15:02Z
staging	worker-7d9f6c5b8-qq1a9	2026-07-31T10:15:02Z
[namespace-cleanup] This will strip finalizers from 2 stuck resource(s), which can orphan cloud resources. Continue? [y/N] n
[namespace-cleanup] --fix requested but not confirmed (use -y/--yes). No changes made.
```

## Actually fix stuck pods, skipping the prompt

```bash
./namespace-cleanup.sh --namespace staging --fix -y
```

```
[namespace-cleanup] Scanning for pods stuck in Terminating state...
[namespace-cleanup] Found 2 pod(s) stuck Terminating:
NAMESPACE	NAME	DELETION_TIMESTAMP
staging	worker-7d9f6c5b8-lm3n2	2026-07-31T10:15:02Z
staging	worker-7d9f6c5b8-qq1a9	2026-07-31T10:15:02Z
[namespace-cleanup] Stripping finalizers from pod staging/worker-7d9f6c5b8-lm3n2...
[namespace-cleanup] Stripping finalizers from pod staging/worker-7d9f6c5b8-qq1a9...
[namespace-cleanup] Fix complete. Fixed: 2  Failed: 0
```
