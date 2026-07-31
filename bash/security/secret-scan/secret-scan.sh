#!/usr/bin/env bash
#
# secret-scan.sh — recursively scan a directory for likely hardcoded secrets
# using a curated set of regex patterns (AWS keys, private key headers,
# generic password/token/api_key assignments, Slack tokens, etc).
#
# Usage: ./secret-scan.sh [options]
# Run with --help for full usage.

set -euo pipefail

SCRIPT_NAME="$(basename "$0")"

SCAN_PATH="."
EXCLUDES=(".git")

usage() {
  cat <<EOF
Usage: ${SCRIPT_NAME} [options]

Recursively scan a directory for strings that look like hardcoded secrets,
using a curated set of regex patterns. This is a lightweight heuristic
scanner for auditing your own code — see README.md for its limits.

Options:
  --path <dir>          Directory to scan (default: .)
  --exclude <pattern>   Path substring/pattern to skip; repeatable
                         (default excludes: .git)
  -h, --help            Show this help message and exit

Examples:
  ${SCRIPT_NAME} --path ./src
  ${SCRIPT_NAME} --path . --exclude node_modules --exclude vendor

Output:
  file:line: <pattern-name>: <matched line, truncated>
EOF
}

log()  { printf '[secret-scan] %s\n' "$*"; }
err()  { printf '[secret-scan] ERROR: %s\n' "$*" >&2; }

while [ "$#" -gt 0 ]; do
  case "$1" in
    --path)
      [ "$#" -ge 2 ] || { err "--path requires a value"; exit 1; }
      SCAN_PATH="$2"
      shift 2
      ;;
    --exclude)
      [ "$#" -ge 2 ] || { err "--exclude requires a value"; exit 1; }
      EXCLUDES+=("$2")
      shift 2
      ;;
    -h|--help) usage; exit 0 ;;
    *)
      err "Unknown option: $1"
      usage
      exit 1
      ;;
  esac
done

if [ ! -d "$SCAN_PATH" ]; then
  err "Path not found or not a directory: $SCAN_PATH"
  exit 1
fi

# Pattern name / regex pairs (extended regex, case-insensitive where useful).
PATTERN_NAMES=(
  "AWS Access Key ID"
  "AWS Secret Access Key (assignment)"
  "Private Key Header"
  "Generic Password Assignment"
  "Generic Secret Assignment"
  "Generic Token Assignment"
  "Generic API Key Assignment"
  "Slack Token"
  "GitHub Token"
  "Generic Bearer Token"
)
# Matched case-insensitively (grep -Ei), so mixed case is not an issue here.
PATTERN_REGEXES=(
  '(A3T[A-Z0-9]|AKIA|AGPA|AIDA|AROA|AIPA|ANPA|ANVA|ASIA)[A-Z0-9]{16}'
  'aws_secret_access_key[[:space:]]*[:=][[:space:]]*["'"'"'][A-Za-z0-9/+=]{30,}["'"'"']'
  '-----BEGIN[A-Z ]*PRIVATE KEY-----'
  '(password|passwd|pwd)[[:space:]]*[:=][[:space:]]*["'"'"'][^"'"'"']{3,}["'"'"']'
  'secret[[:space:]]*[:=][[:space:]]*["'"'"'][^"'"'"']{3,}["'"'"']'
  '(auth_)?token[[:space:]]*[:=][[:space:]]*["'"'"'][^"'"'"']{6,}["'"'"']'
  'api[_-]?key[[:space:]]*[:=][[:space:]]*["'"'"'][^"'"'"']{6,}["'"'"']'
  'xox[baprs]-[A-Za-z0-9-]{10,}'
  '(ghp|gho|ghu|ghs|ghr|github_pat)_[A-Za-z0-9_]{20,}'
  'bearer[[:space:]]+[A-Za-z0-9._-]{16,}'
)

build_grep_excludes() {
  local -n arr_ref=$1
  arr_ref=()
  for pat in "${EXCLUDES[@]}"; do
    arr_ref+=(--exclude-dir="$pat" --exclude="$pat")
  done
}

grep_exclude_args=()
build_grep_excludes grep_exclude_args

# Extended regex (-E) is sufficient for all patterns here (no lookaround
# needed), and is more portable than PCRE (-P) across grep builds.
GREP_MODE="-E"

matches_found=0
files_scanned=0

# Build a list of files to scan, honoring excludes as path-substring filters
# (handles both grep --exclude-dir support and manual filtering as fallback).
while IFS= read -r -d '' file; do
  skip=false
  for pat in "${EXCLUDES[@]}"; do
    case "$file" in
      *"$pat"*) skip=true; break ;;
    esac
  done
  [ "$skip" = true ] && continue

  files_scanned=$((files_scanned + 1))

  # Skip binary files.
  if LC_ALL=C grep -qI '' "$file" 2>/dev/null; then
    :
  else
    continue
  fi

  for i in "${!PATTERN_REGEXES[@]}"; do
    name="${PATTERN_NAMES[$i]}"
    regex="${PATTERN_REGEXES[$i]}"
    while IFS=: read -r lineno content; do
      [ -z "$lineno" ] && continue
      trimmed="$(printf '%s' "$content" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')"
      if [ "${#trimmed}" -gt 120 ]; then
        trimmed="${trimmed:0:120}..."
      fi
      printf '%s:%s: %s: %s\n' "$file" "$lineno" "$name" "$trimmed"
      matches_found=$((matches_found + 1))
    done < <(grep -n -i $GREP_MODE -- "$regex" "$file" 2>/dev/null || true)
  done
done < <(find "$SCAN_PATH" -type f -print0)

log "Scanned $files_scanned file(s) under '$SCAN_PATH'."
if [ "$matches_found" -eq 0 ]; then
  log "No likely secrets found."
  exit 0
else
  log "Found $matches_found potential secret(s). Review each match above."
  exit 0
fi
