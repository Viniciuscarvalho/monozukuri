#!/bin/bash
# lib/agent/adapter-kiro.sh — AWS Kiro adapter manifest.
#
# Required env vars (set by pipeline.sh before calling agent_run_phase):
#   MONOZUKURI_FEATURE_ID     feature being processed
#   MONOZUKURI_WORKTREE       absolute path to the feature worktree
#   MONOZUKURI_AUTONOMY       supervised | checkpoint | full_auto
#   MONOZUKURI_LOG_FILE       where to tee kiro output (optional)
#   MONOZUKURI_PHASE          current phase name
#
# Config: agents.kiro.use_native_specs (bool, default false) — when true,
# the prd and techspec phases delegate to `kiro spec create` instead of
# `kiro agent run` with a rendered prompt.
#
# Auth: AWS credentials via standard AWS SDK chain (env vars, ~/.aws/credentials,
# instance profile). Verified via `aws sts get-caller-identity`.

_ADAPTER_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=thin-shell-base.sh
source "${_ADAPTER_DIR}/thin-shell-base.sh"

agent_name() { echo "kiro"; }

agent_capabilities() {
  printf '%s\n' '{
  "agent": "kiro",
  "supports": {
    "phases":         ["prd","techspec","tasks","code","tests","pr"],
    "skills":         false,
    "native_edit":    true,
    "shell_access":   true,
    "mcp":            false,
    "streaming":      true,
    "token_counting": "approximate",
    "approval_modes":        ["interactive","autonomous"],
    "session_continuity":    false
  },
  "models": {
    "aliases": {
      "default": "amazon.nova-premier-v1:0"
    },
    "default": "amazon.nova-premier-v1:0"
  },
  "auth": {
    "methods": ["aws:credentials"],
    "verify":  "aws sts get-caller-identity"
  }
}'
}

agent_doctor() {
  if ! command -v kiro &>/dev/null; then
    printf 'kiro CLI not found. Install Kiro from the AWS Marketplace or Developer Preview.\n' >&2
    return 1
  fi
  if ! aws sts get-caller-identity >/dev/null 2>&1; then
    printf 'AWS credentials not configured. Run: aws configure\n' >&2
    return 1
  fi
  return 0
}

agent_login_hint() { printf 'aws configure\n'; }

_thin_shell_invoke() {
  local _prompt="$1" log_file="$2" feat_id="$3" wt_path="$4"
  (cd "$wt_path" && printf '%s\n' "$_prompt" | \
    adapter_tee "$log_file" -- \
      op_timeout "${SKILL_TIMEOUT_SECONDS:-1800}" \
        kiro agent run \
          --feature "$feat_id" \
          ${MONOZUKURI_MODEL:+--model "$MONOZUKURI_MODEL"} \
          -)
}

# Kiro native-spec workflow: handle prd/techspec via `kiro spec create` when enabled.
# Returns 0 (handled+success), non-zero non-99 (handled+failed), or 99 (not handled).
_thin_shell_pre_phase() {
  local feat_id="$1" wt_path="$2" log_file="$3" phase="$4"
  local use_native_specs="${KIRO_USE_NATIVE_SPECS:-false}"
  if [ "$use_native_specs" = "true" ] && { [ "$phase" = "prd" ] || [ "$phase" = "techspec" ]; }; then
    local exit_code=0
    (cd "$wt_path" && adapter_tee "$log_file" -- \
      op_timeout "${SKILL_TIMEOUT_SECONDS:-1800}" \
        kiro spec create \
          --feature "$feat_id" \
          --phase "$phase") || exit_code=$?
    return "$exit_code"
  fi
  return 99
}

agent_native_context_files() {
  printf '%s\n' '["AGENTS.md"]'
}
