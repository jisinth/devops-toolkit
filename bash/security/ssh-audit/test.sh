#!/usr/bin/env bash
#
# test.sh — basic checks for ssh-audit.sh

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SCRIPT="${SCRIPT_DIR}/ssh-audit.sh"

pass=0
fail=0

assert_exit_code() {
  local desc="$1" expected="$2"; shift 2
  local actual=0
  "$@" >/tmp/ssh-audit-test.out 2>&1 || actual=$?
  if [ "$actual" -eq "$expected" ]; then
    echo "ok   - $desc"
    pass=$((pass + 1))
  else
    echo "FAIL - $desc (expected exit $expected, got $actual)"
    cat /tmp/ssh-audit-test.out
    fail=$((fail + 1))
  fi
}

assert_output_contains() {
  local desc="$1" needle="$2"; shift 2
  local out
  out="$("$@" 2>&1 || true)"
  if printf '%s' "$out" | grep -qF -- "$needle"; then
    echo "ok   - $desc"
    pass=$((pass + 1))
  else
    echo "FAIL - $desc (expected output to contain: $needle)"
    echo "$out"
    fail=$((fail + 1))
  fi
}

assert_exit_code "--help exits 0" 0 "$SCRIPT" --help
assert_exit_code "unknown option exits non-zero" 1 "$SCRIPT" --bogus
assert_exit_code "missing config file exits non-zero" 1 "$SCRIPT" --config /this/does/not/exist
assert_output_contains "usage mentions --config" "--config" "$SCRIPT" --help

TMP_CONF="$(mktemp)"
trap 'rm -f "$TMP_CONF"' EXIT

cat > "$TMP_CONF" <<'EOF'
Port 22
PermitRootLogin yes
PasswordAuthentication yes
X11Forwarding no
EOF
assert_exit_code "insecure config fails the audit (exit 1)" 1 "$SCRIPT" --config "$TMP_CONF"
assert_output_contains "insecure config flags PermitRootLogin" "FAIL  Root login disabled" "$SCRIPT" --config "$TMP_CONF"

cat > "$TMP_CONF" <<'EOF'
Port 22
PermitRootLogin no
PasswordAuthentication no
PermitEmptyPasswords no
X11Forwarding no
Protocol 2
EOF
assert_exit_code "hardened config passes the audit (exit 0)" 0 "$SCRIPT" --config "$TMP_CONF"

echo
echo "Passed: $pass  Failed: $fail"
[ "$fail" -eq 0 ]
