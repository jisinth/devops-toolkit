#!/usr/bin/env bash
#
# test.sh — basic checks for disk-usage.sh. Run: ./test.sh

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SCRIPT="${SCRIPT_DIR}/disk-usage.sh"

pass=0
fail=0

assert_exit_code() {
  local desc="$1" expected="$2"; shift 2
  local actual=0
  "$@" >/tmp/disk-usage-test.out 2>&1 || actual=$?
  if [ "$actual" -eq "$expected" ]; then
    echo "ok   - $desc"
    pass=$((pass + 1))
  else
    echo "FAIL - $desc (expected exit $expected, got $actual)"
    cat /tmp/disk-usage-test.out
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

if command -v df >/dev/null 2>&1; then
  assert_exit_code "default run with a very high threshold succeeds" 0 "$SCRIPT" --threshold 100
  assert_output_contains "reports below threshold at 100%" "below the 100% threshold" "$SCRIPT" --threshold 100

  if command -v du >/dev/null 2>&1; then
    TOP_TEST_DIR="$(mktemp -d)"
    mkdir -p "$TOP_TEST_DIR/subdir"
    echo "test" > "$TOP_TEST_DIR/subdir/file.txt"
    assert_exit_code "--top 1 --path <small dir> succeeds" 0 "$SCRIPT" --threshold 100 --top 1 --path "$TOP_TEST_DIR"
    assert_output_contains "--top output header" "largest directories" "$SCRIPT" --threshold 100 --top 1 --path "$TOP_TEST_DIR"
    rm -rf "$TOP_TEST_DIR"
  else
    echo "skip - du not available, skipping --top checks"
  fi

  assert_exit_code "--path pointing at a non-directory fails" 1 "$SCRIPT" --top 1 --path /this/does/not/exist
else
  echo "skip - df not available, skipping functional df checks"
fi

echo
echo "Passed: $pass  Failed: $fail"
[ "$fail" -eq 0 ]
