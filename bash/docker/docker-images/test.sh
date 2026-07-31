#!/usr/bin/env bash
#
# test.sh — basic checks for docker-images.sh. Read-only script, so all
# checks can run against real Docker state. Run: ./test.sh

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SCRIPT="${SCRIPT_DIR}/docker-images.sh"

pass=0
fail=0

assert_exit_code() {
  local desc="$1" expected="$2"; shift 2
  local actual=0
  "$@" >/tmp/docker-images-test.out 2>&1 || actual=$?
  if [ "$actual" -eq "$expected" ]; then
    echo "ok   - $desc"
    pass=$((pass + 1))
  else
    echo "FAIL - $desc (expected exit $expected, got $actual)"
    cat /tmp/docker-images-test.out
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
assert_exit_code "invalid --output value exits non-zero" 1 "$SCRIPT" --output bogus

assert_output_contains "usage mentions --sort-by-size" "--sort-by-size" "$SCRIPT" --help
assert_output_contains "usage mentions --dangling-only" "--dangling-only" "$SCRIPT" --help
assert_output_contains "usage mentions --output" "--output" "$SCRIPT" --help
assert_output_contains "unknown option is reported" "Unknown option" "$SCRIPT" --bogus

if command -v docker >/dev/null 2>&1 && docker info >/dev/null 2>&1; then
  assert_exit_code "default table report succeeds" 0 "$SCRIPT"
  assert_exit_code "--sort-by-size succeeds" 0 "$SCRIPT" --sort-by-size
  assert_exit_code "--dangling-only succeeds" 0 "$SCRIPT" --dangling-only
  assert_exit_code "--output csv succeeds" 0 "$SCRIPT" --output csv
  assert_exit_code "--output json succeeds" 0 "$SCRIPT" --output json

  assert_output_contains "table report has header" "REPOSITORY" "$SCRIPT"
  assert_output_contains "csv report has header" "Repository,Tag,ImageID,Size,Created,Dangling" "$SCRIPT" --output csv
  assert_output_contains "json report is an array" "[" "$SCRIPT" --output json
else
  echo "skip - Docker not available, skipping report integration checks"
fi

echo
echo "Passed: $pass  Failed: $fail"
[ "$fail" -eq 0 ]
