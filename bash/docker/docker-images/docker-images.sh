#!/usr/bin/env bash
#
# docker-images.sh — read-only report of Docker images: repository, tag,
# image ID, size, created date, and whether the image is dangling.
#
# Usage: ./docker-images.sh [options]
# Run with --help for full usage.

set -euo pipefail

SCRIPT_NAME="$(basename "$0")"

SORT_BY_SIZE=false
DANGLING_ONLY=false
OUTPUT_FORMAT="table"

usage() {
  cat <<EOF
Usage: ${SCRIPT_NAME} [options]

Read-only report of local Docker images: repository, tag, image ID, size,
created date, and a dangling flag. Makes no changes to Docker state.

Options:
  --sort-by-size     Sort images largest-first by size
  --dangling-only    Show only dangling images (untagged, <none>:<none>)
  --output FORMAT    Output format: table (default), csv, or json
  -h, --help         Show this help message and exit

Examples:
  ${SCRIPT_NAME}
  ${SCRIPT_NAME} --sort-by-size
  ${SCRIPT_NAME} --dangling-only --output json
  ${SCRIPT_NAME} --output csv
EOF
}

log()  { printf '[docker-images] %s\n' "$*"; }
err()  { printf '[docker-images] ERROR: %s\n' "$*" >&2; }

require_docker() {
  if ! command -v docker >/dev/null 2>&1; then
    err "docker CLI not found on PATH."
    exit 1
  fi
  if ! docker info >/dev/null 2>&1; then
    err "Docker daemon is not reachable (is it running? do you have permission?)."
    exit 1
  fi
}

# Convert a docker-style human size (e.g. "1.23GB", "512kB", "0B") to bytes.
size_to_bytes() {
  local s="$1" num unit
  num=$(printf '%s' "$s" | grep -oE '^[0-9.]+')
  unit=$(printf '%s' "$s" | grep -oE '[A-Za-z]+$')
  [ -z "$num" ] && num=0
  case "$unit" in
    B)  awk -v n="$num" 'BEGIN{printf "%.0f", n}' ;;
    kB) awk -v n="$num" 'BEGIN{printf "%.0f", n*1000}' ;;
    MB) awk -v n="$num" 'BEGIN{printf "%.0f", n*1000000}' ;;
    GB) awk -v n="$num" 'BEGIN{printf "%.0f", n*1000000000}' ;;
    TB) awk -v n="$num" 'BEGIN{printf "%.0f", n*1000000000000}' ;;
    *)  echo 0 ;;
  esac
}

json_escape() {
  printf '%s' "$1" | sed 's/\\/\\\\/g; s/"/\\"/g'
}

while [ "$#" -gt 0 ]; do
  case "$1" in
    --sort-by-size) SORT_BY_SIZE=true ;;
    --dangling-only) DANGLING_ONLY=true ;;
    --output)
      [ "$#" -ge 2 ] || { err "--output requires an argument (table|csv|json)"; exit 1; }
      OUTPUT_FORMAT="$2"
      shift
      ;;
    --output=*) OUTPUT_FORMAT="${1#*=}" ;;
    -h|--help) usage; exit 0 ;;
    *)
      err "Unknown option: $1"
      usage
      exit 1
      ;;
  esac
  shift
done

case "$OUTPUT_FORMAT" in
  table|csv|json) ;;
  *)
    err "Invalid --output value: ${OUTPUT_FORMAT} (expected table, csv, or json)"
    exit 1
    ;;
esac

require_docker

FILTER_ARGS=()
if [ "$DANGLING_ONLY" = true ]; then
  FILTER_ARGS=(-f dangling=true)
fi

RAW="$(docker images "${FILTER_ARGS[@]}" --format '{{.Repository}}	{{.Tag}}	{{.ID}}	{{.Size}}	{{.CreatedAt}}')"

if [ -z "$RAW" ]; then
  log "No images found."
  exit 0
fi

# Build rows: bytes<TAB>repo<TAB>tag<TAB>id<TAB>size<TAB>created<TAB>dangling
rows=()
while IFS=$'\t' read -r repo tag id size created; do
  [ -z "$repo" ] && continue
  dangling="false"
  if [ "$repo" = "<none>" ] && [ "$tag" = "<none>" ]; then
    dangling="true"
  fi
  bytes="$(size_to_bytes "$size")"
  rows+=("${bytes}	${repo}	${tag}	${id}	${size}	${created}	${dangling}")
done <<< "$RAW"

if [ "$SORT_BY_SIZE" = true ]; then
  mapfile -t rows < <(printf '%s\n' "${rows[@]}" | sort -t $'\t' -k1,1 -rn)
fi

case "$OUTPUT_FORMAT" in
  table)
    {
      printf 'REPOSITORY\tTAG\tIMAGE ID\tSIZE\tCREATED\tDANGLING\n'
      for row in "${rows[@]}"; do
        IFS=$'\t' read -r _ repo tag id size created dangling <<< "$row"
        printf '%s\t%s\t%s\t%s\t%s\t%s\n' "$repo" "$tag" "$id" "$size" "$created" "$dangling"
      done
    } | column -t -s $'\t'
    ;;
  csv)
    printf 'Repository,Tag,ImageID,Size,Created,Dangling\n'
    for row in "${rows[@]}"; do
      IFS=$'\t' read -r _ repo tag id size created dangling <<< "$row"
      printf '%s,%s,%s,%s,%s,%s\n' "$repo" "$tag" "$id" "$size" "$created" "$dangling"
    done
    ;;
  json)
    printf '[\n'
    total="${#rows[@]}"
    i=0
    for row in "${rows[@]}"; do
      i=$((i + 1))
      IFS=$'\t' read -r _ repo tag id size created dangling <<< "$row"
      printf '  {"repository": "%s", "tag": "%s", "id": "%s", "size": "%s", "created": "%s", "dangling": %s}' \
        "$(json_escape "$repo")" "$(json_escape "$tag")" "$(json_escape "$id")" \
        "$(json_escape "$size")" "$(json_escape "$created")" "$dangling"
      if [ "$i" -lt "$total" ]; then printf ','; fi
      printf '\n'
    done
    printf ']\n'
    ;;
esac
