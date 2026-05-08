#!/bin/bash
# lib/agent/adapter-codex.sh — OpenAI Codex CLI adapter manifest.
#
# Required env vars (set by pipeline.sh before calling agent_run_phase):
#   MONOZUKURI_FEATURE_ID   feature being processed
#   MONOZUKURI_WORKTREE     absolute path to the feature worktree
#   MONOZUKURI_AUTONOMY     supervised | checkpoint | full_auto
#   MONOZUKURI_LOG_FILE     where to tee codex output (optional)
#
# Auth: codex CLI must be logged in (run: codex login).

_ADAPTER_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=thin-shell-base.sh
source "${_ADAPTER_DIR}/thin-shell-base.sh"

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

_thin_shell_invoke() {
  local prompt="$1" log_file="$2" _feat_id="$3" wt_path="$4"
  local approval_mode
  case "${MONOZUKURI_AUTONOMY:-checkpoint}" in
    full_auto)  approval_mode="auto-edit" ;;
    *)          approval_mode="suggest" ;;
  esac
  (cd "$wt_path" && printf '%s\n' "$prompt" | \
    adapter_tee "$log_file" -- \
      op_timeout "${SKILL_TIMEOUT_SECONDS:-1800}" \
        codex \
          --approval-mode "$approval_mode" \
          ${MONOZUKURI_MODEL:+--model "$MONOZUKURI_MODEL"} \
          -)
}

_thin_shell_auth_check() {
  grep -qiE \
    "please run codex login|not authenticated|authentication required|invalid api key|session expired|please log in|token.*expired|unauthorized" \
    "${1:-}" 2>/dev/null
}

agent_native_context_files() {
  printf '%s\n' '["AGENTS.md"]'
}
