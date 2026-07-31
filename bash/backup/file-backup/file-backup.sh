#!/usr/bin/env bash
#
# file-backup.sh — tar+gzip a directory, optionally upload it to S3 or a
# local/mounted directory, verify archive integrity, and print a summary.
#
# Usage: ./file-backup.sh --source <dir> [options]
# Run with --help for full usage.

set -euo pipefail

SCRIPT_NAME="$(basename "$0")"

SOURCE=""
OUTPUT_DIR="./backups"
UPLOAD_S3=""
UPLOAD_DIR=""
PRE_HOOK=""
POST_HOOK=""
EXCLUDES=()

usage() {
  cat <<EOF
Usage: ${SCRIPT_NAME} --source <dir> [options]

Create a tar+gzip archive of --source, write it to --output-dir, optionally
upload it, verify the archive, and print a summary.

Options:
  --source <dir>              Directory to back up (required)
  --exclude <pattern>         Pattern to exclude (repeatable), passed to tar --exclude
  --output-dir <dir>          Directory to write the backup to (default: ./backups)
  --upload-s3 <bucket>        Upload the backup to this S3 bucket via 'aws s3 cp'
  --upload-dir <path>         Copy the backup to this local/mounted directory
  --pre-hook '<command>'      Shell command to run before the tar starts
  --post-hook '<command>'     Shell command to run after the tar completes
  -h, --help                  Show this help message and exit

Notes:
  "Stop Writes" (pausing an application or flushing writes before a backup)
  is application-specific and cannot be safely automated by a generic
  script. Use --pre-hook / --post-hook to plug in your own pause/resume
  commands.

Examples:
  ${SCRIPT_NAME} --source /var/www/app --exclude '*.log' --exclude 'tmp/*'
  ${SCRIPT_NAME} --source /data --upload-s3 my-backups-bucket
EOF
}

log()  { printf '[file-backup] %s\n' "$*"; }
err()  { printf '[file-backup] ERROR: %s\n' "$*" >&2; }

require_cmd() {
  if ! command -v "$1" >/dev/null 2>&1; then
    err "Required command not found on PATH: $1"
    exit 1
  fi
}

run_hook() {
  local label="$1" hook="$2"
  if [ -n "$hook" ]; then
    log "Running ${label}: ${hook}"
    bash -c "$hook"
  fi
}

if [ "$#" -eq 0 ]; then
  usage
  exit 0
fi

while [ "$#" -gt 0 ]; do
  case "$1" in
    --source) SOURCE="$2"; shift 2 ;;
    --exclude) EXCLUDES+=("$2"); shift 2 ;;
    --output-dir) OUTPUT_DIR="$2"; shift 2 ;;
    --upload-s3) UPLOAD_S3="$2"; shift 2 ;;
    --upload-dir) UPLOAD_DIR="$2"; shift 2 ;;
    --pre-hook) PRE_HOOK="$2"; shift 2 ;;
    --post-hook) POST_HOOK="$2"; shift 2 ;;
    -h|--help) usage; exit 0 ;;
    *)
      err "Unknown option: $1"
      usage
      exit 1
      ;;
  esac
done

if [ -z "$SOURCE" ]; then
  err "--source is required."
  usage
  exit 1
fi

if [ ! -d "$SOURCE" ]; then
  err "Source directory does not exist: ${SOURCE}"
  exit 1
fi

if [ -n "$UPLOAD_S3" ] && [ -n "$UPLOAD_DIR" ]; then
  err "Use only one of --upload-s3 or --upload-dir."
  exit 1
fi

require_cmd tar
require_cmd gzip

if [ -n "$UPLOAD_S3" ]; then
  require_cmd aws
fi

mkdir -p "$OUTPUT_DIR"

SOURCE="${SOURCE%/}"
BASE_NAME="$(basename "$SOURCE")"
PARENT_DIR="$(dirname "$SOURCE")"
TIMESTAMP="$(date +%Y%m%d-%H%M%S)"
FILENAME="${BASE_NAME}-${TIMESTAMP}.tar.gz"
OUTPUT_FILE="${OUTPUT_DIR%/}/${FILENAME}"

TAR_ARGS=(-czf "$OUTPUT_FILE")
for pattern in "${EXCLUDES[@]+"${EXCLUDES[@]}"}"; do
  TAR_ARGS+=(--exclude="$pattern")
done
TAR_ARGS+=(-C "$PARENT_DIR" "$BASE_NAME")

run_hook "pre-hook" "$PRE_HOOK"

START_TIME=$(date +%s)
log "Archiving ${SOURCE} to ${OUTPUT_FILE}"
tar "${TAR_ARGS[@]}"

run_hook "post-hook" "$POST_HOOK"

END_TIME=$(date +%s)
DURATION=$((END_TIME - START_TIME))

if [ ! -s "$OUTPUT_FILE" ]; then
  err "Backup file is empty: ${OUTPUT_FILE}"
  exit 1
fi

if ! tar -tzf "$OUTPUT_FILE" >/dev/null 2>&1; then
  err "Backup archive failed integrity check: ${OUTPUT_FILE}"
  exit 1
fi

FILE_SIZE=$(du -h "$OUTPUT_FILE" | cut -f1)

if [ -n "$UPLOAD_S3" ]; then
  log "Uploading to s3://${UPLOAD_S3}/${FILENAME}"
  aws s3 cp "$OUTPUT_FILE" "s3://${UPLOAD_S3%/}/${FILENAME}"
elif [ -n "$UPLOAD_DIR" ]; then
  log "Copying to ${UPLOAD_DIR}"
  mkdir -p "$UPLOAD_DIR"
  cp "$OUTPUT_FILE" "${UPLOAD_DIR%/}/${FILENAME}"
fi

log "Backup complete."
log "  File:     ${OUTPUT_FILE}"
log "  Size:     ${FILE_SIZE}"
log "  Duration: ${DURATION}s"
