#!/usr/bin/env bash
#
# test.sh — basic checks for traceroute.sh

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SCRIPT="${SCRIPT_DIR}/traceroute.sh"

pass=0
fail=0

assert_exit_code() {
  local desc="$1" expected="$2"; shift 2
  local actual=0
  "$@" >/tmp/traceroute-test.out 2>&1 || actual=$?
  if [ "$actual" -eq "$expected" ]; then
    echo "ok   - $desc"
    pass=$((pass + 1))
  else
    echo "FAIL - $desc (expected exit $expected, got $actual)"
    cat /tmp/traceroute-test.out
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
assert_exit_code "no host given exits non-zero" 1 "$SCRIPT"
assert_exit_code "two hosts given exits non-zero" 1 "$SCRIPT" host1 host2
assert_output_contains "usage mentions --max-hops" "--max-hops" "$SCRIPT" --help

if command -v traceroute >/dev/null 2>&1 || command -v tracepath >/dev/null 2>&1; then
  echo "(traceroute/tracepath present; not asserting on live trace output)"
else
  assert_exit_code "neither tool available exits non-zero with a clear error" 1 "$SCRIPT" 127.0.0.1
  assert_output_contains "error names both tools" "tracepath" "$SCRIPT" 127.0.0.1
fi

echo
echo "Passed: $pass  Failed: $fail"
[ "$fail" -eq 0 ]
