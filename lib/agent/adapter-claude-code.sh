#!/bin/bash
# lib/agent/adapter-claude-code.sh — Claude Code reference adapter (ADR-012/013).
#
# Implements the six-function adapter contract. Wraps the feature-marker skill
# invocation with:
#   - Schema injection to worktree (.monozukuri-schemas/) before invocation
#   - Proper exit-code capture with pipefail
#   - Error envelope writing to MONOZUKURI_ERROR_FILE on failure (ADR-013)
#
# Required env vars (set by pipeline.sh before calling agent_run_phase):
#   MONOZUKURI_FEATURE_ID   feature being processed
#   MONOZUKURI_WORKTREE     absolute path to the feature worktree
#   MONOZUKURI_AUTONOMY     supervised | checkpoint | full_auto
#   MONOZUKURI_MODEL        model alias (optional; empty = config default)
#   MONOZUKURI_LOG_FILE     where to tee claude output (optional)
#   MONOZUKURI_ERROR_FILE   path for structured error envelope on failure (optional)
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

# _cc_inject_schemas <wt_path>
# Copies phase schemas into <wt_path>/.monozukuri-schemas/ (ADR-012 schema-in-prompt).
_cc_inject_schemas() {
  local wt_path="$1"
  local schemas_dir
  # Navigate: lib/agent/ → lib/ → repo-root → schemas/
  schemas_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)/schemas"
  local dest="$wt_path/.monozukuri-schemas"
  mkdir -p "$dest" 2>/dev/null || return 0
  for artifact in prd techspec tasks commit-summary; do
    local src="$schemas_dir/$artifact.schema.json"
    [ -f "$src" ] && cp "$src" "$dest/" 2>/dev/null || true
  done
}

# _cc_run_phase_render PHASE FEAT_ID WT_PATH LOG_FILE
# Phase-aware render path: renders template → pipes to claude --print.
# Used when MONOZUKURI_PHASE=prd|techspec and CONTEXT_JSON is set.
_cc_run_phase_render() {
  local phase="$1" feat_id="$2" wt_path="$3" log_file="$4"
  local effective_model="${MONOZUKURI_MODEL:-}"
  [ "$effective_model" = "opusplan" ] && effective_model="sonnet"

  local perm_flag=""
  [ "${MONOZUKURI_AUTONOMY:-}" = "full_auto" ] && perm_flag="--dangerously-skip-permissions"

  # Source render.sh if not already loaded
  if ! declare -f render_phase_prompt &>/dev/null; then
    local _render_sh
    _render_sh="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/prompt/render.sh"
    [[ -f "$_render_sh" ]] && source "$_render_sh"
  fi

  local rendered_prompt
  rendered_prompt=$(render_phase_prompt "$phase") || return 1

  local artifact_dir="$wt_path/tasks/prd-$feat_id"
  mkdir -p "$artifact_dir"
  local artifact_file="$artifact_dir/${phase}.md"

  local exit_code=0
  (
    set -o pipefail
    cd "$wt_path" && platform_claude "${SKILL_TIMEOUT_SECONDS:-1800}" \
      ${effective_model:+--model "$effective_model"} \
      $perm_flag \
      -p "$rendered_prompt" 2>&1 | tee "$log_file"
  ) || exit_code=$?

  [ "$exit_code" -eq 0 ] && [ -s "$log_file" ] && cp "$log_file" "$artifact_file" || true
  return "$exit_code"
}

agent_run_phase() {
  local feat_id="${MONOZUKURI_FEATURE_ID:?agent_run_phase: MONOZUKURI_FEATURE_ID not set}"
  local wt_path="${MONOZUKURI_WORKTREE:?agent_run_phase: MONOZUKURI_WORKTREE not set}"
  local log_file="${MONOZUKURI_LOG_FILE:-/tmp/monozukuri-${feat_id}-$(date +%s).log}"

  # ADR-012: inject schemas before invoking the agent
  _cc_inject_schemas "$wt_path"

  local exit_code=0

  # Phase-aware render path (prd/techspec when CONTEXT_JSON is set)
  if [[ "${MONOZUKURI_PHASE:-}" == "prd" || "${MONOZUKURI_PHASE:-}" == "techspec" ]] && \
     [[ -n "${CONTEXT_JSON:-}" ]] && [[ -f "${CONTEXT_JSON}" ]]; then
    _cc_run_phase_render "$MONOZUKURI_PHASE" "$feat_id" "$wt_path" "$log_file" \
      || exit_code=$?
  else
    # Legacy feature-marker path
    local skill_arg="${SKILL_COMMAND:-feature-marker}"
    local effective_model="${MONOZUKURI_MODEL:-}"
    [ "$effective_model" = "opusplan" ] && effective_model="opus"

    local perm_flag=""
    [ "${MONOZUKURI_AUTONOMY:-}" = "full_auto" ] && perm_flag="--permission-mode bypassPermissions"

    local interactive_flag=""
    [ "${MONOZUKURI_AUTONOMY:-}" = "supervised" ] && interactive_flag="--interactive"

    (
      set -o pipefail
      cd "$wt_path" && platform_claude "${SKILL_TIMEOUT_SECONDS:-1800}" \
        ${effective_model:+--model "$effective_model"} \
        --agent "$skill_arg" \
        $perm_flag \
        ${interactive_flag:+$interactive_flag} \
        -p "prd-$feat_id" 2>&1 | tee "$log_file"
    ) || exit_code=$?
  fi

  # ADR-013: write error envelope so policy engine can classify without log scraping
  if [ "$exit_code" -ne 0 ] && [ -n "${MONOZUKURI_ERROR_FILE:-}" ]; then
    if declare -f agent_error_classify &>/dev/null; then
      agent_error_classify "$exit_code" "$log_file" > "$MONOZUKURI_ERROR_FILE" 2>/dev/null || true
    else
      printf '{"class":"unknown","code":"exit-%d","message":"claude exited with code %d"}\n' \
        "$exit_code" "$exit_code" > "$MONOZUKURI_ERROR_FILE" 2>/dev/null || true
    fi
  fi

  return "$exit_code"
}

agent_report_cost() {
  if declare -f cost_report &>/dev/null; then
    cost_report
  else
    echo "0.00"
  fi
}

# agent_native_context_files — optional 7th contract function.
# Returns JSON array of repo-relative paths this agent reads on its own.
# Conventions from these files are referenced by path rather than re-injected.
agent_native_context_files() {
  printf '%s\n' '["CLAUDE.md", ".claude/CLAUDE.md"]'
}
