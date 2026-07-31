#!/usr/bin/env bash
#
# test.sh — basic checks for pending-pods.sh

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SCRIPT="${SCRIPT_DIR}/pending-pods.sh"

pass=0
fail=0

assert_exit_code() {
  local desc="$1" expected="$2"; shift 2
  local actual=0
  "$@" >/tmp/pending-pods-test.out 2>&1 || actual=$?
  if [ "$actual" -eq "$expected" ]; then
    echo "ok   - $desc"
    pass=$((pass + 1))
  else
    echo "FAIL - $desc (expected exit $expected, got $actual)"
    cat /tmp/pending-pods-test.out
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
assert_output_contains "usage mentions --namespace" "--namespace" "$SCRIPT" --help

if command -v kubectl >/dev/null 2>&1 && kubectl cluster-info >/dev/null 2>&1; then
  assert_exit_code "cluster-wide check succeeds" 0 "$SCRIPT"
else
  echo "skip - no reachable Kubernetes cluster, skipping functional checks"
fi

echo
echo "Passed: $pass  Failed: $fail"
[ "$fail" -eq 0 ]
