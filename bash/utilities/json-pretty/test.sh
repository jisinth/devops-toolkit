#!/usr/bin/env bash
#
# test.sh — checks for json-pretty.sh. Run: ./test.sh

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SCRIPT="${SCRIPT_DIR}/json-pretty.sh"
TMP_DIR="$(mktemp -d)"
trap 'rm -rf "$TMP_DIR"' EXIT

pass=0
fail=0

assert_exit_code() {
  local desc="$1" expected="$2"; shift 2
  local actual=0
  "$@" >"${TMP_DIR}/out" 2>&1 || actual=$?
  if [ "$actual" -eq "$expected" ]; then
    echo "ok   - $desc"
    pass=$((pass + 1))
  else
    echo "FAIL - $desc (expected exit $expected, got $actual)"
    cat "${TMP_DIR}/out"
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
assert_output_contains "usage mentions --file" "--file" "$SCRIPT" --help

assert_exit_code "unknown option exits non-zero" 1 "$SCRIPT" --bogus
assert_output_contains "unknown option is reported" "Unknown option" "$SCRIPT" --bogus

assert_exit_code "missing file exits non-zero" 1 "$SCRIPT" --file "${TMP_DIR}/does-not-exist.json"

# Valid JSON via stdin is pretty-printed.
assert_exit_code "valid JSON on stdin exits 0" 0 bash -c "printf '{\"a\":1,\"b\":[1,2,3]}' | '$SCRIPT'"
out="$(printf '{"a":1,"b":[1,2,3]}' | "$SCRIPT")"
if printf '%s' "$out" | grep -q '"a": 1' && printf '%s' "$out" | grep -q '"b"'; then
  echo "ok   - valid JSON is pretty-printed with expected keys"
  pass=$((pass + 1))
else
  echo "FAIL - valid JSON is pretty-printed with expected keys"
  echo "$out"
  fail=$((fail + 1))
fi
if [ "$(printf '%s' "$out" | wc -l)" -gt 1 ]; then
  echo "ok   - output is multi-line (pretty-printed, not minified)"
  pass=$((pass + 1))
else
  echo "FAIL - output is multi-line (pretty-printed, not minified)"
  fail=$((fail + 1))
fi

# Valid JSON via --file.
echo '{"x": true, "y": null}' > "${TMP_DIR}/valid.json"
assert_exit_code "valid JSON via --file exits 0" 0 "$SCRIPT" --file "${TMP_DIR}/valid.json"

# Invalid JSON is rejected.
assert_exit_code "invalid JSON on stdin exits non-zero" 1 bash -c "printf '{bad json' | '$SCRIPT'"
assert_output_contains "invalid JSON reports an error" "Invalid JSON" bash -c "printf '{bad json' | '$SCRIPT'"

echo '{not valid' > "${TMP_DIR}/invalid.json"
assert_exit_code "invalid JSON via --file exits non-zero" 1 "$SCRIPT" --file "${TMP_DIR}/invalid.json"

echo
echo "Passed: $pass  Failed: $fail"
[ "$fail" -eq 0 ]
