#!/usr/bin/env bash
#
# test.sh — checks for random-password.sh. Run: ./test.sh

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SCRIPT="${SCRIPT_DIR}/random-password.sh"
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
assert_output_contains "usage mentions --length" "--length" "$SCRIPT" --help

assert_exit_code "unknown option exits non-zero" 1 "$SCRIPT" --bogus
assert_output_contains "unknown option is reported" "Unknown option" "$SCRIPT" --bogus

assert_exit_code "non-numeric --count exits non-zero" 1 "$SCRIPT" --count abc
assert_exit_code "zero --length exits non-zero" 1 "$SCRIPT" --length 0
assert_exit_code "negative --length exits non-zero" 1 "$SCRIPT" --length -5
assert_exit_code "invalid --charset exits non-zero" 1 "$SCRIPT" --charset bogus
assert_output_contains "invalid --charset is reported" "Invalid --charset" "$SCRIPT" --charset bogus

# Default: exactly 1 password of length 16.
out="$("$SCRIPT")"
n="$(printf '%s\n' "$out" | grep -c .)"
if [ "$n" -eq 1 ] && [ "${#out}" -eq 16 ]; then
  echo "ok   - default generates 1 password of length 16"
  pass=$((pass + 1))
else
  echo "FAIL - default generates 1 password of length 16 (n=$n, len=${#out})"
  fail=$((fail + 1))
fi

# --count N --length M generates N passwords, each of length M.
out="$("$SCRIPT" --count 5 --length 24)"
n="$(printf '%s\n' "$out" | grep -c .)"
if [ "$n" -eq 5 ]; then
  echo "ok   - --count 5 generates exactly 5 passwords"
  pass=$((pass + 1))
else
  echo "FAIL - --count 5 generates exactly 5 passwords (got $n)"
  fail=$((fail + 1))
fi
bad_len=0
while IFS= read -r line; do
  [ "${#line}" -eq 24 ] || bad_len=$((bad_len + 1))
done <<< "$out"
if [ "$bad_len" -eq 0 ]; then
  echo "ok   - all generated passwords have length 24"
  pass=$((pass + 1))
else
  echo "FAIL - all generated passwords have length 24 ($bad_len line(s) wrong length)"
  echo "$out"
  fail=$((fail + 1))
fi

# --charset alnum produces only alphanumeric characters.
out="$("$SCRIPT" --charset alnum --length 40 --count 5)"
if printf '%s' "$out" | grep -qE '^[A-Za-z0-9[:space:]]+$'; then
  echo "ok   - --charset alnum produces only alphanumeric characters"
  pass=$((pass + 1))
else
  echo "FAIL - --charset alnum produces only alphanumeric characters"
  echo "$out"
  fail=$((fail + 1))
fi

# --no-ambiguous excludes 0 O o 1 l I |
out="$("$SCRIPT" --charset alnum --no-ambiguous --length 200 --count 5)"
if printf '%s' "$out" | grep -qE '[0O1lI|]'; then
  echo "FAIL - --no-ambiguous excludes 0 O o 1 l I |"
  fail=$((fail + 1))
else
  echo "ok   - --no-ambiguous excludes 0 O o 1 l I |"
  pass=$((pass + 1))
fi

# Consecutive passwords are not identical (basic randomness sanity check).
p1="$("$SCRIPT")"
p2="$("$SCRIPT")"
if [ "$p1" != "$p2" ]; then
  echo "ok   - consecutive invocations produce different passwords"
  pass=$((pass + 1))
else
  echo "FAIL - consecutive invocations produce different passwords (both: $p1)"
  fail=$((fail + 1))
fi

echo
echo "Passed: $pass  Failed: $fail"
[ "$fail" -eq 0 ]
