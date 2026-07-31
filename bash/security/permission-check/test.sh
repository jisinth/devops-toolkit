#!/usr/bin/env bash
#
# test.sh — basic checks for permission-check.sh

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SCRIPT="${SCRIPT_DIR}/permission-check.sh"

pass=0
fail=0

assert_exit_code() {
  local desc="$1" expected="$2"; shift 2
  local actual=0
  "$@" >/tmp/permission-check-test.out 2>&1 || actual=$?
  if [ "$actual" -eq "$expected" ]; then
    echo "ok   - $desc"
    pass=$((pass + 1))
  else
    echo "FAIL - $desc (expected exit $expected, got $actual)"
    cat /tmp/permission-check-test.out
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
assert_exit_code "nonexistent path exits non-zero" 1 "$SCRIPT" --path /this/does/not/exist
assert_output_contains "usage mentions --path" "--path" "$SCRIPT" --help

if command -v find >/dev/null 2>&1; then
  SCRATCH="$(mktemp -d)"
  trap 'rm -rf "$SCRATCH"' EXIT
  touch "${SCRATCH}/normal.txt"

  assert_exit_code "scan of an isolated scratch dir succeeds" 0 "$SCRIPT" --path "$SCRATCH"
  assert_output_contains "report includes the world-writable section" "World-writable files/directories" "$SCRIPT" --path "$SCRATCH"
  assert_output_contains "report includes the SUID/SGID section" "SUID/SGID binaries" "$SCRIPT" --path "$SCRATCH"

  chmod 0777 "${SCRATCH}/normal.txt" 2>/dev/null || true
  if [ "$(stat -c '%a' "${SCRATCH}/normal.txt" 2>/dev/null || stat -f '%Lp' "${SCRATCH}/normal.txt" 2>/dev/null)" = "777" ]; then
    assert_output_contains "world-writable file is detected" "normal.txt" "$SCRIPT" --path "$SCRATCH"
  else
    echo "skip - chmod 0777 did not take effect on this filesystem, skipping world-writable detection check"
  fi
else
  echo "skip - find not available, skipping functional checks"
fi

echo
echo "Passed: $pass  Failed: $fail"
[ "$fail" -eq 0 ]
