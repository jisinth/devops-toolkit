#!/usr/bin/env bash
#
# test.sh — basic checks for docker-logs.sh

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SCRIPT="${SCRIPT_DIR}/docker-logs.sh"

pass=0
fail=0

assert_exit_code() {
  local desc="$1" expected="$2"; shift 2
  local actual=0
  "$@" >/tmp/docker-logs-test.out 2>&1 || actual=$?
  if [ "$actual" -eq "$expected" ]; then
    echo "ok   - $desc"
    pass=$((pass + 1))
  else
    echo "FAIL - $desc (expected exit $expected, got $actual)"
    cat /tmp/docker-logs-test.out
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
assert_output_contains "usage mentions --output-dir" "--output-dir" "$SCRIPT" --help

if command -v docker >/dev/null 2>&1 && docker info >/dev/null 2>&1; then
  TMP_OUT="$(mktemp -d)"
  CID="$(docker run -d --rm alpine:latest sh -c 'echo hello-from-test; sleep 30')"
  trap 'docker rm -f "$CID" >/dev/null 2>&1 || true; rm -rf "$TMP_OUT"' EXIT
  sleep 1
  assert_exit_code "export logs for the test container" 0 "$SCRIPT" --container "$(docker inspect --format '{{.Name}}' "$CID" | sed 's#^/##')" --output-dir "$TMP_OUT"
  logfile="$(find "$TMP_OUT" -name '*.log.gz' | head -1)"
  if [ -n "$logfile" ] && gzip -t "$logfile" 2>/dev/null && zcat "$logfile" | grep -q "hello-from-test"; then
    echo "ok   - exported log file is valid and contains expected output"
    pass=$((pass + 1))
  else
    echo "FAIL - exported log file missing, corrupt, or missing expected content"
    fail=$((fail + 1))
  fi
else
  echo "skip - Docker not available, skipping functional checks"
fi

echo
echo "Passed: $pass  Failed: $fail"
[ "$fail" -eq 0 ]
