#!/usr/bin/env bash
#
# test.sh — basic checks for memory.sh. Run: ./test.sh

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SCRIPT="${SCRIPT_DIR}/memory.sh"

pass=0
fail=0

assert_exit_code() {
  local desc="$1" expected="$2"; shift 2
  local actual=0
  "$@" >/tmp/memory-test.out 2>&1 || actual=$?
  if [ "$actual" -eq "$expected" ]; then
    echo "ok   - $desc"
    pass=$((pass + 1))
  else
    echo "FAIL - $desc (expected exit $expected, got $actual)"
    cat /tmp/memory-test.out
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
assert_exit_code "--threshold with non-numeric value exits non-zero" 1 "$SCRIPT" --threshold abc
assert_exit_code "--top with non-numeric value exits non-zero" 1 "$SCRIPT" --top abc

assert_output_contains "usage mentions --threshold" "--threshold" "$SCRIPT" --help
assert_output_contains "usage mentions --top" "--top" "$SCRIPT" --help
assert_output_contains "unknown option is reported" "Unknown option" "$SCRIPT" --bogus

if command -v free >/dev/null 2>&1 || [ -r /proc/meminfo ]; then
  assert_exit_code "default run with a very high threshold succeeds" 0 "$SCRIPT" --threshold 100
  assert_output_contains "reports below threshold at 100%" "below the 100% threshold" "$SCRIPT" --threshold 100
else
  echo "skip - neither free nor /proc/meminfo available, skipping memory report checks"
fi

if command -v ps >/dev/null 2>&1 && ps -eo pid >/dev/null 2>&1; then
  assert_exit_code "--top 3 succeeds" 0 "$SCRIPT" --threshold 100 --top 3
  assert_output_contains "--top output header" "memory-consuming processes" "$SCRIPT" --threshold 100 --top 3
else
  echo "skip - ps does not support '-eo' (non-procps ps) in this environment, skipping --top checks"
fi

echo
echo "Passed: $pass  Failed: $fail"
[ "$fail" -eq 0 ]
