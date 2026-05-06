#!/bin/bash
# lib/cli/emit.sh — JSONL event emission for the Ink UI
# Source this file; call monozukuri_emit <type> [--arg key value ...]

MONOZUKURI_RUN_ID="${MONOZUKURI_RUN_ID:-}"

# adapter_tee <log_file> -- <cmd> [args...]
# Routes command stdout+stderr based on whether we're in event-stream mode:
#   MONOZUKURI_RUN_ID set → log file only (stdout is the JSONL event stream;
#                            raw agent text would corrupt it)
#   otherwise             → tee to log file (user sees output in terminal)
# Stdin is passed through to <cmd> unchanged.
# Returns the exit code of <cmd>.
adapter_tee() {
  local _log_file="$1"; shift
  [ "${1:-}" = "--" ] && shift
  if [ -n "${MONOZUKURI_RUN_ID:-}" ]; then
    "$@" > "$_log_file" 2>&1
  else
    "$@" 2>&1 | tee "$_log_file"
    return "${PIPESTATUS[0]}"
  fi
}

monozukuri_emit() {
  # Only emit when launched via Node dispatcher (MONOZUKURI_RUN_ID is set to a UUID).
  # Direct shell invocations leave it empty, so events don't leak to stdout.
  [ -n "${MONOZUKURI_RUN_ID:-}" ] || return 0
  local type="$1"; shift
  local jq_args=()
  while [ $# -ge 2 ]; do
    if [[ "$2" =~ ^-?[0-9]+$ ]]; then
      jq_args+=(--argjson "$1" "$2")
    else
      jq_args+=(--arg "$1" "$2")
    fi
    shift 2
  done
  jq -nc \
    --arg type "$type" \
    --arg ts "$(date -u +%Y-%m-%dT%H:%M:%SZ)" \
    --arg run_id "$MONOZUKURI_RUN_ID" \
    --arg agent "${MONOZUKURI_AGENT:-claude-code}" \
    "${jq_args[@]}" \
    '{type:$type,ts:$ts,run_id:$run_id,agent:$agent} + $ARGS.named' 2>/dev/null || true
}
