# docker-images

Read-only report of local Docker images: repository, tag, image ID, size, created date, and whether the image is dangling.

## Purpose

Get a quick, scriptable view of what images are taking up space on a host, which ones are dangling (safe prune candidates), and which ones are largest — without memorizing `docker images` format flags.

## Requirements

- Docker CLI on `PATH`
- Docker daemon running and reachable by the current user
- Bash 4+, `awk`, `sort`, `column` (all standard on Linux/macOS/WSL/Git Bash)

## Usage

```bash
./docker-images.sh [options]
```

| Option | Description |
|---|---|
| `--sort-by-size` | Sort images largest-first by size |
| `--dangling-only` | Show only dangling images (untagged, `<none>:<none>`) |
| `--output FORMAT` | Output format: `table` (default), `csv`, or `json` |
| `-h`, `--help` | Show usage |

This script is read-only: it never modifies Docker state.

## Examples

See [example.md](example.md).

## Output

- `table` (default): aligned columns — REPOSITORY, TAG, IMAGE ID, SIZE, CREATED, DANGLING.
- `csv`: header row followed by comma-separated values.
- `json`: a JSON array of objects with `repository`, `tag`, `id`, `size`, `created`, `dangling` keys.
- Prints `No images found.` and exits `0` if there are no images (or none match `--dangling-only`).
- Exits non-zero if Docker isn't installed or the daemon isn't reachable.

## Troubleshooting

| Symptom | Cause | Fix |
|---|---|---|
| `docker CLI not found on PATH` | Docker not installed / not on PATH | Install Docker, or fix `PATH` |
| `Docker daemon is not reachable` | Daemon not running, or user lacks permission | Start Docker; add user to the `docker` group or run with sufficient privileges |
| `Invalid --output value` | Typo in `--output` argument | Use one of `table`, `csv`, `json` |
| `No images found.` with `--dangling-only` | No dangling images exist | Nothing to clean — this is expected |

## References

- [`docker images`](https://docs.docker.com/engine/reference/commandline/images/)
- [`docker image prune`](https://docs.docker.com/engine/reference/commandline/image_prune/)
