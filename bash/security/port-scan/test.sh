#!/usr/bin/env bash
#
# test.sh — basic checks for port-scan.sh. Run: ./test.sh

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SCRIPT="${SCRIPT_DIR}/port-scan.sh"

pass=0
fail=0

assert_exit_code() {
  local desc="$1" expected="$2"; shift 2
  local actual=0
  "$@" >/tmp/port-scan-test.out 2>&1 || actual=$?
  if [ "$actual" -eq "$expected" ]; then
    echo "ok   - $desc"
    pass=$((pass + 1))
  else
    echo "FAIL - $desc (expected exit $expected, got $actual)"
    cat /tmp/port-scan-test.out
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
assert_exit_code "missing --host exits non-zero" 1 "$SCRIPT" --range 1-10
assert_exit_code "invalid --range exits non-zero" 1 "$SCRIPT" --host 127.0.0.1 --range bogus

assert_output_contains "usage mentions --host" "--host" "$SCRIPT" --help
assert_output_contains "usage mentions --range" "--range" "$SCRIPT" --help
assert_output_contains "usage includes authorization reminder" "AUTHORIZED USE ONLY" "$SCRIPT" --help
assert_output_contains "unknown option is reported" "Unknown option" "$SCRIPT" --bogus
assert_output_contains "missing host is reported" "--host is required" "$SCRIPT" --range 1-10

# Integration: scan localhost over a narrow, fast range. Don't assert on
# which ports are open (environment-dependent) — just that it runs cleanly.
# Run once and reuse the output/exit code to keep the whole suite fast.
scan_rc=0
scan_out="$("$SCRIPT" --host 127.0.0.1 --range 1-10 --timeout 1 2>&1)" || scan_rc=$?

if [ "$scan_rc" -eq 0 ]; then
  echo "ok   - scan of 127.0.0.1 over a narrow range succeeds"
  pass=$((pass + 1))
else
  echo "FAIL - scan of 127.0.0.1 over a narrow range succeeds (exit $scan_rc)"
  echo "$scan_out"
  fail=$((fail + 1))
fi

if printf '%s' "$scan_out" | grep -qF "AUTHORIZED USE ONLY"; then
  echo "ok   - scan output includes authorization reminder"
  pass=$((pass + 1))
else
  echo "FAIL - scan output includes authorization reminder"
  echo "$scan_out"
  fail=$((fail + 1))
fi

if printf '%s' "$scan_out" | grep -qF "Scan complete"; then
  echo "ok   - scan output reports completion"
  pass=$((pass + 1))
else
  echo "FAIL - scan output reports completion"
  echo "$scan_out"
  fail=$((fail + 1))
fi

echo
echo "Passed: $pass  Failed: $fail"
[ "$fail" -eq 0 ]
