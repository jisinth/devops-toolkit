#!/usr/bin/env bash
#
# test.sh — basic checks for file-backup.sh

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SCRIPT="${SCRIPT_DIR}/file-backup.sh"

pass=0
fail=0

assert_exit_code() {
  local desc="$1" expected="$2"; shift 2
  local actual=0
  "$@" >/tmp/file-backup-test.out 2>&1 || actual=$?
  if [ "$actual" -eq "$expected" ]; then
    echo "ok   - $desc"
    pass=$((pass + 1))
  else
    echo "FAIL - $desc (expected exit $expected, got $actual)"
    cat /tmp/file-backup-test.out
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
assert_exit_code "no args prints usage and exits 0" 0 "$SCRIPT"
assert_exit_code "unknown option exits non-zero" 1 "$SCRIPT" --bogus
assert_exit_code "nonexistent --source exits non-zero" 1 "$SCRIPT" --source /this/does/not/exist
assert_output_contains "usage mentions --exclude" "--exclude" "$SCRIPT" --help

if command -v tar >/dev/null 2>&1 && command -v gzip >/dev/null 2>&1; then
  SRC="$(mktemp -d)"
  OUT="$(mktemp -d)"
  trap 'rm -rf "$SRC" "$OUT"' EXIT

  echo "hello" > "${SRC}/keep.txt"
  echo "excluded" > "${SRC}/skip.log"

  "$SCRIPT" --source "$SRC" --exclude '*.log' --output-dir "$OUT" >/tmp/file-backup-run.out 2>&1
  archive="$(find "$OUT" -name '*.tar.gz' | head -1)"

  if [ -n "$archive" ] && tar -tzf "$archive" >/dev/null 2>&1; then
    echo "ok   - backup archive created and passes integrity check"
    pass=$((pass + 1))
  else
    echo "FAIL - backup archive missing or corrupt"
    cat /tmp/file-backup-run.out
    fail=$((fail + 1))
  fi

  contents="$(tar -tzf "$archive")"
  if printf '%s\n' "$contents" | grep -q "keep.txt" && ! printf '%s\n' "$contents" | grep -q "skip.log"; then
    echo "ok   - --exclude kept keep.txt and dropped skip.log"
    pass=$((pass + 1))
  else
    echo "FAIL - --exclude did not filter the archive contents as expected"
    printf '%s\n' "$contents"
    fail=$((fail + 1))
  fi
else
  echo "skip - tar/gzip not available, skipping functional checks"
fi

echo
echo "Passed: $pass  Failed: $fail"
[ "$fail" -eq 0 ]
