# docker-images examples

## Default table report

```bash
./docker-images.sh
```

```
REPOSITORY               TAG        IMAGE ID      SIZE    CREATED                        DANGLING
docker.n8n.io/n8nio/n8n  latest     15091606d98f  2.53GB  2026-07-20 13:11:36 +0530 IST  false
postgres                 16-alpine  57c72fd2a128  420MB   2026-07-07 23:17:20 +0530 IST  false
alpine                   latest     28bd5fe8b56d  13MB    2026-06-16 05:31:29 +0530 IST  false
```

## Largest images first

```bash
./docker-images.sh --sort-by-size
```

```
REPOSITORY               TAG        IMAGE ID      SIZE    CREATED                        DANGLING
docker.n8n.io/n8nio/n8n  latest     15091606d98f  2.53GB  2026-07-20 13:11:36 +0530 IST  false
postgres                 16-alpine  57c72fd2a128  420MB   2026-07-07 23:17:20 +0530 IST  false
alpine                   latest     28bd5fe8b56d  13MB    2026-06-16 05:31:29 +0530 IST  false
```

## Only dangling images, as JSON

```bash
./docker-images.sh --dangling-only --output json
```

```json
[
  {"repository": "<none>", "tag": "<none>", "id": "a1b2c3d4e5f6", "size": "150MB", "created": "2026-07-15 10:02:11 +0000 UTC", "dangling": true}
]
```

## Full report as CSV, for spreadsheets or piping into other tools

```bash
./docker-images.sh --output csv
```

```
Repository,Tag,ImageID,Size,Created,Dangling
docker.n8n.io/n8nio/n8n,latest,15091606d98f,2.53GB,2026-07-20 13:11:36 +0530 IST,false
postgres,16-alpine,57c72fd2a128,420MB,2026-07-07 23:17:20 +0530 IST,false
alpine,latest,28bd5fe8b56d,13MB,2026-06-16 05:31:29 +0530 IST,false
```
