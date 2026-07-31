#!/usr/bin/env bash
#
# test.sh — basic checks for process.sh

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SCRIPT="${SCRIPT_DIR}/process.sh"

pass=0
fail=0

assert_exit_code() {
  local desc="$1" expected="$2"; shift 2
  local actual=0
  "$@" >/tmp/process-test.out 2>&1 || actual=$?
  if [ "$actual" -eq "$expected" ]; then
    echo "ok   - $desc"
    pass=$((pass + 1))
  else
    echo "FAIL - $desc (expected exit $expected, got $actual)"
    cat /tmp/process-test.out
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
assert_exit_code "--fix without --zombie exits non-zero" 1 "$SCRIPT" --fix
assert_output_contains "usage mentions --zombie" "--zombie" "$SCRIPT" --help

assert_exit_code "--zombie listing succeeds" 0 "$SCRIPT" --zombie

if ps -eo pid,ppid,%cpu,%mem,comm >/dev/null 2>&1; then
  assert_output_contains "full listing includes header" "COMMAND" "$SCRIPT"
else
  echo "skip - 'ps -eo ...' (GNU-style) not supported by this ps, skipping full-listing check"
fi

echo
echo "Passed: $pass  Failed: $fail"
[ "$fail" -eq 0 ]
