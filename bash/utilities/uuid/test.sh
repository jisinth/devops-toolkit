#!/usr/bin/env bash
#
# test.sh — checks for uuid.sh. Run: ./test.sh

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SCRIPT="${SCRIPT_DIR}/uuid.sh"
TMP_DIR="$(mktemp -d)"
trap 'rm -rf "$TMP_DIR"' EXIT

UUID_V4_RE='^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$'

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
assert_output_contains "usage mentions --count" "--count" "$SCRIPT" --help

assert_exit_code "unknown option exits non-zero" 1 "$SCRIPT" --bogus
assert_output_contains "unknown option is reported" "Unknown option" "$SCRIPT" --bogus

assert_exit_code "non-numeric --count exits non-zero" 1 "$SCRIPT" --count abc
assert_exit_code "zero --count exits non-zero" 1 "$SCRIPT" --count 0

# Default: exactly one UUID, matches UUIDv4 format.
out="$("$SCRIPT")"
n="$(printf '%s\n' "$out" | grep -c .)"
if [ "$n" -eq 1 ]; then
  echo "ok   - default generates exactly 1 UUID"
  pass=$((pass + 1))
else
  echo "FAIL - default generates exactly 1 UUID (got $n)"
  fail=$((fail + 1))
fi
if printf '%s' "$out" | grep -qiE "$UUID_V4_RE"; then
  echo "ok   - default output matches UUIDv4 format"
  pass=$((pass + 1))
else
  echo "FAIL - default output matches UUIDv4 format (got: $out)"
  fail=$((fail + 1))
fi

# --count N generates exactly N UUIDs, all valid v4.
out="$("$SCRIPT" --count 10)"
n="$(printf '%s\n' "$out" | grep -c .)"
if [ "$n" -eq 10 ]; then
  echo "ok   - --count 10 generates exactly 10 UUIDs"
  pass=$((pass + 1))
else
  echo "FAIL - --count 10 generates exactly 10 UUIDs (got $n)"
  fail=$((fail + 1))
fi
matched="$(printf '%s\n' "$out" | grep -icE "$UUID_V4_RE" || true)"
if [ "$matched" -eq 10 ]; then
  echo "ok   - all 10 generated UUIDs match the UUIDv4 format"
  pass=$((pass + 1))
else
  echo "FAIL - all 10 generated UUIDs match the UUIDv4 format (only $matched/10 matched)"
  echo "$out"
  fail=$((fail + 1))
fi

# --upper produces uppercase hex, no lowercase letters.
out="$("$SCRIPT" --upper)"
if printf '%s' "$out" | grep -qE '^[0-9A-F-]+$'; then
  echo "ok   - --upper produces uppercase output"
  pass=$((pass + 1))
else
  echo "FAIL - --upper produces uppercase output (got: $out)"
  fail=$((fail + 1))
fi

# --no-dashes strips dashes and yields a 32-char hex string.
out="$("$SCRIPT" --no-dashes)"
if ! printf '%s' "$out" | grep -q '-' && [ "${#out}" -eq 32 ]; then
  echo "ok   - --no-dashes strips dashes and yields 32 hex chars"
  pass=$((pass + 1))
else
  echo "FAIL - --no-dashes strips dashes and yields 32 hex chars (got: '$out', len ${#out})"
  fail=$((fail + 1))
fi

# --upper --no-dashes combined.
out="$("$SCRIPT" --upper --no-dashes)"
if printf '%s' "$out" | grep -qE '^[0-9A-F]{32}$'; then
  echo "ok   - --upper --no-dashes yields 32 uppercase hex chars"
  pass=$((pass + 1))
else
  echo "FAIL - --upper --no-dashes yields 32 uppercase hex chars (got: '$out')"
  fail=$((fail + 1))
fi

# Consecutive UUIDs are not identical (basic randomness sanity check).
u1="$("$SCRIPT")"
u2="$("$SCRIPT")"
if [ "$u1" != "$u2" ]; then
  echo "ok   - consecutive invocations produce different UUIDs"
  pass=$((pass + 1))
else
  echo "FAIL - consecutive invocations produce different UUIDs (both: $u1)"
  fail=$((fail + 1))
fi

echo
echo "Passed: $pass  Failed: $fail"
[ "$fail" -eq 0 ]
