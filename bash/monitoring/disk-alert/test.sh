#!/usr/bin/env bash
#
# test.sh — basic checks for disk-alert.sh

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SCRIPT="${SCRIPT_DIR}/disk-alert.sh"

pass=0
fail=0

assert_exit_code() {
  local desc="$1" expected="$2"; shift 2
  local actual=0
  "$@" >/tmp/disk-alert-test.out 2>&1 || actual=$?
  if [ "$actual" -eq "$expected" ]; then
    echo "ok   - $desc"
    pass=$((pass + 1))
  else
    echo "FAIL - $desc (expected exit $expected, got $actual)"
    cat /tmp/disk-alert-test.out
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
assert_exit_code "nonexistent mount exits non-zero" 1 "$SCRIPT" --mount /this/does/not/exist
assert_output_contains "usage mentions --all" "--all" "$SCRIPT" --help

if command -v df >/dev/null 2>&1; then
  assert_exit_code "threshold 0 on / always alerts (exit 1)" 1 "$SCRIPT" --mount / --threshold 0
  assert_exit_code "threshold 100 on / never alerts (exit 0)" 0 "$SCRIPT" --mount / --threshold 100
else
  echo "skip - df not available, skipping functional checks"
fi

echo
echo "Passed: $pass  Failed: $fail"
[ "$fail" -eq 0 ]
