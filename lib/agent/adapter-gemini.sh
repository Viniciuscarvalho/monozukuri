#!/bin/bash
# lib/agent/adapter-gemini.sh — Google Gemini CLI adapter manifest.
#
# Required env vars (set by pipeline.sh before calling agent_run_phase):
#   MONOZUKURI_FEATURE_ID   feature being processed
#   MONOZUKURI_WORKTREE     absolute path to the feature worktree
#   MONOZUKURI_AUTONOMY     supervised | checkpoint | full_auto
#   MONOZUKURI_LOG_FILE     where to tee gemini output (optional)
#
# Auth: gemini CLI must be logged in (run: gemini auth login).

_ADAPTER_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=thin-shell-base.sh
source "${_ADAPTER_DIR}/thin-shell-base.sh"

agent_name() { echo "gemini"; }

agent_capabilities() {
  printf '%s\n' '{
  "agent": "gemini",
  "supports": {
    "phases":         ["prd","techspec","tasks","code","tests","pr"],
    "skills":         false,
    "native_edit":    true,
    "shell_access":   true,
    "mcp":            false,
    "streaming":      true,
    "token_counting": "approximate",
    "approval_modes": ["interactive","yolo"]
  },
  "models": {
    "aliases": {
      "default": "gemini-2.5-pro",
      "flash":   "gemini-2.5-flash"
    },
    "default": "gemini-2.5-pro"
  },
  "auth": {
    "methods": ["oauth:google-account"],
    "verify":  "gemini --version"
  }
}'
}

agent_doctor() {
  if ! command -v gemini &>/dev/null; then
    printf 'gemini CLI not found. Install: npm install -g @google/gemini-cli\n' >&2
    return 1
  fi
  local creds_file="${HOME}/.gemini/oauth_creds.json"
  if [ ! -s "$creds_file" ]; then
    printf 'gemini not authenticated. Run: gemini auth login\n' >&2
    return 1
  fi
  return 0
}

agent_login_hint() { printf 'gemini auth login\n'; }

_thin_shell_invoke() {
  local prompt="$1" log_file="$2" _feat_id="$3" wt_path="$4"
  local yolo_flag="false"
  [ "${MONOZUKURI_AUTONOMY:-checkpoint}" = "full_auto" ] && yolo_flag="true"
  (cd "$wt_path" && printf '%s\n' "$prompt" | \
    adapter_tee "$log_file" -- \
      op_timeout "${SKILL_TIMEOUT_SECONDS:-1800}" \
        gemini \
          --yolo "$yolo_flag" \
          ${MONOZUKURI_MODEL:+--model "$MONOZUKURI_MODEL"} \
          -)
}

_thin_shell_auth_check() {
  grep -qiE \
    "oauth token expired|unable to refresh credentials|authentication failed|invalid credentials|please authenticate|token.*revoked|access denied|401" \
    "${1:-}" 2>/dev/null
}

agent_native_context_files() {
  printf '%s\n' '["AGENTS.md", "GEMINI.md"]'
}
