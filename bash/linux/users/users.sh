#!/usr/bin/env bash
#
# users.sh — report local users: last login, locked/expired accounts,
# UID 0 accounts other than root, and accounts with empty passwords.
#
# Usage: ./users.sh [options]
# Run with --help for full usage.

set -euo pipefail

SCRIPT_NAME="$(basename "$0")"

usage() {
  cat <<EOF
Usage: ${SCRIPT_NAME} [options]

Report local users from /etc/passwd: last login (lastlog, if available),
locked/expired accounts (chage -l, if available), UID 0 accounts other
than root, and accounts with an empty password field (requires read
access to /etc/shadow).

Options:
  -h, --help   Show this help message and exit

Examples:
  ${SCRIPT_NAME}
EOF
}

log()  { printf '[users] %s\n' "$*"; }
err()  { printf '[users] ERROR: %s\n' "$*" >&2; }

while [ "$#" -gt 0 ]; do
  case "$1" in
    -h|--help) usage; exit 0 ;;
    *)
      err "Unknown option: $1"
      usage
      exit 1
      ;;
  esac
done

if [ ! -r /etc/passwd ]; then
  err "/etc/passwd is not readable; this script requires a Linux host."
  exit 1
fi

log "UID 0 accounts other than root:"
found_uid0=false
while IFS=: read -r name _ uid _ _ _ _; do
  if [ "$uid" = "0" ] && [ "$name" != "root" ]; then
    echo "  $name"
    found_uid0=true
  fi
done < /etc/passwd
[ "$found_uid0" = false ] && log "  (none found)"

log "Last login per user:"
if command -v lastlog >/dev/null 2>&1; then
  lastlog 2>/dev/null | sed 's/^/  /'
else
  log "  'lastlog' not available on this system, skipping."
fi

log "Account expiry/lock status (chage):"
if command -v chage >/dev/null 2>&1; then
  while IFS=: read -r name _ _ _ _ _ _ _ _; do
    chage_out=$(chage -l "$name" 2>/dev/null) || continue
    expires=$(printf '%s\n' "$chage_out" | awk -F': ' '/^Account expires/ {print $2}')
    if [ -n "$expires" ] && [ "$expires" != "never" ]; then
      echo "  ${name}: expires ${expires}"
    fi
  done < /etc/passwd
else
  log "  'chage' not available on this system, skipping."
fi

log "Accounts with an empty password:"
if [ -r /etc/shadow ]; then
  found_empty=false
  while IFS=: read -r name pass _; do
    if [ -z "$pass" ]; then
      echo "  $name"
      found_empty=true
    fi
  done < /etc/shadow
  [ "$found_empty" = false ] && log "  (none found)"
else
  log "  /etc/shadow not readable (need root), skipping."
fi

exit 0
