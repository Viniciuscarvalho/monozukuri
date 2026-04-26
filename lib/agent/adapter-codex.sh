#!/bin/bash
# lib/agent/adapter-codex.sh — OpenAI Codex CLI adapter.
#
# Required env vars (set by pipeline.sh before calling agent_run_phase):
#   MONOZUKURI_FEATURE_ID   feature being processed
#   MONOZUKURI_WORKTREE     absolute path to the feature worktree
#   MONOZUKURI_AUTONOMY     supervised | checkpoint | full_auto
#   MONOZUKURI_LOG_FILE     where to tee codex output (optional)
#
# Auth: OPENAI_API_KEY must be set in environment.

agent_name() { echo "codex"; }

agent_capabilities() {
  printf '%s\n' '{
  "agent": "codex",
  "supports": {
    "phases":         ["prd","techspec","tasks","code","tests","pr"],
    "skills":         false,
    "native_edit":    true,
    "shell_access":   true,
    "mcp":            false,
    "streaming":      true,
    "token_counting": "approximate",
    "approval_modes": ["suggest","auto-edit"]
  },
  "models": {
    "aliases": {
      "default": "gpt-5",
      "mini":    "gpt-5-mini"
    },
    "default": "gpt-5"
  },
  "auth": {
    "methods": ["api_key:OPENAI_API_KEY"],
    "verify":  "codex --version"
  }
}'
}

agent_doctor() {
  if ! command -v codex &>/dev/null; then
    printf 'codex CLI not found. Install: npm install -g @openai/codex\n' >&2
    return 1
  fi
  if [ -z "${OPENAI_API_KEY:-}" ]; then
    printf 'OPENAI_API_KEY not set. Add it to .env\n' >&2
    return 1
  fi
  return 0
}

agent_estimate_tokens() {
  local prompt; prompt=$(cat)
  if declare -f cost_estimate_tokens &>/dev/null; then
    cost_estimate_tokens "$prompt"
  else
    printf '%d\n' $(( ${#prompt} / 4 ))
  fi
}

agent_run_phase() {
  local feat_id="${MONOZUKURI_FEATURE_ID:?agent_run_phase: MONOZUKURI_FEATURE_ID not set}"
  local wt_path="${MONOZUKURI_WORKTREE:?agent_run_phase: MONOZUKURI_WORKTREE not set}"
  local log_file="${MONOZUKURI_LOG_FILE:-/tmp/monozukuri-${feat_id}-$(date +%s).log}"

  # Map autonomy to codex approval mode
  local approval_mode
  case "${MONOZUKURI_AUTONOMY:-checkpoint}" in
    full_auto)  approval_mode="auto-edit" ;;
    *)          approval_mode="suggest" ;;
  esac

  local rendered_prompt
  if declare -f render_phase_prompt &>/dev/null; then
    rendered_prompt=$(render_phase_prompt "${MONOZUKURI_PHASE:-prd}")
  else
    rendered_prompt="Implement feature ${feat_id}."
  fi

  (cd "$wt_path" && printf '%s\n' "$rendered_prompt" | \
    codex \
      --approval-mode "$approval_mode" \
      ${MONOZUKURI_MODEL:+--model "$MONOZUKURI_MODEL"} \
      -) 2>&1 | tee "$log_file"
}

agent_report_cost() {
  if declare -f cost_report &>/dev/null; then
    cost_report
  else
    echo "0.00"
  fi
}

agent_native_context_files() {
  printf '%s\n' '["AGENTS.md"]'
}
