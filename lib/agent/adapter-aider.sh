#!/bin/bash
# lib/agent/adapter-aider.sh — Aider adapter (alpha, ADR-012).
#
# Bridges the Monozukuri adapter contract to the Aider CLI.
# Aider is invoked with --message for non-interactive operation.
# All six phases are run in a single aider session, guided by a structured prompt
# that references the artifacts from prior phases.
#
# Required env vars: same as all adapters (see docs/adapter-contract.md §2).
#
# Aider-specific env vars:
#   AIDER_MODEL   Override model (falls back to MONOZUKURI_MODEL → adapter default)

agent_name() { echo "aider"; }

agent_capabilities() {
  printf '%s\n' '{
  "agent": "aider",
  "supports": {
    "phases":         ["prd","techspec","tasks","code","tests","pr"],
    "skills":         false,
    "native_edit":    true,
    "shell_access":   false,
    "mcp":            false,
    "streaming":      true,
    "token_counting": "estimate",
    "approval_modes": ["auto","suggest"]
  },
  "models": {
    "aliases": {
      "opus":   "claude/claude-opus-4-7",
      "sonnet": "claude/claude-sonnet-4-6",
      "haiku":  "claude/claude-haiku-4-5"
    },
    "default": "sonnet"
  },
  "auth": {
    "methods": ["api_key:ANTHROPIC_API_KEY"],
    "verify":  "aider --version"
  }
}'
}

agent_doctor() {
  if ! command -v aider &>/dev/null; then
    printf 'aider not found. Install: pip install aider-chat\n' >&2
    return 1
  fi
  if [ -z "${ANTHROPIC_API_KEY:-}" ] && [ -z "${OPENAI_API_KEY:-}" ]; then
    printf 'No API key found. Set ANTHROPIC_API_KEY or OPENAI_API_KEY.\n' >&2
    return 1
  fi
  return 0
}

agent_estimate_tokens() {
  local prompt; prompt=$(cat)
  printf '%d\n' $(( ${#prompt} / 4 ))
}

# _aider_inject_schemas <wt_path>
# Copies phase schemas into <wt_path>/.monozukuri-schemas/ (ADR-012 schema-in-prompt).
_aider_inject_schemas() {
  local wt_path="$1"
  local schemas_dir
  schemas_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)/schemas"
  local dest="$wt_path/.monozukuri-schemas"
  mkdir -p "$dest" 2>/dev/null || return 0
  for artifact in prd techspec tasks commit-summary; do
    local src="$schemas_dir/$artifact.schema.json"
    [ -f "$src" ] && cp "$src" "$dest/" 2>/dev/null || true
  done
}

# _aider_resolve_model
# Resolves alias → aider model string. Falls back to sonnet.
_aider_resolve_model() {
  local alias="${AIDER_MODEL:-${MONOZUKURI_MODEL:-sonnet}}"
  case "$alias" in
    opus)   echo "claude/claude-opus-4-7" ;;
    sonnet) echo "claude/claude-sonnet-4-6" ;;
    haiku)  echo "claude/claude-haiku-4-5" ;;
    opusplan) echo "claude/claude-sonnet-4-6" ;;
    *) echo "$alias" ;;
  esac
}

# _aider_build_prompt <feat_id> <run_dir> <wt_path>
# Builds the structured feature-implementation prompt for aider.
_aider_build_prompt() {
  local feat_id="$1"
  local run_dir="${MONOZUKURI_RUN_DIR:-/tmp}"
  local wt_path="$3"
  local feat_dir="$run_dir/$feat_id"

  printf 'You are implementing feature %s.\n\n' "$feat_id"
  printf 'PHASE SEQUENCE: prd → techspec → tasks → code → tests → pr\n\n'

  printf 'Output schemas are at %s/.monozukuri-schemas/\n\n' "$wt_path"

  printf '## Phase 1 — PRD\n'
  printf 'Write a PRD to %s/prd.md (sections: Goal, Users, Success Metrics, Non-Goals).\n\n' "$feat_dir"

  printf '## Phase 2 — TechSpec\n'
  printf 'Write a TechSpec to %s/techspec.md following the schema at .monozukuri-schemas/techspec.schema.json.\n' "$feat_dir"
  printf 'Required section: "## Files Likely Touched" with a bullet list of files.\n\n'

  printf '## Phase 3 — Tasks\n'
  printf 'Write tasks to %s/tasks.json following .monozukuri-schemas/tasks.schema.json.\n\n' "$feat_dir"

  printf '## Phase 4 — Code\n'
  printf 'Implement each task from tasks.json. Commit each task: feat(%s): <task title>\n\n' "$feat_id"

  printf '## Phase 5 — Tests\n'
  printf 'Write tests covering the acceptance criteria. All tests must pass. '
  printf 'Write a summary to %s/tests.md\n\n' "$feat_dir"

  printf '## Phase 6 — PR\n'
  printf 'Open a PR with gh pr create. Write PR metadata to %s/pr.md\n' "$feat_dir"
}

agent_run_phase() {
  local feat_id="${MONOZUKURI_FEATURE_ID:?agent_run_phase: MONOZUKURI_FEATURE_ID not set}"
  local wt_path="${MONOZUKURI_WORKTREE:?agent_run_phase: MONOZUKURI_WORKTREE not set}"
  local log_file="${MONOZUKURI_LOG_FILE:-/tmp/monozukuri-aider-${feat_id}-$(date +%s).log}"
  local run_dir="${MONOZUKURI_RUN_DIR:-}"

  local model
  model=$(_aider_resolve_model)

  local yes_flag="--yes"
  [ "${MONOZUKURI_AUTONOMY:-}" = "supervised" ] && yes_flag=""

  # ADR-012: inject schemas before invoking the agent
  _aider_inject_schemas "$wt_path"

  local prompt
  prompt=$(_aider_build_prompt "$feat_id" "$run_dir" "$wt_path")

  local exit_code=0
  (
    set -o pipefail
    cd "$wt_path" && op_timeout "${SKILL_TIMEOUT_SECONDS:-1800}" \
      aider \
      --model "$model" \
      --no-git \
      $yes_flag \
      --read ".monozukuri-schemas" \
      --message "$prompt" 2>&1 | tee "$log_file"
  ) || exit_code=$?

  # ADR-013: write error envelope
  if [ "$exit_code" -ne 0 ] && [ -n "${MONOZUKURI_ERROR_FILE:-}" ]; then
    if declare -f agent_error_classify &>/dev/null; then
      agent_error_classify "$exit_code" "$log_file" > "$MONOZUKURI_ERROR_FILE" 2>/dev/null || true
    else
      printf '{"class":"unknown","code":"exit-%d","message":"aider exited with code %d"}\n' \
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
