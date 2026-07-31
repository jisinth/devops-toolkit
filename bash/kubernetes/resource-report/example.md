# resource-report examples

## Report for a namespace

```bash
./resource-report.sh --namespace prod
```

```
[resource-report] Collecting pod list...
NAMESPACE	POD	CONTAINER	CPU_REQUEST	CPU_LIMIT	CPU_USAGE	MEM_REQUEST	MEM_LIMIT	MEM_USAGE	FLAGS
prod	api-6f9c8d7b4-abc12	api	250m	500m	180m	256Mi	512Mi	310Mi	-
prod	api-6f9c8d7b4-xyz99	api	250m	500m	205m	256Mi	512Mi	295Mi	-
prod	batch-job-9f8d7c	worker	-	-	410m	-	-	780Mi	NO_CPU_REQUEST,NO_MEM_REQUEST,NO_CPU_LIMIT,NO_MEM_LIMIT
[resource-report] Checked 3 container(s) across the reported pods. Flagged (missing requests/limits): 1.
```

## Report across all namespaces

```bash
./resource-report.sh --all-namespaces
```

## Report a single pod

```bash
./resource-report.sh --namespace prod --pod api-6f9c8d7b4-abc12
```

```
[resource-report] Collecting pod list...
NAMESPACE	POD	CONTAINER	CPU_REQUEST	CPU_LIMIT	CPU_USAGE	MEM_REQUEST	MEM_LIMIT	MEM_USAGE	FLAGS
prod	api-6f9c8d7b4-abc12	api	250m	500m	180m	256Mi	512Mi	310Mi	-
[resource-report] Checked 1 container(s) across the reported pods. Flagged (missing requests/limits): 0.
```

## No metrics-server installed

```bash
./resource-report.sh --namespace prod
```

```
[resource-report] Collecting pod list...
[resource-report] WARNING: metrics unavailable (metrics-server not installed?). Usage columns will show N/A.
NAMESPACE	POD	CONTAINER	CPU_REQUEST	CPU_LIMIT	CPU_USAGE	MEM_REQUEST	MEM_LIMIT	MEM_USAGE	FLAGS
prod	api-6f9c8d7b4-abc12	api	250m	500m	N/A	256Mi	512Mi	N/A	-
[resource-report] Checked 1 container(s) across the reported pods. Flagged (missing requests/limits): 0.
```
