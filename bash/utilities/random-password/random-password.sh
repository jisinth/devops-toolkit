#!/usr/bin/env bash
#
# random-password.sh — generate one or more random passwords using
# /dev/urandom (never $RANDOM).
#
# Usage: ./random-password.sh [--count N] [--length N] [--charset TYPE] [--no-ambiguous]
# Run with --help for full usage.

set -euo pipefail

SCRIPT_NAME="$(basename "$0")"

COUNT=1
LENGTH=16
CHARSET="alnum-symbols"
NO_AMBIGUOUS=false

usage() {
  cat <<EOF
Usage: ${SCRIPT_NAME} [options]

Generate one or more random passwords, drawing randomness from
/dev/urandom.

Options:
  --count <N>          Number of passwords to generate (default: 1)
  --length <N>         Length of each password (default: 16)
  --charset <type>     'alnum' or 'alnum-symbols' (default: alnum-symbols)
  --no-ambiguous       Exclude visually-ambiguous characters (0 O o 1 l I |)
  -h, --help           Show this help message and exit

Examples:
  ${SCRIPT_NAME}
  ${SCRIPT_NAME} --count 5 --length 24
  ${SCRIPT_NAME} --charset alnum --no-ambiguous

Notes:
  Randomness is sourced from /dev/urandom with rejection sampling to avoid
  modulo bias; \$RANDOM is never used.
EOF
}

log()  { printf '[random-password] %s\n' "$*"; }
err()  { printf '[random-password] ERROR: %s\n' "$*" >&2; }

while [ "$#" -gt 0 ]; do
  case "$1" in
    --count)
      [ "$#" -ge 2 ] || { err "--count requires a value"; exit 1; }
      COUNT="$2"
      shift 2
      ;;
    --length)
      [ "$#" -ge 2 ] || { err "--length requires a value"; exit 1; }
      LENGTH="$2"
      shift 2
      ;;
    --charset)
      [ "$#" -ge 2 ] || { err "--charset requires a value"; exit 1; }
      CHARSET="$2"
      shift 2
      ;;
    --no-ambiguous) NO_AMBIGUOUS=true; shift ;;
    -h|--help) usage; exit 0 ;;
    *)
      err "Unknown option: $1"
      usage
      exit 1
      ;;
  esac
done

if ! [[ "$COUNT" =~ ^[0-9]+$ ]] || [ "$COUNT" -lt 1 ]; then
  err "--count must be a positive integer."
  exit 1
fi

if ! [[ "$LENGTH" =~ ^[0-9]+$ ]] || [ "$LENGTH" -lt 1 ]; then
  err "--length must be a positive integer."
  exit 1
fi

case "$CHARSET" in
  alnum) POOL="ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789" ;;
  alnum-symbols) POOL='ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789!@#$%^&*()-_=+[]{}<>?' ;;
  *)
    err "Invalid --charset: $CHARSET (expected 'alnum' or 'alnum-symbols')"
    exit 1
    ;;
esac

if [ "$NO_AMBIGUOUS" = true ]; then
  POOL="$(printf '%s' "$POOL" | tr -d '0O1lI|')"
fi

POOL_LEN=${#POOL}
if [ "$POOL_LEN" -eq 0 ]; then
  err "Character pool is empty after filtering."
  exit 1
fi

if [ ! -r /dev/urandom ]; then
  err "/dev/urandom is not available."
  exit 1
fi

read_random_bytes() {
  # Emit $1 random bytes, one decimal value per line.
  od -An -tu1 -N "$1" /dev/urandom | tr -s ' ' '\n' | sed '/^$/d'
}

generate_password() {
  local max=$(( (256 / POOL_LEN) * POOL_LEN ))
  local result=""
  local batch
  while [ "${#result}" -lt "$LENGTH" ]; do
    batch="$(read_random_bytes $(( (LENGTH - ${#result}) * 3 + 16 )))"
    while IFS= read -r byte; do
      [ "${#result}" -ge "$LENGTH" ] && break
      if [ "$byte" -lt "$max" ]; then
        result+="${POOL:$(( byte % POOL_LEN )):1}"
      fi
    done <<< "$batch"
  done
  printf '%s' "$result"
}

for ((i = 0; i < COUNT; i++)); do
  generate_password
  printf '\n'
done
