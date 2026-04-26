#!/bin/bash
# lib/agent/adapter-gemini.sh — Google Gemini CLI adapter.
#
# Required env vars (set by pipeline.sh before calling agent_run_phase):
#   MONOZUKURI_FEATURE_ID   feature being processed
#   MONOZUKURI_WORKTREE     absolute path to the feature worktree
#   MONOZUKURI_AUTONOMY     supervised | checkpoint | full_auto
#   MONOZUKURI_LOG_FILE     where to tee gemini output (optional)
#
# Auth: GEMINI_API_KEY or gcloud ADC (~/.config/gcloud/application_default_credentials.json).

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
    "methods": ["api_key:GEMINI_API_KEY", "gcloud:ADC"],
    "verify":  "gemini --version"
  }
}'
}

agent_doctor() {
  if ! command -v gemini &>/dev/null; then
    printf 'gemini CLI not found. Install: npm install -g @google/gemini-cli\n' >&2
    return 1
  fi
  local adc_file="${HOME}/.config/gcloud/application_default_credentials.json"
  if [ -z "${GEMINI_API_KEY:-}" ] && [ ! -f "$adc_file" ]; then
    printf 'gemini auth missing. Set GEMINI_API_KEY or run: gcloud auth application-default login\n' >&2
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

  # Map autonomy: full_auto → --yolo true; others → --yolo false (interactive)
  local yolo_flag="false"
  [ "${MONOZUKURI_AUTONOMY:-checkpoint}" = "full_auto" ] && yolo_flag="true"

  local rendered_prompt
  if declare -f render_phase_prompt &>/dev/null; then
    rendered_prompt=$(render_phase_prompt "${MONOZUKURI_PHASE:-prd}")
  else
    rendered_prompt="Implement feature ${feat_id}."
  fi

  (cd "$wt_path" && printf '%s\n' "$rendered_prompt" | \
    gemini \
      --yolo "$yolo_flag" \
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
  printf '%s\n' '["AGENTS.md", "GEMINI.md"]'
}
