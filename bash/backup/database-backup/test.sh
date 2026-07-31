#!/usr/bin/env bash
#
# test.sh — basic checks for database-backup.sh. Run: ./test.sh

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SCRIPT="${SCRIPT_DIR}/database-backup.sh"
TMP_OUT="$(mktemp)"
trap 'rm -f "$TMP_OUT"' EXIT

pass=0
fail=0

assert_exit_code() {
  local desc="$1" expected="$2"; shift 2
  local actual=0
  "$@" >"$TMP_OUT" 2>&1 || actual=$?
  if [ "$actual" -eq "$expected" ]; then
    echo "ok   - $desc"
    pass=$((pass + 1))
  else
    echo "FAIL - $desc (expected exit $expected, got $actual)"
    cat "$TMP_OUT"
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
assert_exit_code "missing --type exits non-zero" 1 "$SCRIPT" --database app
assert_exit_code "unsupported --type exits non-zero" 1 "$SCRIPT" --type oracle

assert_output_contains "usage mentions --type" "--type" "$SCRIPT" --help
assert_output_contains "missing --type is reported" "--type is required" "$SCRIPT" --database app
assert_output_contains "unsupported type is reported" "Unknown --type" "$SCRIPT" --type oracle

assert_output_contains "dispatches to mysql-backup.sh" "Dispatching to mysql-backup.sh" "$SCRIPT" --type mysql --user root
assert_output_contains "dispatches to postgres-backup.sh" "Dispatching to postgres-backup.sh" "$SCRIPT" --type postgres --user postgres
assert_output_contains "passes args through to mysql-backup.sh" "--database is required" "$SCRIPT" --type mysql --user root
assert_output_contains "passes args through to postgres-backup.sh" "--database is required" "$SCRIPT" --type postgres --user postgres

echo
echo "Passed: $pass  Failed: $fail"
[ "$fail" -eq 0 ]
