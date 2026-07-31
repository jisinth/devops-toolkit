#!/usr/bin/env bash
#
# test.sh — basic checks for website-health.sh

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SCRIPT="${SCRIPT_DIR}/website-health.sh"

pass=0
fail=0

assert_exit_code() {
  local desc="$1" expected="$2"; shift 2
  local actual=0
  "$@" >/tmp/website-health-test.out 2>&1 || actual=$?
  if [ "$actual" -eq "$expected" ]; then
    echo "ok   - $desc"
    pass=$((pass + 1))
  else
    echo "FAIL - $desc (expected exit $expected, got $actual)"
    cat /tmp/website-health-test.out
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
assert_exit_code "no URLs given exits non-zero" 1 "$SCRIPT"
assert_output_contains "usage mentions --url-file" "--url-file" "$SCRIPT" --help

if command -v curl >/dev/null 2>&1 && curl -s -o /dev/null -m 5 https://example.com 2>/dev/null; then
  assert_exit_code "example.com passes the health check" 0 "$SCRIPT" --timeout 10 https://example.com
else
  echo "skip - no network egress to example.com, skipping functional check"
fi

echo
echo "Passed: $pass  Failed: $fail"
[ "$fail" -eq 0 ]
