#!/usr/bin/env bash
#
# restore.sh — restore from a backup produced by mysql-backup.sh,
# postgres-backup.sh, or file-backup.sh. Detects backup type from the file
# extension: .tar.gz -> file restore, .sql.gz -> database restore (requires
# an explicit --type, since both mysql-backup.sh and postgres-backup.sh
# produce .sql.gz).
#
# This is DESTRUCTIVE to the target (it overwrites files or database
# contents). It requires -y/--yes or an interactive confirmation, and
# supports --dry-run to preview without making changes.
#
# Usage: ./restore.sh --file <backup> [options]
# Run with --help for full usage.

set -euo pipefail

SCRIPT_NAME="$(basename "$0")"

FILE=""
TARGET_DIR=""
TYPE=""
HOST="127.0.0.1"
PORT=""
USER=""
PASSWORD_ENV=""
DATABASE=""
ASSUME_YES=false
DRY_RUN=false

usage() {
  cat <<EOF
Usage: ${SCRIPT_NAME} --file <backup> [options]

Restore from a backup file produced by mysql-backup.sh, postgres-backup.sh,
or file-backup.sh. The backup type is detected from the file extension:

  *.tar.gz   -> file restore, extracted into --target-dir
  *.sql.gz   -> database restore; requires --type mysql|postgres, since
                both mysql-backup.sh and postgres-backup.sh produce .sql.gz

This OVERWRITES data at the target (extracted files or database contents).
It requires -y/--yes or an interactive confirmation before making changes.
Use --dry-run to preview what would happen without touching anything.

Options:
  --file <path>               Backup file to restore from (required)
  --target-dir <dir>           Directory to extract a .tar.gz backup into
  --type mysql|postgres        Database engine for a .sql.gz backup (required for .sql.gz)
  --host <host>                 Database host (default: 127.0.0.1)
  --port <port>                  Database port
  --user <user>                  Database user
  --password-env <VAR>          Name of an environment variable holding the password
                                 (never pass the password on the command line)
  --database <name>            Database to restore into (required for .sql.gz)
  -y, --yes                     Do not prompt for confirmation
  --dry-run                     Show what would happen without making changes
  -h, --help                    Show this help message and exit

Examples:
  ${SCRIPT_NAME} --file backups/app-20260731.tar.gz --target-dir /var/www/app --dry-run
  ${SCRIPT_NAME} --file backups/app-20260731.sql.gz --type mysql \\
      --database app --user root --password-env MYSQL_PWD_VALUE -y
EOF
}

log()  { printf '[restore] %s\n' "$*"; }
err()  { printf '[restore] ERROR: %s\n' "$*" >&2; }

require_cmd() {
  if ! command -v "$1" >/dev/null 2>&1; then
    err "Required command not found on PATH: $1"
    exit 1
  fi
}

confirm() {
  local prompt="$1"
  if [ "$ASSUME_YES" = true ]; then
    return 0
  fi
  read -r -p "${prompt} [y/N] " reply
  case "$reply" in
    [yY][eE][sS]|[yY]) return 0 ;;
    *) return 1 ;;
  esac
}

if [ "$#" -eq 0 ]; then
  usage
  exit 0
fi

while [ "$#" -gt 0 ]; do
  case "$1" in
    --file) FILE="$2"; shift 2 ;;
    --target-dir) TARGET_DIR="$2"; shift 2 ;;
    --type) TYPE="$2"; shift 2 ;;
    --host) HOST="$2"; shift 2 ;;
    --port) PORT="$2"; shift 2 ;;
    --user) USER="$2"; shift 2 ;;
    --password-env) PASSWORD_ENV="$2"; shift 2 ;;
    --database) DATABASE="$2"; shift 2 ;;
    -y|--yes) ASSUME_YES=true; shift ;;
    --dry-run) DRY_RUN=true; shift ;;
    -h|--help) usage; exit 0 ;;
    *)
      err "Unknown option: $1"
      usage
      exit 1
      ;;
  esac
done

if [ -z "$FILE" ]; then
  err "--file is required."
  usage
  exit 1
fi

if [ ! -f "$FILE" ]; then
  err "Backup file not found: ${FILE}"
  exit 1
fi

case "$FILE" in
  *.tar.gz) KIND="file" ;;
  *.sql.gz) KIND="database" ;;
  *)
    err "Cannot determine backup type from filename: ${FILE} (expected .tar.gz or .sql.gz)"
    exit 1
    ;;
