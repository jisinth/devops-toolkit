#!/usr/bin/env bash
#
# ssh-audit.sh — parse an sshd_config file and flag insecure settings.
# Read-only.
#
# Usage: ./ssh-audit.sh [options]
# Run with --help for full usage.

set -euo pipefail

SCRIPT_NAME="$(basename "$0")"

CONFIG="/etc/ssh/sshd_config"

usage() {
  cat <<EOF
Usage: ${SCRIPT_NAME} [options]

Parse an sshd_config file and report pass/fail for a set of common
security-relevant settings. Read-only.

Options:
  --config PATH   Path to sshd_config (default: ${CONFIG})
  -h, --help      Show this help message and exit

Examples:
  ${SCRIPT_NAME}
  ${SCRIPT_NAME} --config ./sshd_config.test
EOF
}

log()  { printf '[ssh-audit] %s\n' "$*"; }
err()  { printf '[ssh-audit] ERROR: %s\n' "$*" >&2; }

while [ "$#" -gt 0 ]; do
  case "$1" in
    --config)
      [ "$#" -ge 2 ] || { err "--config requires a value"; exit 1; }
      CONFIG="$2"
      shift
      ;;
    -h|--help) usage; exit 0 ;;
    *)
      err "Unknown option: $1"
      usage
      exit 1
      ;;
  esac
  shift
done

if [ ! -r "$CONFIG" ]; then
  err "Cannot read sshd_config at: $CONFIG"
  exit 1
fi

# get_setting <keyword> — returns the effective (last, case-insensitive)
# value for a keyword, ignoring comments and blank lines.
get_setting() {
  local keyword="$1"
  awk -v k="$keyword" '
    BEGIN { IGNORECASE = 1 }
    /^[[:space:]]*#/ { next }
    { sub(/#.*/, "") }
    $1 == k { val = $2 }
    END { print val }
  ' "$CONFIG"
}

FAILED=0

check() {
  local desc="$1" keyword="$2" bad_value="$3" default_if_unset="$4"
  local value
  value="$(get_setting "$keyword")"
  [ -z "$value" ] && value="$default_if_unset"

  if [ "$(printf '%s' "$value" | tr '[:upper:]' '[:lower:]')" = "$(printf '%s' "$bad_value" | tr '[:upper:]' '[:lower:]')" ]; then
    printf '  FAIL  %-28s %-20s (found/assumed: %s)\n' "$desc" "$keyword" "$value"
    FAILED=$((FAILED + 1))
  else
    printf '  PASS  %-28s %-20s (%s)\n' "$desc" "$keyword" "${value:-not set}"
  fi
}

log "Auditing ${CONFIG}:"
echo

check "Root login disabled"        "PermitRootLogin"        "yes" "prohibit-password"
check "Password auth disabled"     "PasswordAuthentication" "yes" "yes"
check "Empty passwords disabled"   "PermitEmptyPasswords"   "yes" "no"
check "X11 forwarding disabled"    "X11Forwarding"          "yes" "no"
check "Protocol 1 not in use"      "Protocol"               "1"   "2"

echo
if [ "$FAILED" -gt 0 ]; then
  log "${FAILED} check(s) failed."
  exit 1
fi

log "All checks passed."
