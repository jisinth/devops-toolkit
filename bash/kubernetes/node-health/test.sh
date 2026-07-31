#!/usr/bin/env bash
#
# test.sh — basic checks for node-health.sh. Run: ./test.sh

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SCRIPT="${SCRIPT_DIR}/node-health.sh"

pass=0
fail=0

assert_exit_code() {
  local desc="$1" expected="$2"; shift 2
  local actual=0
  "$@" >/tmp/node-health-test.out 2>&1 || actual=$?
  if [ "$actual" -eq "$expected" ]; then
    echo "ok   - $desc"
    pass=$((pass + 1))
  else
    echo "FAIL - $desc (expected exit $expected, got $actual)"
    cat /tmp/node-health-test.out
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

assert_output_contains "usage mentions --node" "--node" "$SCRIPT" --help
assert_output_contains "usage mentions Ready condition" "Ready" "$SCRIPT" --help
assert_output_contains "unknown option is reported" "Unknown option" "$SCRIPT" --bogus

if ! command -v kubectl >/dev/null 2>&1; then
  echo "skip - kubectl not installed, skipping live integration checks"
  assert_exit_code "no kubectl: fails clearly with non-zero exit" 1 "$SCRIPT"
  assert_output_contains "no kubectl: error message is clear" "kubectl CLI not found" "$SCRIPT"
elif ! timeout 5 kubectl cluster-info >/dev/null 2>&1; then
  echo "skip - no reachable Kubernetes cluster, skipping live integration checks"
  assert_exit_code "no cluster: fails clearly with non-zero exit" 1 "$SCRIPT"
  assert_output_contains "no cluster: error message is clear" "not reachable" "$SCRIPT"
else
  assert_exit_code "reports on a nonexistent node with non-zero exit" 1 "$SCRIPT" --node this-node-should-not-exist
  assert_output_contains "default run prints a header row" "READY" "$SCRIPT"
fi

echo
echo "Passed: $pass  Failed: $fail"
[ "$fail" -eq 0 ]