esac

require_cmd gzip

if ! gzip -t "$FILE" 2>/dev/null; then
  err "Backup file failed gzip integrity check: ${FILE}"
  exit 1
fi

START_TIME=$(date +%s)

if [ "$KIND" = "file" ]; then
  require_cmd tar

  if [ -z "$TARGET_DIR" ]; then
    err "--target-dir is required to restore a .tar.gz backup."
    exit 1
  fi

  if ! tar -tzf "$FILE" >/dev/null 2>&1; then
    err "Archive failed integrity check: ${FILE}"
    exit 1
  fi

  log "Backup type: file archive"
  log "  Source: ${FILE}"
  log "  Target: ${TARGET_DIR}"

  if [ "$DRY_RUN" = true ]; then
    log "DRY-RUN: would extract ${FILE} into ${TARGET_DIR}"
    log "DRY-RUN: contents:"
    tar -tzf "$FILE" | sed 's/^/[restore] DRY-RUN:   /'
    log "Dry run complete. No changes were made."
    exit 0
  fi

  if ! confirm "This will extract '${FILE}' into '${TARGET_DIR}', overwriting any conflicting files. Continue?"; then
    err "Restore aborted (not confirmed)."
    exit 1
  fi

  mkdir -p "$TARGET_DIR"
  tar -xzf "$FILE" -C "$TARGET_DIR"

  END_TIME=$(date +%s)
  log "Restore complete."
  log "  Extracted to: ${TARGET_DIR}"
  log "  Duration:     $((END_TIME - START_TIME))s"
  exit 0
fi

# KIND = database
if [ -z "$TYPE" ]; then
  err "--type mysql|postgres is required to restore a .sql.gz backup (ambiguous otherwise)."
  exit 1
fi

if [ -z "$DATABASE" ]; then
  err "--database is required to restore a database backup."
  exit 1
fi

PASSWORD=""
if [ -n "$PASSWORD_ENV" ]; then
  if [ -z "${!PASSWORD_ENV:-}" ]; then
    err "Environment variable '${PASSWORD_ENV}' (from --password-env) is not set or empty."
    exit 1
  fi
  PASSWORD="${!PASSWORD_ENV}"
fi

case "$TYPE" in
  mysql)
    require_cmd mysql
    RESTORE_ARGS=(--host="$HOST")
    [ -n "$PORT" ] && RESTORE_ARGS+=(--port="$PORT")
    [ -n "$USER" ] && RESTORE_ARGS+=(--user="$USER")
    RESTORE_ARGS+=("$DATABASE")
    ;;
  postgres)
    require_cmd psql
    RESTORE_ARGS=(--host="$HOST")
    [ -n "$PORT" ] && RESTORE_ARGS+=(--port="$PORT")
    [ -n "$USER" ] && RESTORE_ARGS+=(--username="$USER")
    RESTORE_ARGS+=(--dbname="$DATABASE")
    ;;
  *)
    err "Unknown --type: ${TYPE} (expected mysql or postgres)"
    exit 1
    ;;
esac

log "Backup type: ${TYPE} database dump"
log "  Source:   ${FILE}"
log "  Host:     ${HOST}"
log "  Database: ${DATABASE}"

if [ "$DRY_RUN" = true ]; then
  log "DRY-RUN: would restore into ${TYPE} database '${DATABASE}' on ${HOST} from ${FILE}"
  log "Dry run complete. No changes were made."
  exit 0
fi

if ! confirm "This will restore into ${TYPE} database '${DATABASE}' on ${HOST}, overwriting existing data. Continue?"; then
  err "Restore aborted (not confirmed)."
  exit 1
fi

log "Restoring..."
if [ "$TYPE" = "mysql" ]; then
  if [ -n "$PASSWORD" ]; then
    gzip -dc "$FILE" | MYSQL_PWD="$PASSWORD" mysql "${RESTORE_ARGS[@]}"
  else
    gzip -dc "$FILE" | mysql "${RESTORE_ARGS[@]}"
  fi
else
  if [ -n "$PASSWORD" ]; then
    gzip -dc "$FILE" | PGPASSWORD="$PASSWORD" psql "${RESTORE_ARGS[@]}"
  else
    gzip -dc "$FILE" | psql "${RESTORE_ARGS[@]}"
  fi
fi

END_TIME=$(date +%s)
log "Restore complete."
log "  Database:  ${DATABASE}"
log "  Duration:  $((END_TIME - START_TIME))s"
