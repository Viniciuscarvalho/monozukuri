#!/bin/bash
# lib/agent/adapter-codex.sh — OpenAI Codex CLI adapter.
#
# Required env vars (set by pipeline.sh before calling agent_run_phase):
#   MONOZUKURI_FEATURE_ID   feature being processed
#   MONOZUKURI_WORKTREE     absolute path to the feature worktree
#   MONOZUKURI_AUTONOMY     supervised | checkpoint | full_auto
#   MONOZUKURI_LOG_FILE     where to tee codex output (optional)
#
# Auth: codex CLI must be logged in (run: codex login).

# op_timeout is sourced from lib/core/util.sh by pipeline.sh before this adapter loads.
# Provide a no-op passthrough for environments that source this adapter directly (e.g. tests).
if ! declare -f op_timeout &>/dev/null; then
  op_timeout() { local _secs="$1"; shift; "$@"; }
fi

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
    "methods": ["oauth:openai-account"],
    "verify":  "codex --version && codex login status"
  }
}'
}

agent_doctor() {
  if ! command -v codex &>/dev/null; then
    printf 'codex CLI not found. Install: npm install -g @openai/codex\n' >&2
    return 1
  fi
  if ! codex login status >/dev/null 2>&1; then
    printf 'codex not authenticated. Run: codex login\n' >&2
    return 1
  fi
  return 0
}

agent_login_hint() { printf 'codex login\n'; }

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

  # fix-retry: Phase 3 Ralph Loop — feed MONOZUKURI_FIX_CONTEXT directly to codex.
  if [[ "${MONOZUKURI_PHASE:-}" == "fix-retry" ]]; then
    local fix_context="${MONOZUKURI_FIX_CONTEXT:-Fix the failing tests.}"
    local exit_code=0
    (
      set -o pipefail
      cd "$wt_path" && printf '%s\n' "$fix_context" | \
        op_timeout "${SKILL_TIMEOUT_SECONDS:-1800}" \
          codex \
            --approval-mode "$approval_mode" \
            ${MONOZUKURI_MODEL:+--model "$MONOZUKURI_MODEL"} \
            - 2>&1 | tee "$log_file"
    ) || exit_code=$?
    _codex_auth_expired "$log_file" && return 15
    return "$exit_code"
  fi

  local rendered_prompt
  if declare -f render_phase_prompt &>/dev/null; then
    rendered_prompt=$(render_phase_prompt "${MONOZUKURI_PHASE:-prd}")
  else
    rendered_prompt="Implement feature ${feat_id}."
  fi

  local exit_code=0
  (cd "$wt_path" && printf '%s\n' "$rendered_prompt" | \
    op_timeout "${SKILL_TIMEOUT_SECONDS:-1800}" \
      codex \
        --approval-mode "$approval_mode" \
        ${MONOZUKURI_MODEL:+--model "$MONOZUKURI_MODEL"} \
        -) 2>&1 | tee "$log_file" || exit_code=$?
  _codex_auth_expired "$log_file" && return 15
  return "$exit_code"
}

# _codex_auth_expired <log_file>
# Returns 0 (true) if the log contains a codex auth-failure marker.
# Used to distinguish auth expiry (exit 15) from ordinary phase failures.
_codex_auth_expired() {
  grep -qiE \
    "please run codex login|not authenticated|authentication required|invalid api key|session expired|please log in|token.*expired|unauthorized" \
    "${1:-}" 2>/dev/null
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
