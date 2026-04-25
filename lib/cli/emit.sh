#!/bin/bash
# lib/cli/emit.sh — JSONL event emission for the Ink UI
# Source this file; call monozukuri_emit <type> [--arg key value ...]

MONOZUKURI_RUN_ID="${MONOZUKURI_RUN_ID:-}"

monozukuri_emit() {
  # Only emit when launched via Node dispatcher (MONOZUKURI_RUN_ID is set to a UUID).
  # Direct shell invocations leave it empty, so events don't leak to stdout.
  [ -n "${MONOZUKURI_RUN_ID:-}" ] || return 0
  local type="$1"; shift
  local jq_args=()
  while [ $# -ge 2 ]; do
    jq_args+=(--arg "$1" "$2")
    shift 2
  done
  jq -nc \
    --arg type "$type" \
    --arg ts "$(date -u +%Y-%m-%dT%H:%M:%SZ)" \
    --arg run_id "$MONOZUKURI_RUN_ID" \
    "${jq_args[@]}" \
    '{type:$type,ts:$ts,run_id:$run_id} + $ARGS.named' 2>/dev/null || true
}
