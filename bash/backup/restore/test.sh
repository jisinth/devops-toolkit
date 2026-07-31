#!/usr/bin/env bash
#
# test.sh — basic checks for restore.sh, including a real file-backup ->
# restore round trip using file-backup.sh's own output.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SCRIPT="${SCRIPT_DIR}/restore.sh"
FILE_BACKUP_SCRIPT="${SCRIPT_DIR}/../file-backup/file-backup.sh"

pass=0
fail=0

assert_exit_code() {
  local desc="$1" expected="$2"; shift 2
  local actual=0
  "$@" >/tmp/restore-test.out 2>&1 || actual=$?
  if [ "$actual" -eq "$expected" ]; then
    echo "ok   - $desc"
    pass=$((pass + 1))
  else
    echo "FAIL - $desc (expected exit $expected, got $actual)"
    cat /tmp/restore-test.out
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
assert_exit_code "missing --file exits non-zero" 1 "$SCRIPT" --yes
assert_exit_code "nonexistent --file exits non-zero" 1 "$SCRIPT" --file /does/not/exist.tar.gz
assert_output_contains "usage mentions --dry-run" "--dry-run" "$SCRIPT" --help

TMP_UNKNOWN_EXT="$(mktemp -u).bin"
touch "$TMP_UNKNOWN_EXT"
assert_exit_code "unrecognized extension exits non-zero" 1 "$SCRIPT" --file "$TMP_UNKNOWN_EXT"
rm -f "$TMP_UNKNOWN_EXT"

if command -v tar >/dev/null 2>&1 && command -v gzip >/dev/null 2>&1 && [ -x "$FILE_BACKUP_SCRIPT" ]; then
  SRC="$(mktemp -d)"
  BACKUP_DIR="$(mktemp -d)"
  TARGET="$(mktemp -d)"
  trap 'rm -rf "$SRC" "$BACKUP_DIR" "$TARGET"' EXIT

  echo "original content" > "${SRC}/data.txt"
  "$FILE_BACKUP_SCRIPT" --source "$SRC" --output-dir "$BACKUP_DIR" >/dev/null 2>&1
  archive="$(find "$BACKUP_DIR" -name '*.tar.gz' | head -1)"

  if [ -z "$archive" ]; then
    echo "FAIL - could not produce a test backup archive via file-backup.sh"
    fail=$((fail + 1))
  else
    assert_exit_code "dry-run restore succeeds without extracting" 0 "$SCRIPT" --file "$archive" --target-dir "$TARGET" --dry-run
    if [ ! -e "${TARGET}/$(basename "$SRC")/data.txt" ]; then
      echo "ok   - dry-run did not extract any files"
      pass=$((pass + 1))
    else
      echo "FAIL - dry-run extracted files, it should not have"
      fail=$((fail + 1))
    fi

    assert_exit_code "restore with -y extracts the archive" 0 "$SCRIPT" --file "$archive" --target-dir "$TARGET" -y
    restored_file="${TARGET}/$(basename "$SRC")/data.txt"
    if [ -f "$restored_file" ] && grep -q "original content" "$restored_file"; then
      echo "ok   - restored file matches the original content"
      pass=$((pass + 1))
    else
      echo "FAIL - restored file missing or content mismatch"
      fail=$((fail + 1))
    fi
  fi
else
  echo "skip - tar/gzip/file-backup.sh not available, skipping round-trip check"
fi

echo
echo "Passed: $pass  Failed: $fail"
[ "$fail" -eq 0 ]
