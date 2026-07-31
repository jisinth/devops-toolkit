# docker-volumes examples

## Default table report

```bash
./docker-volumes.sh
```

```
NAME                   DRIVER  MOUNTPOINT                                           ATTACHED
jinora_n8n_data        local   /var/lib/docker/volumes/jinora_n8n_data/_data        true
jinora_postgres_data   local   /var/lib/docker/volumes/jinora_postgres_data/_data   true
old_project_data       local   /var/lib/docker/volumes/old_project_data/_data       false
```

## Only volumes not attached to any container

```bash
./docker-volumes.sh --unattached-only
```

```
NAME               DRIVER  MOUNTPOINT                                       ATTACHED
old_project_data   local   /var/lib/docker/volumes/old_project_data/_data   false
```

## Full report as JSON

```bash
./docker-volumes.sh --output json
```

```json
[
  {"name": "jinora_n8n_data", "driver": "local", "mountpoint": "/var/lib/docker/volumes/jinora_n8n_data/_data", "attached": true},
  {"name": "old_project_data", "driver": "local", "mountpoint": "/var/lib/docker/volumes/old_project_data/_data", "attached": false}
]
```

## Full report as CSV

```bash
./docker-volumes.sh --output csv
```

```
Name,Driver,Mountpoint,Attached
jinora_n8n_data,local,/var/lib/docker/volumes/jinora_n8n_data/_data,true
old_project_data,local,/var/lib/docker/volumes/old_project_data/_data,false
```
