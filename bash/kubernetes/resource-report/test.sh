#!/usr/bin/env bash
#
# test.sh — basic checks for resource-report.sh. Run: ./test.sh

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SCRIPT="${SCRIPT_DIR}/resource-report.sh"

pass=0
fail=0

assert_exit_code() {
  local desc="$1" expected="$2"; shift 2
  local actual=0
  "$@" >/tmp/resource-report-test.out 2>&1 || actual=$?
  if [ "$actual" -eq "$expected" ]; then
    echo "ok   - $desc"
    pass=$((pass + 1))
  else
    echo "FAIL - $desc (expected exit $expected, got $actual)"
    cat /tmp/resource-report-test.out
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
assert_exit_code "no namespace target exits non-zero" 1 "$SCRIPT" --pod foo
assert_exit_code "namespace and all-namespaces together exit non-zero" 1 "$SCRIPT" -n prod --all-namespaces
assert_exit_code "--pod with --all-namespaces exits non-zero" 1 "$SCRIPT" --all-namespaces --pod foo

assert_output_contains "usage mentions --all-namespaces" "--all-namespaces" "$SCRIPT" --help
assert_output_contains "usage mentions --pod" "--pod" "$SCRIPT" --help
assert_output_contains "unknown option is reported" "Unknown option" "$SCRIPT" --bogus

if command -v kubectl >/dev/null 2>&1 && timeout 5 kubectl cluster-info >/dev/null 2>&1; then
  assert_exit_code "nonexistent pod exits non-zero" 1 "$SCRIPT" -n default --pod this-pod-should-not-exist
else
  echo "skip - no reachable Kubernetes cluster, skipping live integration checks"
fi

echo
echo "Passed: $pass  Failed: $fail"
[ "$fail" -eq 0 ]
