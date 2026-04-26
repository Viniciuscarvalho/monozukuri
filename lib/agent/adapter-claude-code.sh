#!/bin/bash
# lib/agent/adapter-claude-code.sh — Claude Code reference adapter.
#
# Wraps the existing "claude --agent <skill> -p <project>" invocation
# behind the six-function adapter contract. Existing users see no behavior
# change; the SKILL_COMMAND env var continues to select the Claude Code skill.
#
# Required env vars (set by pipeline.sh before calling agent_run_phase):
#   MONOZUKURI_FEATURE_ID   feature being processed
#   MONOZUKURI_WORKTREE     absolute path to the feature worktree
#   MONOZUKURI_AUTONOMY     supervised | checkpoint | full_auto
#   MONOZUKURI_MODEL        model alias (optional; empty = config default)
#   MONOZUKURI_LOG_FILE     where to tee claude output (optional)
#   SKILL_COMMAND           which Claude Code skill to invoke (default: feature-marker)

agent_name() { echo "claude-code"; }

agent_capabilities() {
  printf '%s\n' '{
  "agent": "claude-code",
  "supports": {
    "phases":         ["prd","techspec","tasks","code","tests","pr"],
    "skills":         true,
    "native_edit":    true,
    "shell_access":   true,
    "mcp":            true,
    "streaming":      true,
    "token_counting": "exact",
    "approval_modes": ["read-only","auto-edit","full-access"]
  },
  "models": {
    "aliases": {
      "opus":     "claude-opus-4-7",
      "sonnet":   "claude-sonnet-4-6",
      "haiku":    "claude-haiku-4-5",
      "opusplan": "{plan:opus,code:sonnet}"
    },
    "default": "opusplan"
  },
  "auth": {
    "methods": ["api_key:ANTHROPIC_API_KEY", "oauth:claude.ai"],
    "verify":  "claude --version && claude auth status"
  }
}'
}

agent_doctor() {
  if ! command -v claude &>/dev/null; then
    printf 'claude CLI not found. Install: https://claude.ai/code\n' >&2
    return 1
  fi
  if ! claude auth status >/dev/null 2>&1; then
    printf 'claude not authenticated. Run: claude login\n' >&2
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

  local skill_arg="${SKILL_COMMAND:-feature-marker}"
  local effective_model="${MONOZUKURI_MODEL:-}"
  [ "$effective_model" = "opusplan" ] && effective_model="opus"

  local perm_flag=""
  [ "${MONOZUKURI_AUTONOMY:-}" = "full_auto" ] && perm_flag="--permission-mode bypassPermissions"

  local interactive_flag=""
  [ "${MONOZUKURI_AUTONOMY:-}" = "supervised" ] && interactive_flag="--interactive"

  (cd "$wt_path" && platform_claude "${SKILL_TIMEOUT_SECONDS:-1800}" \
    ${effective_model:+--model "$effective_model"} \
    --agent "$skill_arg" \
    $perm_flag \
    ${interactive_flag:+$interactive_flag} \
    -p "prd-$feat_id") 2>&1 | tee "$log_file"
}

agent_report_cost() {
  if declare -f cost_report &>/dev/null; then
    cost_report
  else
    echo "0.00"
  fi
}
