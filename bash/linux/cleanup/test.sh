#!/usr/bin/env bash
#
# test.sh — basic checks for cleanup.sh

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SCRIPT="${SCRIPT_DIR}/cleanup.sh"

pass=0
fail=0

assert_exit_code() {
  local desc="$1" expected="$2"; shift 2
  local actual=0
  "$@" >/tmp/cleanup-test.out 2>&1 || actual=$?
  if [ "$actual" -eq "$expected" ]; then
    echo "ok   - $desc"
    pass=$((pass + 1))
  else
    echo "FAIL - $desc (expected exit $expected, got $actual)"
    cat /tmp/cleanup-test.out
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
assert_exit_code "non-numeric --days exits non-zero" 1 "$SCRIPT" --days abc
assert_output_contains "usage mentions --tmp-dir" "--tmp-dir" "$SCRIPT" --help

# Use an isolated scratch directory (not the real /tmp or /var/log) so this
# test is fast, deterministic, and never deletes anything real.
SCRATCH_TMP="$(mktemp -d)"
SCRATCH_LOG="$(mktemp -d)"
trap 'rm -rf "$SCRATCH_TMP" "$SCRATCH_LOG"' EXIT

old_file="${SCRATCH_TMP}/old-file.txt"
echo "old" > "$old_file"
# Back-date the file so it's older than the --days threshold.
touch -d '30 days ago' "$old_file" 2>/dev/null || touch -t 202001010000 "$old_file"

new_file="${SCRATCH_TMP}/new-file.txt"
echo "new" > "$new_file"

assert_output_contains "dry-run reports the old file, not the new one" "1 file(s)" \
  "$SCRIPT" --tmp-dir "$SCRATCH_TMP" --log-dir "$SCRATCH_LOG" --skip-pkg-cache --days 1

assert_exit_code "dry-run makes no changes (default)" 0 "$SCRIPT" --tmp-dir "$SCRATCH_TMP" --log-dir "$SCRATCH_LOG" --skip-pkg-cache --days 1
if [ -f "$old_file" ]; then
  echo "ok   - dry-run did not delete the old file"
  pass=$((pass + 1))
else
  echo "FAIL - dry-run deleted a file without --yes"
  fail=$((fail + 1))
fi

"$SCRIPT" --tmp-dir "$SCRATCH_TMP" --log-dir "$SCRATCH_LOG" --skip-pkg-cache --days 1 -y >/dev/null 2>&1
if [ ! -f "$old_file" ] && [ -f "$new_file" ]; then
  echo "ok   - --yes removed only the old file"
  pass=$((pass + 1))
else
  echo "FAIL - --yes did not remove exactly the old file"
  fail=$((fail + 1))
fi

echo
echo "Passed: $pass  Failed: $fail"
[ "$fail" -eq 0 ]
