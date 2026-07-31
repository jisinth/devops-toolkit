#!/usr/bin/env bash
#
# test.sh — basic checks for docker-network.sh

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SCRIPT="${SCRIPT_DIR}/docker-network.sh"

pass=0
fail=0

assert_exit_code() {
  local desc="$1" expected="$2"; shift 2
  local actual=0
  "$@" >/tmp/docker-network-test.out 2>&1 || actual=$?
  if [ "$actual" -eq "$expected" ]; then
    echo "ok   - $desc"
    pass=$((pass + 1))
  else
    echo "FAIL - $desc (expected exit $expected, got $actual)"
    cat /tmp/docker-network-test.out
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
assert_output_contains "usage mentions --unused-only" "--unused-only" "$SCRIPT" --help

if command -v docker >/dev/null 2>&1 && docker info >/dev/null 2>&1; then
  NET_NAME="docker-network-test-$$"
  docker network create "$NET_NAME" >/dev/null
  trap 'docker network rm "$NET_NAME" >/dev/null 2>&1 || true' EXIT
  assert_exit_code "default report succeeds" 0 "$SCRIPT"
  assert_output_contains "unused-only report lists the unattached test network" "$NET_NAME" "$SCRIPT" --unused-only
else
  echo "skip - Docker not available, skipping functional checks"
fi

echo
echo "Passed: $pass  Failed: $fail"
[ "$fail" -eq 0 ]
