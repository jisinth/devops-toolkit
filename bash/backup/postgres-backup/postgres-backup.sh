#!/usr/bin/env bash
#
# postgres-backup.sh — pg_dump a database, gzip-compress it, optionally
# upload to S3 or a local/mounted directory, verify the result, and print a
# summary.
#
# Usage: ./postgres-backup.sh --database <name> [options]
# Run with --help for full usage.

set -euo pipefail

SCRIPT_NAME="$(basename "$0")"

HOST="127.0.0.1"
PORT=""
USER=""
PASSWORD_ENV=""
DATABASE=""
OUTPUT_DIR="./backups"
UPLOAD_S3=""
UPLOAD_DIR=""
PRE_HOOK=""
POST_HOOK=""

usage() {
  cat <<EOF
Usage: ${SCRIPT_NAME} --database <name> [options]

Dump a PostgreSQL database with pg_dump, gzip-compress it to --output-dir,
optionally upload it, verify the archive, and print a summary.

Options:
  --host <host>               Database host (default: 127.0.0.1)
  --port <port>                Database port (default: pg_dump's default, 5432)
  --user <user>                 Database user
  --password-env <VAR>        Name of an environment variable holding the password
                               (never pass the password on the command line)
  --database <name>           Database to dump (required)
  --output-dir <dir>           Directory to write the backup to (default: ./backups)
  --upload-s3 <bucket>         Upload the backup to this S3 bucket via 'aws s3 cp'
  --upload-dir <path>           Copy the backup to this local/mounted directory
  --pre-hook '<command>'       Shell command to run before the dump starts
  --post-hook '<command>'      Shell command to run after the dump completes
  -h, --help                   Show this help message and exit

Notes:
  "Stop Writes" (pausing application writes before a backup) is
  application-specific and cannot be safely automated by a generic script.
  Use --pre-hook / --post-hook to plug in your own pause/resume commands.

Examples:
  ${SCRIPT_NAME} --database app --user backup --password-env PG_PWD
  ${SCRIPT_NAME} --host db.internal --database app --user backup \\
      --password-env PG_PWD --upload-s3 my-backups-bucket
EOF
}

log()  { printf '[postgres-backup] %s\n' "$*"; }
err()  { printf '[postgres-backup] ERROR: %s\n' "$*" >&2; }

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
    --host) HOST="$2"; shift 2 ;;
    --port) PORT="$2"; shift 2 ;;
    --user) USER="$2"; shift 2 ;;
    --password-env) PASSWORD_ENV="$2"; shift 2 ;;
    --database) DATABASE="$2"; shift 2 ;;
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

if [ -z "$DATABASE" ]; then
  err "--database is required."
  usage
  exit 1
fi

if [ -n "$UPLOAD_S3" ] && [ -n "$UPLOAD_DIR" ]; then
  err "Use only one of --upload-s3 or --upload-dir."
  exit 1
fi

require_cmd pg_dump
require_cmd gzip

if [ -n "$UPLOAD_S3" ]; then
  require_cmd aws
fi

PASSWORD=""
if [ -n "$PASSWORD_ENV" ]; then
  if [ -z "${!PASSWORD_ENV:-}" ]; then
    err "Environment variable '${PASSWORD_ENV}' (from --password-env) is not set or empty."
    exit 1
  fi
  PASSWORD="${!PASSWORD_ENV}"
fi

mkdir -p "$OUTPUT_DIR"

TIMESTAMP="$(date +%Y%m%d-%H%M%S)"
FILENAME="${DATABASE}-${TIMESTAMP}.sql.gz"
OUTPUT_FILE="${OUTPUT_DIR%/}/${FILENAME}"

PG_DUMP_ARGS=(--host="$HOST")
[ -n "$PORT" ] && PG_DUMP_ARGS+=(--port="$PORT")
[ -n "$USER" ] && PG_DUMP_ARGS+=(--username="$USER")
PG_DUMP_ARGS+=("$DATABASE")

run_hook "pre-hook" "$PRE_HOOK"

START_TIME=$(date +%s)
log "Dumping database '${DATABASE}' from ${HOST} to ${OUTPUT_FILE}"

if [ -n "$PASSWORD" ]; then
  PGPASSWORD="$PASSWORD" pg_dump "${PG_DUMP_ARGS[@]}" | gzip > "$OUTPUT_FILE"
else
  pg_dump "${PG_DUMP_ARGS[@]}" | gzip > "$OUTPUT_FILE"
fi

run_hook "post-hook" "$POST_HOOK"

END_TIME=$(date +%s)
DURATION=$((END_TIME - START_TIME))

if [ ! -s "$OUTPUT_FILE" ]; then
  err "Backup file is empty: ${OUTPUT_FILE}"
  exit 1
fi

if ! gzip -t "$OUTPUT_FILE" 2>/dev/null; then
  err "Backup file failed gzip integrity check: ${OUTPUT_FILE}"
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
