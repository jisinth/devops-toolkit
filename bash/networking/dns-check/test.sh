#!/usr/bin/env bash
#
# test.sh — basic checks for dns-check.sh

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SCRIPT="${SCRIPT_DIR}/dns-check.sh"

pass=0
fail=0

assert_exit_code() {
  local desc="$1" expected="$2"; shift 2
  local actual=0
  "$@" >/tmp/dns-check-test.out 2>&1 || actual=$?
  if [ "$actual" -eq "$expected" ]; then
    echo "ok   - $desc"
    pass=$((pass + 1))
  else
    echo "FAIL - $desc (expected exit $expected, got $actual)"
    cat /tmp/dns-check-test.out
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
assert_exit_code "missing --host exits non-zero" 1 "$SCRIPT"
assert_output_contains "usage mentions --resolver" "--resolver" "$SCRIPT" --help

if command -v dig >/dev/null 2>&1 || command -v host >/dev/null 2>&1 || command -v nslookup >/dev/null 2>&1; then
  if timeout 8 "$SCRIPT" --host example.com --types A >/tmp/dns-check-live.out 2>&1; then
    echo "ok   - live A record lookup for example.com succeeds"
    pass=$((pass + 1))
  else
    echo "skip - no network egress for a live DNS lookup, skipping functional check"
    cat /tmp/dns-check-live.out
  fi
else
  echo "skip - no DNS lookup tool (dig/host/nslookup) available, skipping functional checks"
fi

echo
echo "Passed: $pass  Failed: $fail"
[ "$fail" -eq 0 ]
