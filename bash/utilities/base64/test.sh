#!/usr/bin/env bash
#
# test.sh — checks for base64.sh. Run: ./test.sh

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SCRIPT="${SCRIPT_DIR}/base64.sh"
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
assert_output_contains "usage mentions --encode" "--encode" "$SCRIPT" --help

assert_exit_code "unknown option exits non-zero" 1 "$SCRIPT" --bogus
assert_output_contains "unknown option is reported" "Unknown option" "$SCRIPT" --bogus

assert_exit_code "missing --encode/--decode exits non-zero" 1 "$SCRIPT" "hello"
assert_output_contains "missing mode is reported" "required" "$SCRIPT" "hello"

assert_exit_code "both --encode and --decode exits non-zero" 1 "$SCRIPT" --encode --decode "hello"
assert_output_contains "conflicting flags are reported" "mutually exclusive" "$SCRIPT" --encode --decode "hello"

assert_exit_code "-i and inline string together exits non-zero" 1 "$SCRIPT" --encode -i "${TMP_DIR}/x" "hello"

assert_exit_code "missing input file exits non-zero" 1 "$SCRIPT" --encode -i "${TMP_DIR}/does-not-exist.txt"

# Functional round trip: inline string.
original="hello world $(date +%s)"
encoded="$("$SCRIPT" --encode "$original")"
decoded="$("$SCRIPT" --decode "$encoded")"
if [ "$decoded" = "$original" ]; then
  echo "ok   - encode/decode round-trips an inline string"
  pass=$((pass + 1))
else
  echo "FAIL - encode/decode round-trips an inline string (got: '$decoded', expected: '$original')"
  fail=$((fail + 1))
fi

# Functional round trip: stdin.
encoded_stdin="$(printf '%s' "$original" | "$SCRIPT" --encode)"
decoded_stdin="$(printf '%s' "$encoded_stdin" | "$SCRIPT" --decode)"
if [ "$decoded_stdin" = "$original" ]; then
  echo "ok   - encode/decode round-trips via stdin"
  pass=$((pass + 1))
else
  echo "FAIL - encode/decode round-trips via stdin (got: '$decoded_stdin', expected: '$original')"
  fail=$((fail + 1))
fi

# Functional round trip: file input.
printf '%s' "$original" > "${TMP_DIR}/plain.txt"
"$SCRIPT" --encode -i "${TMP_DIR}/plain.txt" > "${TMP_DIR}/encoded.txt"
decoded_file="$("$SCRIPT" --decode -i "${TMP_DIR}/encoded.txt")"
if [ "$decoded_file" = "$original" ]; then
  echo "ok   - encode/decode round-trips via -i/--in-file"
  pass=$((pass + 1))
else
  echo "FAIL - encode/decode round-trips via -i/--in-file (got: '$decoded_file', expected: '$original')"
  fail=$((fail + 1))
fi

echo
echo "Passed: $pass  Failed: $fail"
[ "$fail" -eq 0 ]
