#!/usr/bin/env bash
#
# firewall-report.sh — detect the active firewall subsystem (ufw,
# firewalld, nftables, or iptables) and print its current rules in a
# normalized, readable summary. Read-only.
#
# Usage: ./firewall-report.sh
# Run with --help for full usage.

set -euo pipefail

SCRIPT_NAME="$(basename "$0")"

usage() {
  cat <<EOF
Usage: ${SCRIPT_NAME}

Detect which firewall subsystem is active on this host (checked in order:
ufw, firewalld, nftables, iptables) and print its current rules.

Options:
  -h, --help   Show this help message and exit

Examples:
  ${SCRIPT_NAME}

Notes:
  Read-only: this script never modifies firewall rules. Reading rules
  typically requires root privileges.
EOF
}

log()  { printf '[firewall-report] %s\n' "$*"; }
err()  { printf '[firewall-report] ERROR: %s\n' "$*" >&2; }

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

if command -v ufw >/dev/null 2>&1 && ufw status >/dev/null 2>&1; then
  log "Detected: ufw"
  ufw status verbose
elif command -v firewall-cmd >/dev/null 2>&1 && firewall-cmd --state >/dev/null 2>&1; then
  log "Detected: firewalld"
  echo "Default zone: $(firewall-cmd --get-default-zone)"
  echo
  echo "Active zones:"
  firewall-cmd --get-active-zones
  echo
  for zone in $(firewall-cmd --get-active-zones | awk 'NR % 2 == 1'); do
    echo "--- zone: ${zone} ---"
    firewall-cmd --zone="$zone" --list-all
  done
elif command -v nft >/dev/null 2>&1 && nft list ruleset >/dev/null 2>&1; then
  log "Detected: nftables"
  nft list ruleset
elif command -v iptables >/dev/null 2>&1; then
  log "Detected: iptables"
  iptables -L -n -v
else
  err "No supported firewall subsystem found (checked: ufw, firewalld, nftables, iptables)."
  exit 1
fi
