#!/usr/bin/env bash
#
# test.sh — basic checks for secret-scan.sh. Run: ./test.sh

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SCRIPT="${SCRIPT_DIR}/secret-scan.sh"

pass=0
fail=0

assert_exit_code() {
  local desc="$1" expected="$2"; shift 2
  local actual=0
  "$@" >/tmp/secret-scan-test.out 2>&1 || actual=$?
  if [ "$actual" -eq "$expected" ]; then
    echo "ok   - $desc"
    pass=$((pass + 1))
  else
    echo "FAIL - $desc (expected exit $expected, got $actual)"
    cat /tmp/secret-scan-test.out
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

assert_output_not_contains() {
  local desc="$1" needle="$2"; shift 2
  local out
  out="$("$@" 2>&1 || true)"
  if printf '%s' "$out" | grep -qF -- "$needle"; then
    echo "FAIL - $desc (expected output NOT to contain: $needle)"
    echo "$out"
    fail=$((fail + 1))
  else
    echo "ok   - $desc"
    pass=$((pass + 1))
  fi
}

assert_exit_code "no args exits 0 (scans cwd)" 0 "$SCRIPT" --path "$SCRIPT_DIR"
assert_exit_code "--help exits 0" 0 "$SCRIPT" --help
assert_exit_code "unknown option exits non-zero" 1 "$SCRIPT" --bogus
assert_exit_code "missing path exits non-zero" 1 "$SCRIPT" --path /no/such/dir/xyz

assert_output_contains "usage mentions --path" "--path" "$SCRIPT" --help
assert_output_contains "usage mentions --exclude" "--exclude" "$SCRIPT" --help
assert_output_contains "unknown option is reported" "Unknown option" "$SCRIPT" --bogus

# Integration: a temp dir with a fake secret and a clean file.
TMPDIR_TEST="$(mktemp -d)"
cleanup() { rm -rf "$TMPDIR_TEST"; }
trap cleanup EXIT

cat >"${TMPDIR_TEST}/secret.txt" <<'EOF'
aws_access_key = "AKIAABCDEFGHIJKLMNOP"
api_key = "sk_test_totally_fake_1234567890"
EOF

cat >"${TMPDIR_TEST}/clean.txt" <<'EOF'
This file just contains ordinary prose about deployments and has no secrets.
EOF

out="$("$SCRIPT" --path "$TMPDIR_TEST" 2>&1)"

if printf '%s' "$out" | grep -qF "secret.txt"; then
  echo "ok   - flags the file containing a fake secret"
  pass=$((pass + 1))
else
  echo "FAIL - did not flag secret.txt"
  echo "$out"
  fail=$((fail + 1))
fi

if printf '%s' "$out" | grep -qF "AWS Access Key ID"; then
  echo "ok   - identifies the AWS Access Key ID pattern"
  pass=$((pass + 1))
else
  echo "FAIL - did not identify AWS Access Key ID pattern"
  echo "$out"
  fail=$((fail + 1))
fi

if printf '%s' "$out" | grep -qF "clean.txt"; then
  echo "FAIL - incorrectly flagged clean.txt"
  echo "$out"
  fail=$((fail + 1))
else
  echo "ok   - does not flag the clean file"
  pass=$((pass + 1))
fi

echo
echo "Passed: $pass  Failed: $fail"
[ "$fail" -eq 0 ]
