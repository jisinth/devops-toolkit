#!/usr/bin/env bash
#
# test.sh — basic checks for mysql-backup.sh. Run: ./test.sh

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SCRIPT="${SCRIPT_DIR}/mysql-backup.sh"
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
assert_exit_code "missing --database exits non-zero" 1 "$SCRIPT" --user root

assert_output_contains "usage mentions --database" "--database" "$SCRIPT" --help
assert_output_contains "usage mentions --password-env" "--password-env" "$SCRIPT" --help
assert_output_contains "usage mentions --pre-hook" "--pre-hook" "$SCRIPT" --help
assert_output_contains "usage mentions --upload-s3" "--upload-s3" "$SCRIPT" --help
assert_output_contains "unknown option is reported" "Unknown option" "$SCRIPT" --bogus
assert_output_contains "missing --database is reported" "--database is required" "$SCRIPT" --user root

if ! command -v mysqldump >/dev/null 2>&1; then
  echo "skip - mysqldump not installed, skipping live dump integration checks"
elif ! command -v mysqladmin >/dev/null 2>&1 || ! mysqladmin --host=127.0.0.1 --user=root ping >/dev/null 2>&1; then
  echo "skip - no reachable MySQL server on 127.0.0.1, skipping live dump integration checks"
else
  echo "info - live MySQL server detected but no test database configured; skipping live dump"
fi

echo
echo "Passed: $pass  Failed: $fail"
[ "$fail" -eq 0 ]
