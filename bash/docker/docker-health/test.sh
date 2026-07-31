#!/usr/bin/env bash
#
# test.sh — basic checks for docker-health.sh

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SCRIPT="${SCRIPT_DIR}/docker-health.sh"

pass=0
fail=0

assert_exit_code() {
  local desc="$1" expected="$2"; shift 2
  local actual=0
  "$@" >/tmp/docker-health-test.out 2>&1 || actual=$?
  if [ "$actual" -eq "$expected" ]; then
    echo "ok   - $desc"
    pass=$((pass + 1))
  else
    echo "FAIL - $desc (expected exit $expected, got $actual)"
    cat /tmp/docker-health-test.out
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
assert_exit_code "invalid --output format exits non-zero" 1 "$SCRIPT" --output bogus
assert_output_contains "usage mentions --fix" "--fix" "$SCRIPT" --help

if command -v docker >/dev/null 2>&1 && docker info >/dev/null 2>&1; then
  assert_exit_code "default report succeeds" 0 "$SCRIPT"
  assert_exit_code "json report succeeds" 0 "$SCRIPT" --output json
else
  echo "skip - Docker not available, skipping functional checks"
fi

echo
echo "Passed: $pass  Failed: $fail"
[ "$fail" -eq 0 ]
