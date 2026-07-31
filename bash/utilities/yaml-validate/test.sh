#!/usr/bin/env bash
#
# test.sh — checks for yaml-validate.sh. Run: ./test.sh

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SCRIPT="${SCRIPT_DIR}/yaml-validate.sh"
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
assert_output_contains "usage mentions stdin" "stdin" "$SCRIPT" --help

assert_exit_code "unknown option exits non-zero" 1 "$SCRIPT" --bogus
assert_output_contains "unknown option is reported" "Unknown option" "$SCRIPT" --bogus

printf 'a: 1\nb:\n  - 1\n  - 2\nc:\n  nested: true\n' > "${TMP_DIR}/good.yaml"
printf 'a: [1, 2\nb: {\n' > "${TMP_DIR}/bad.yaml"

assert_exit_code "valid file exits 0" 0 "$SCRIPT" "${TMP_DIR}/good.yaml"
assert_output_contains "valid file reports PASS" "PASS - ${TMP_DIR}/good.yaml" "$SCRIPT" "${TMP_DIR}/good.yaml"

assert_exit_code "invalid file exits non-zero" 1 "$SCRIPT" "${TMP_DIR}/bad.yaml"
assert_output_contains "invalid file reports FAIL" "FAIL - ${TMP_DIR}/bad.yaml" "$SCRIPT" "${TMP_DIR}/bad.yaml"

assert_exit_code "one bad file among several fails overall" 1 "$SCRIPT" "${TMP_DIR}/good.yaml" "${TMP_DIR}/bad.yaml"

assert_exit_code "missing file exits non-zero" 1 "$SCRIPT" "${TMP_DIR}/does-not-exist.yaml"
assert_output_contains "missing file is reported" "file not found" "$SCRIPT" "${TMP_DIR}/does-not-exist.yaml"

assert_exit_code "valid document on stdin exits 0" 0 bash -c "printf 'x: y\\n' | '$SCRIPT'"
assert_output_contains "valid stdin reports PASS - stdin" "PASS - stdin" bash -c "printf 'x: y\\n' | '$SCRIPT'"

assert_exit_code "invalid document on stdin exits non-zero" 1 bash -c "printf 'a: [1, 2\\nb: {\\n' | '$SCRIPT'"
assert_output_contains "invalid stdin reports FAIL - stdin" "FAIL - stdin" bash -c "printf 'a: [1, 2\\nb: {\\n' | '$SCRIPT'"

echo
echo "Passed: $pass  Failed: $fail"
[ "$fail" -eq 0 ]
