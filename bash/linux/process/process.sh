#!/usr/bin/env bash
#
# process.sh — list/report processes, with a focus on finding and (with
# --fix) reaping zombie/defunct processes.
#
# Usage: ./process.sh [options]
# Run with --help for full usage.

set -euo pipefail

SCRIPT_NAME="$(basename "$0")"

ZOMBIE_ONLY=false
FIX=false
ASSUME_YES=false
FILTER_USER=""
FILTER_NAME=""

usage() {
  cat <<EOF
Usage: ${SCRIPT_NAME} [options]

List processes (ps-based). With --zombie, only list zombie/defunct
processes. With --fix, attempt to reap zombies by sending SIGCHLD-inducing
signals to (or, if unresponsive, killing) their parent process.

Options:
  --zombie        Only list zombie/defunct processes
  --fix           Attempt to reap zombie processes found (requires --zombie)
  -y, --yes       Do not prompt for confirmation before --fix acts
  --user NAME     Only show processes owned by this user
  --name PATTERN  Only show processes whose command matches this pattern
  -h, --help      Show this help message and exit

Examples:
  ${SCRIPT_NAME}
  ${SCRIPT_NAME} --user www-data
  ${SCRIPT_NAME} --zombie --fix -y

Notes:
  A zombie process itself cannot be killed (it's already dead and waiting
  to be reaped) — --fix works by signaling its parent process, which
  should then reap it. If the parent ignores SIGCHLD, the zombie may
  persist until the parent exits.
EOF
}

log()  { printf '[process] %s\n' "$*"; }
err()  { printf '[process] ERROR: %s\n' "$*" >&2; }

confirm() {
  local prompt="$1"
  if [ "$ASSUME_YES" = true ]; then
    return 0
  fi
  read -r -p "${prompt} [y/N] " reply
  case "$reply" in
    [yY][eE][sS]|[yY]) return 0 ;;
    *) return 1 ;;
  esac
}

while [ "$#" -gt 0 ]; do
  case "$1" in
    --zombie) ZOMBIE_ONLY=true ;;
    --fix) FIX=true ;;
    -y|--yes) ASSUME_YES=true ;;
    --user)
      [ "$#" -ge 2 ] || { err "--user requires a value"; exit 1; }
      FILTER_USER="$2"
      shift
      ;;
    --name)
      [ "$#" -ge 2 ] || { err "--name requires a value"; exit 1; }
      FILTER_NAME="$2"
      shift
      ;;
    -h|--help) usage; exit 0 ;;
    *)
      err "Unknown option: $1"
      usage
      exit 1
      ;;
  esac
  shift
done

if [ "$FIX" = true ] && [ "$ZOMBIE_ONLY" = false ]; then
  err "--fix requires --zombie."
  exit 1
fi

if ! command -v ps >/dev/null 2>&1; then
  err "required command not found: ps"
  exit 1
fi

if [ "$ZOMBIE_ONLY" = true ]; then
  log "Zombie/defunct processes:"
  header="  PID  PPID USER     COMMAND"
  echo "$header"

  zombie_pids=()
  zombie_ppids=()

  while read -r pid ppid state user comm; do
    case "$state" in Z*) ;; *) continue ;; esac
    [ -n "$FILTER_USER" ] && [ "$user" != "$FILTER_USER" ] && continue
    [ -n "$FILTER_NAME" ] && ! printf '%s' "$comm" | grep -q -- "$FILTER_NAME" && continue
    printf '%5s %5s %-8s %s\n' "$pid" "$ppid" "$user" "$comm"
    zombie_pids+=("$pid")
    zombie_ppids+=("$ppid")
  done < <(ps -eo pid=,ppid=,stat=,user=,comm= 2>/dev/null)

  if [ "${#zombie_pids[@]}" -eq 0 ]; then
    log "No zombie processes found."
    exit 0
  fi

  log "${#zombie_pids[@]} zombie process(es) found."

  if [ "$FIX" = true ]; then
    if confirm "Send SIGCHLD to ${#zombie_ppids[@]} parent process(es) to reap zombies?"; then
      declare -A seen_ppids
      for ppid in "${zombie_ppids[@]}"; do
        [ -n "${seen_ppids[$ppid]:-}" ] && continue
        seen_ppids["$ppid"]=1
        log "Sending SIGCHLD to parent PID ${ppid}"
        kill -CHLD "$ppid" 2>/dev/null || err "Failed to signal PID ${ppid} (already gone, or insufficient permission)"
      done
    else
      log "Skipping --fix (not confirmed)."
    fi
  fi
else
  log "Process list:"
  ps_args=(-eo "pid=,ppid=,%cpu=,%mem=,user=,comm=")
  if ! ps "${ps_args[@]}" >/dev/null 2>&1; then
    err "'ps -eo ...' is not supported on this system."
    exit 1
  fi
  printf '%5s %5s %6s %6s %-10s %s\n' "PID" "PPID" "%CPU" "%MEM" "USER" "COMMAND"
  while read -r pid ppid cpu mem user comm; do
    [ -n "$FILTER_USER" ] && [ "$user" != "$FILTER_USER" ] && continue
    [ -n "$FILTER_NAME" ] && ! printf '%s' "$comm" | grep -q -- "$FILTER_NAME" && continue
    printf '%5s %5s %6s %6s %-10s %s\n' "$pid" "$ppid" "$cpu" "$mem" "$user" "$comm"
  done < <(ps "${ps_args[@]}" 2>/dev/null)
fi
