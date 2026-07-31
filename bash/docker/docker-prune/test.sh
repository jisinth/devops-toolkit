#!/usr/bin/env bash
#
# test.sh — basic checks for docker-prune.sh that don't require modifying
# any real Docker state. Run: ./test.sh

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SCRIPT="${SCRIPT_DIR}/docker-prune.sh"

pass=0
fail=0

assert_exit_code() {
  local desc="$1" expected="$2"; shift 2
  local actual=0
  "$@" >/tmp/docker-prune-test.out 2>&1 || actual=$?
  if [ "$actual" -eq "$expected" ]; then
    echo "ok   - $desc"
    pass=$((pass + 1))
  else
    echo "FAIL - $desc (expected exit $expected, got $actual)"
    cat /tmp/docker-prune-test.out
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

assert_output_contains "usage mentions --dry-run" "--dry-run" "$SCRIPT" --help
assert_output_contains "usage mentions -y/--yes" "--yes" "$SCRIPT" --help
assert_output_contains "unknown option is reported" "Unknown option" "$SCRIPT" --bogus

if command -v docker >/dev/null 2>&1 && docker info >/dev/null 2>&1; then
  assert_exit_code "--dry-run succeeds when Docker is available" 0 "$SCRIPT" --dry-run
  assert_output_contains "--dry-run makes no changes" "Dry run complete. No changes were made." "$SCRIPT" --dry-run
  assert_output_contains "--dry-run shows the command that would run" "would run: docker system prune -a --volumes --force" "$SCRIPT" --dry-run

  # No args: prompts for confirmation. With stdin closed, the prompt is
  # declined and the script exits non-zero without changing anything.
  actual=0
  "$SCRIPT" </dev/null >/tmp/docker-prune-test.out 2>&1 || actual=$?
  if [ "$actual" -ne 0 ]; then
    echo "ok   - declining confirmation aborts with non-zero exit"
    pass=$((pass + 1))
  else
    echo "FAIL - declining confirmation aborts with non-zero exit (got exit 0)"
    cat /tmp/docker-prune-test.out
    fail=$((fail + 1))
  fi
else
  echo "skip - Docker not available, skipping --dry-run integration checks"
fi

echo
echo "Passed: $pass  Failed: $fail"
[ "$fail" -eq 0 ]
