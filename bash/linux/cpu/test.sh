#!/usr/bin/env bash
#
# test.sh — basic checks for cpu.sh

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SCRIPT="${SCRIPT_DIR}/cpu.sh"

pass=0
fail=0

assert_exit_code() {
  local desc="$1" expected="$2"; shift 2
  local actual=0
  "$@" >/tmp/cpu-test.out 2>&1 || actual=$?
  if [ "$actual" -eq "$expected" ]; then
    echo "ok   - $desc"
    pass=$((pass + 1))
  else
    echo "FAIL - $desc (expected exit $expected, got $actual)"
    cat /tmp/cpu-test.out
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
assert_exit_code "non-numeric threshold exits non-zero" 1 "$SCRIPT" --threshold abc
assert_output_contains "usage mentions --top" "--top" "$SCRIPT" --help

if [ -r /proc/stat ]; then
  assert_exit_code "threshold 0 always alerts (exit 1)" 1 "$SCRIPT" --threshold 0 --interval 1
  assert_exit_code "threshold 100 never alerts (exit 0)" 0 "$SCRIPT" --threshold 100 --interval 1
  if ps -eo pid,ppid,%cpu,%mem,comm >/dev/null 2>&1; then
    assert_output_contains "--top 3 lists processes" "COMMAND" "$SCRIPT" --threshold 100 --top 3 --interval 1
  else
    echo "skip - 'ps -eo ...' (GNU-style) not supported by this ps, skipping --top check"
  fi
else
  echo "skip - /proc/stat not available, skipping functional checks"
fi

echo
echo "Passed: $pass  Failed: $fail"
[ "$fail" -eq 0 ]
