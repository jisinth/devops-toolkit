#!/usr/bin/env bash
#
# user-audit.sh — audit local users for security-relevant issues: empty
# passwords, UID 0 accounts other than root, sudo/wheel group membership,
# and accounts with no password expiry set. Read-only.
#
# Usage: ./user-audit.sh
# Run with --help for full usage.

set -euo pipefail

SCRIPT_NAME="$(basename "$0")"

usage() {
  cat <<EOF
Usage: ${SCRIPT_NAME}

Audit local users for security-relevant issues:
  - accounts with an empty password (requires /etc/shadow read access)
  - UID 0 accounts other than root
  - members of the sudo/wheel group
  - accounts with no password expiry set (chage, if available)

Read-only — this script never modifies user accounts.

Options:
  -h, --help   Show this help message and exit

Examples:
  ${SCRIPT_NAME}
  sudo ${SCRIPT_NAME}
EOF
}

log()  { printf '[user-audit] %s\n' "$*"; }
err()  { printf '[user-audit] ERROR: %s\n' "$*" >&2; }

while [ "$#" -gt 0 ]; do
  case "$1" in
    -h|--help) usage; exit 0 ;;
    *)
      err "Unknown option: $1"
      usage
      exit 1
      ;;
  esac
  shift
done

if [ ! -r /etc/passwd ]; then
  err "/etc/passwd is not readable; this script requires a Linux host."
  exit 1
fi

log "UID 0 accounts other than root:"
found=false
while IFS=: read -r name _ uid _ _ _ _; do
  if [ "$uid" = "0" ] && [ "$name" != "root" ]; then
    echo "  $name"
    found=true
  fi
done < /etc/passwd
[ "$found" = false ] && echo "  (none found)"

log "Members of sudo/wheel group:"
found=false
for grp in sudo wheel; do
  if command -v getent >/dev/null 2>&1; then
    members=$(getent group "$grp" 2>/dev/null | awk -F: '{print $4}')
  else
    members=$(awk -F: -v g="$grp" '$1 == g {print $4}' /etc/group 2>/dev/null)
  fi
  if [ -n "$members" ]; then
    echo "  ${grp}: ${members}"
    found=true
  fi
done
[ "$found" = false ] && echo "  (no sudo/wheel group members found)"

log "Accounts with an empty password:"
if [ -r /etc/shadow ]; then
  found=false
  while IFS=: read -r name pass _; do
    if [ -z "$pass" ]; then
      echo "  $name"
      found=true
    fi
  done < /etc/shadow
  [ "$found" = false ] && echo "  (none found)"
else
  echo "  /etc/shadow not readable (need root), skipping."
fi

log "Accounts with no password expiry set:"
if command -v chage >/dev/null 2>&1; then
  found=false
  while IFS=: read -r name _ _ _ _ _ _ _ _; do
    chage_out=$(chage -l "$name" 2>/dev/null) || continue
    expires=$(printf '%s\n' "$chage_out" | awk -F': ' '/^Password expires/ {print $2}')
    if [ "$expires" = "never" ]; then
      echo "  $name"
      found=true
    fi
  done < /etc/passwd
  [ "$found" = false ] && echo "  (all accounts have an expiry set)"
else
  echo "  'chage' not available on this system, skipping."
fi
