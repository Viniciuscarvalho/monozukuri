#!/bin/bash
# lib/agent/adapter-kiro.sh — AWS Kiro adapter.
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
    "approval_modes": ["interactive","autonomous"]
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
  local phase="${MONOZUKURI_PHASE:-prd}"

  local use_native_specs="${KIRO_USE_NATIVE_SPECS:-false}"

  # For prd/techspec phases, optionally use kiro's native spec workflow
  if [ "$use_native_specs" = "true" ] && { [ "$phase" = "prd" ] || [ "$phase" = "techspec" ]; }; then
    (cd "$wt_path" && kiro spec create \
      --feature "$feat_id" \
      --phase "$phase") 2>&1 | tee "$log_file"
    return "${PIPESTATUS[0]}"
  fi

  # All other phases (and prd/techspec when native specs disabled): agent run
  local rendered_prompt
  if declare -f render_phase_prompt &>/dev/null; then
    rendered_prompt=$(render_phase_prompt "$phase")
  else
    rendered_prompt="Implement feature ${feat_id}."
  fi

  (cd "$wt_path" && printf '%s\n' "$rendered_prompt" | \
    kiro agent run \
      --feature "$feat_id" \
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
