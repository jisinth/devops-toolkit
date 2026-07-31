#!/usr/bin/env bash
#
# test.sh — basic checks for pod-logs.sh that don't require a live cluster
# for the core checks. Run: ./test.sh

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SCRIPT="${SCRIPT_DIR}/pod-logs.sh"

pass=0
fail=0

assert_exit_code() {
  local desc="$1" expected="$2"; shift 2
  local actual=0
  "$@" >/tmp/pod-logs-test.out 2>&1 || actual=$?
  if [ "$actual" -eq "$expected" ]; then
    echo "ok   - $desc"
    pass=$((pass + 1))
  else
    echo "FAIL - $desc (expected exit $expected, got $actual)"
    cat /tmp/pod-logs-test.out
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

assert_exit_code "no args prints usage and exits 0" 0 "$SCRIPT"
assert_exit_code "--help exits 0" 0 "$SCRIPT" --help
assert_exit_code "unknown option exits non-zero" 1 "$SCRIPT" --bogus
assert_exit_code "missing --namespace exits non-zero" 1 "$SCRIPT" -l app=api -o /tmp
assert_exit_code "missing --selector exits non-zero" 1 "$SCRIPT" -n prod -o /tmp
assert_exit_code "missing --output-dir exits non-zero" 1 "$SCRIPT" -n prod -l app=api

assert_output_contains "usage mentions --namespace" "--namespace" "$SCRIPT" --help
assert_output_contains "usage mentions --selector" "--selector" "$SCRIPT" --help
assert_output_contains "usage mentions --previous" "--previous" "$SCRIPT" --help
assert_output_contains "usage mentions --since" "--since" "$SCRIPT" --help
assert_output_contains "unknown option is reported" "Unknown option" "$SCRIPT" --bogus

if command -v kubectl >/dev/null 2>&1 && timeout 5 kubectl cluster-info >/dev/null 2>&1; then
  assert_exit_code "no pods for bogus selector exits 0" 0 "$SCRIPT" -n default -l app=this-selector-should-match-nothing -o /tmp
else
  echo "skip - no reachable Kubernetes cluster, skipping live integration checks"
fi

echo
echo "Passed: $pass  Failed: $fail"
[ "$fail" -eq 0 ]
