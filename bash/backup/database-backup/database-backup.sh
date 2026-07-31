#!/usr/bin/env bash
#
# database-backup.sh — thin dispatcher: picks mysql-backup.sh or
# postgres-backup.sh based on --type and execs it with all remaining args
# passed through unchanged.
#
# Usage: ./database-backup.sh --type mysql|postgres [script options...]
# Run with --help for full usage.

set -euo pipefail

SCRIPT_NAME="$(basename "$0")"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

MYSQL_SCRIPT="${SCRIPT_DIR}/../mysql-backup/mysql-backup.sh"
POSTGRES_SCRIPT="${SCRIPT_DIR}/../postgres-backup/postgres-backup.sh"

usage() {
  cat <<EOF
Usage: ${SCRIPT_NAME} --type mysql|postgres [options...]

Dispatch to mysql-backup.sh or postgres-backup.sh based on --type, passing
all other options through unchanged. See each script's --help (or README)
for its full option list.

Options:
  --type mysql|postgres      Which backup script to run (required)
  -h, --help                  Show this help message and exit

Examples:
  ${SCRIPT_NAME} --type mysql --database app --user backup --password-env MYSQL_PWD_VALUE
  ${SCRIPT_NAME} --type postgres --database app --user backup --password-env PG_PWD_VALUE
EOF
}

log()  { printf '[database-backup] %s\n' "$*"; }
err()  { printf '[database-backup] ERROR: %s\n' "$*" >&2; }

if [ "$#" -eq 0 ]; then
  usage
  exit 0
fi

TYPE=""
ARGS=()

while [ "$#" -gt 0 ]; do
  case "$1" in
    --type) TYPE="$2"; shift 2 ;;
    -h|--help) usage; exit 0 ;;
    *) ARGS+=("$1"); shift ;;
  esac
done

if [ -z "$TYPE" ]; then
  err "--type is required (mysql or postgres)."
  usage
  exit 1
fi

case "$TYPE" in
  mysql)
    TARGET="$MYSQL_SCRIPT"
    ;;
  postgres)
    TARGET="$POSTGRES_SCRIPT"
    ;;
  *)
    err "Unknown --type: ${TYPE} (expected mysql or postgres)"
    usage
    exit 1
    ;;
esac

if [ ! -x "$TARGET" ]; then
  err "Backup script not found or not executable: ${TARGET}"
  exit 1
fi

log "Dispatching to $(basename "$TARGET")"
exec "$TARGET" "${ARGS[@]+"${ARGS[@]}"}"
