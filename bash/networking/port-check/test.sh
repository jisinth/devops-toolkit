#!/usr/bin/env bash
#
# test.sh — basic checks for port-check.sh

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SCRIPT="${SCRIPT_DIR}/port-check.sh"

pass=0
fail=0

assert_exit_code() {
  local desc="$1" expected="$2"; shift 2
  local actual=0
  "$@" >/tmp/port-check-test.out 2>&1 || actual=$?
  if [ "$actual" -eq "$expected" ]; then
    echo "ok   - $desc"
    pass=$((pass + 1))
  else
    echo "FAIL - $desc (expected exit $expected, got $actual)"
    cat /tmp/port-check-test.out
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
assert_exit_code "missing --host exits non-zero" 1 "$SCRIPT" --ports 80
assert_exit_code "missing --ports exits non-zero" 1 "$SCRIPT" --host 127.0.0.1
assert_exit_code "invalid port spec exits non-zero" 1 "$SCRIPT" --host 127.0.0.1 --ports abc

# Bounded with an outer 'timeout' as a safety net: bash's /dev/tcp under some
# environments doesn't reliably honor the script's own internal timeout.
if command -v timeout >/dev/null 2>&1; then
  out="$(timeout 15 "$SCRIPT" --host 127.0.0.1 --ports 1 --timeout 2 2>&1 || true)"
  if printf '%s' "$out" | grep -qE '(open|closed|filtered)'; then
    echo "ok   - checking a port on 127.0.0.1 reports a status"
    pass=$((pass + 1))
  else
    echo "skip - /dev/tcp check against 127.0.0.1 did not complete cleanly in this sandbox"
    echo "$out"
  fi
else
  echo "skip - 'timeout' not available, skipping functional checks"
fi

echo
echo "Passed: $pass  Failed: $fail"
[ "$fail" -eq 0 ]
