#!/bin/bash
# lib/run/measure.sh — Token measurement helpers for economics reporting.
#
# Writes JSONL records to .monozukuri/runs/<RUN_ID>/measurements.jsonl
# so economics_report can show per-run convention coordination stats.
#
# Public:
#   measure_tokens LABEL CONTENT   — record approximate token count for CONTENT
#   economics_report [RUN_ID]      — print convention coordination summary

# measure_tokens LABEL CONTENT
# Appends one JSONL record to the active run's measurements file.
# Silently no-ops when MANIFEST_RUN_ID is unset (e.g. during tests).
measure_tokens() {
  local label="${1:?measure_tokens: LABEL required}"
  local content="${2:-}"
  [[ -z "${MANIFEST_RUN_ID:-}" ]] && return 0
  [[ -z "${CONFIG_DIR:-}" ]] && return 0

  local run_dir="$CONFIG_DIR/runs/$MANIFEST_RUN_ID"
  mkdir -p "$run_dir" 2>/dev/null || return 0

  local tokens
  tokens=$(printf '%s' "$content" | wc -c | tr -d ' ')
  tokens=$(( tokens / 4 ))

  jq -nc \
    --arg  label  "$label" \
    --argjson tokens "$tokens" \
    --arg  ts    "$(date -u +%Y-%m-%dT%H:%M:%SZ 2>/dev/null || date +%Y-%m-%dT%H:%M:%SZ)" \
    '{label:$label, tokens:$tokens, ts:$ts}' \
    >> "$run_dir/measurements.jsonl" 2>/dev/null || true
}

# economics_report [RUN_ID]
# Prints a convention coordination summary for the given run (defaults to latest).
economics_report() {
  local run_id="${1:-}"
  local config_dir="${CONFIG_DIR:-${ROOT_DIR:-$(pwd)}/.monozukuri}"

  if [[ -z "$run_id" ]]; then
    # Find most-recent run with a measurements file
    run_id=$(find "$config_dir/runs" -name "measurements.jsonl" -maxdepth 2 2>/dev/null \
      | sort | tail -1 | xargs -I{} dirname {} | xargs basename 2>/dev/null || true)
  fi

  if [[ -z "$run_id" ]]; then
    printf 'No measurement data found. Run monozukuri with a project that has AGENTS.md.\n' >&2
    return 1
  fi

  local mfile="$config_dir/runs/$run_id/measurements.jsonl"
  if [[ ! -f "$mfile" ]]; then
    printf 'No measurements for run: %s\n' "$run_id" >&2
    return 1
  fi

  printf '\nConvention coordination — run: %s\n' "$run_id"
  printf '%s\n' "────────────────────────────────────────"

  local injected suppressed_label
  injected=$(jq -s '[.[] | select(.label == "conventions-injected") | .tokens] | add // 0' "$mfile")
  suppressed_label=$(jq -rs '[.[] | select(.label == "conventions-suppressed") | .label] | first // ""' "$mfile")

  local suppressed_count=0
  if [[ -n "$suppressed_label" ]]; then
    suppressed_count=$(jq -rs \
      '[.[] | select(.label == "conventions-suppressed") | .tokens] | add // 0' "$mfile")
  fi

  printf '  Injected convention tokens  : %s\n' "$injected"
  printf '  Suppressed (native to agent): %s conventions\n' "$suppressed_count"

  if [[ "$suppressed_count" -eq 0 && "$injected" -gt 0 ]]; then
    printf '\n  → Active adapter does not read AGENTS.md natively.\n'
    printf '    Consider: monozukuri conventions generate (PR3) to write CLAUDE.md.\n'
  elif [[ "$suppressed_count" -gt 0 ]]; then
    local saved=$(( suppressed_count * 50 ))
    printf '\n  → ~%s tokens saved this run via native-context suppression.\n' "$saved"
  fi
  printf '\n'
}
