#!/usr/bin/env bats
# test/conformance/agent_phase_outputs.bats
#
# Agent Conformance Suite — verifies that render_phase_prompt produces
# phase-specific required headings for each enabled adapter.
#
# Phase 3 baseline: claude-code only.
# Phases 4–6 extend AGENTS_UNDER_TEST when new adapters land.
#
# Each adapter mock must live in:
#   test/fixtures/agents/mock-<name>/<binary>
# and be prepended to PATH when agent_doctor runs.

AGENTS_UNDER_TEST=(claude-code codex gemini kiro aider)

# Required headings per phase — one heading per line (bash 3 compatible)
_headings_for() {
  local phase="$1"
  case "$phase" in
    prd)
      printf '%s\n' "## Problem" "## Solution" "## Functional requirements" "## Out of scope"
      ;;
    techspec)
      printf '%s\n' "## Approach" "## File change map" "## Components" "## Testing"
      ;;
    tasks)
      printf '%s\n' "## Output contract"
      ;;
    code)
      printf '%s\n' "## Instructions" "## Output contract"
      ;;
    tests)
      printf '%s\n' "## Output contract"
      ;;
    pr)
      printf '%s\n' "## Instructions" "## Output contract"
      ;;
    *)
      ;;
  esac
}

setup() {
  REPO_ROOT="$(cd "$(dirname "$BATS_TEST_FILENAME")/../.." && pwd)"
  LIB_DIR="$REPO_ROOT/lib"
  PROMPT_PHASES_DIR="$LIB_DIR/prompt/phases"
  export LIB_DIR PROMPT_PHASES_DIR

  source "$LIB_DIR/agent/contract.sh"
  source "$LIB_DIR/prompt/render.sh"

  export MONOZUKURI_FEATURE_ID="feat-001"
  export MONOZUKURI_AUTONOMY="checkpoint"
  export MONOZUKURI_WORKTREE="/tmp/conformance-worktree"
  export MONOZUKURI_RUN_DIR="/tmp/conformance-run"
  export FEATURE_TITLE="Conformance test feature"
  export FEATURE_DESCRIPTION="A feature used by the conformance test suite."
  export LEARNINGS_BLOCK=""
}

# ── helpers ──────────────────────────────────────────────────────────────────

_assert_phase_headings() {
  local agent="$1" phase="$2"
  local rendered heading ok=0

  rendered=$(render_phase_prompt "$phase")
  [ "$?" -eq 0 ] || { echo "render_phase_prompt '$phase' failed for agent '$agent'" >&2; return 1; }

  while IFS= read -r heading; do
    [ -z "$heading" ] && continue
    if ! printf '%s\n' "$rendered" | grep -qF "$heading"; then
      printf 'FAIL [%s/%s]: missing heading "%s"\n' "$agent" "$phase" "$heading" >&2
      ok=1
    fi
  done <<< "$(_headings_for "$phase")"
  return "$ok"
}

# ── per-agent, per-phase conformance tests ────────────────────────────────────

@test "claude-code: prd template has required headings" {
  _assert_phase_headings "claude-code" "prd"
}

@test "claude-code: techspec template has required headings" {
  _assert_phase_headings "claude-code" "techspec"
}

@test "claude-code: tasks template has required headings" {
  _assert_phase_headings "claude-code" "tasks"
}

@test "claude-code: code template has required headings" {
  _assert_phase_headings "claude-code" "code"
}

@test "claude-code: tests template has required headings" {
  _assert_phase_headings "claude-code" "tests"
}

@test "claude-code: pr template has required headings" {
  _assert_phase_headings "claude-code" "pr"
}

# ── agent_verify for all adapters ────────────────────────────────────────────

@test "claude-code adapter satisfies the six-function contract" {
  agent_load "claude-code"
  run agent_verify
  [ "$status" -eq 0 ]
}

@test "codex adapter satisfies the six-function contract" {
  agent_load "codex"
  run agent_verify
  [ "$status" -eq 0 ]
}

@test "gemini adapter satisfies the six-function contract" {
  agent_load "gemini"
  run agent_verify
  [ "$status" -eq 0 ]
}

@test "kiro adapter satisfies the six-function contract" {
  agent_load "kiro"
  run agent_verify
  [ "$status" -eq 0 ]
}

@test "aider adapter satisfies the six-function contract" {
  agent_load "aider"
  run agent_verify
  [ "$status" -eq 0 ]
}

# ── schema injection conformance ──────────────────────────────────────────────

@test "claude-code: _cc_inject_schemas populates .monozukuri-schemas/ in worktree" {
  agent_load "claude-code"
  local wt
  wt=$(mktemp -d)
  _cc_inject_schemas "$wt"
  [ -d "$wt/.monozukuri-schemas" ]
  # At least the techspec schema (most critical — has files_likely_touched) must be present
  [ -f "$wt/.monozukuri-schemas/techspec.schema.json" ]
  rm -rf "$wt"
}

@test "aider: _aider_inject_schemas populates .monozukuri-schemas/ in worktree" {
  agent_load "aider"
  local wt
  wt=$(mktemp -d)
  _aider_inject_schemas "$wt"
  [ -d "$wt/.monozukuri-schemas" ]
  [ -f "$wt/.monozukuri-schemas/techspec.schema.json" ]
  rm -rf "$wt"
}

# ── error envelope conformance ────────────────────────────────────────────────

@test "claude-code: agent_run_phase writes MONOZUKURI_ERROR_FILE when claude exits non-zero" {
  agent_load "claude-code"
  # Stub platform_claude to exit 1 (simulating a failed agent run)
  platform_claude() { shift; echo "mock claude failure" >&2; return 1; }
  export -f platform_claude
  # Stub op_timeout so it doesn't try to actually timeout
  op_timeout() { shift; "$@"; }
  export -f op_timeout

  local wt; wt=$(mktemp -d)
  local err_file; err_file=$(mktemp)
  MONOZUKURI_FEATURE_ID="conf-feat-1" \
  MONOZUKURI_WORKTREE="$wt" \
  MONOZUKURI_LOG_FILE="$wt/run.log" \
  MONOZUKURI_ERROR_FILE="$err_file" \
    agent_run_phase 2>/dev/null || true

  # Error file must contain valid JSON with a 'class' field
  node -e "
    const d = JSON.parse(require('fs').readFileSync('$err_file','utf-8'));
    if (!d.class) throw new Error('missing class');
    const valid = ['transient','phase','fatal','unknown'];
    if (!valid.includes(d.class)) throw new Error('invalid class: ' + d.class);
  "
  rm -rf "$wt" "$err_file"
}

@test "aider: agent_run_phase writes MONOZUKURI_ERROR_FILE when aider exits non-zero" {
  agent_load "aider"
  op_timeout() { shift; echo "mock aider failure" >&2; return 1; }
  export -f op_timeout

  local wt; wt=$(mktemp -d)
  local err_file; err_file=$(mktemp)
  MONOZUKURI_FEATURE_ID="conf-feat-2" \
  MONOZUKURI_WORKTREE="$wt" \
  MONOZUKURI_LOG_FILE="$wt/run.log" \
  MONOZUKURI_ERROR_FILE="$err_file" \
    agent_run_phase 2>/dev/null || true

  node -e "
    const d = JSON.parse(require('fs').readFileSync('$err_file','utf-8'));
    if (!d.class) throw new Error('missing class');
  "
  rm -rf "$wt" "$err_file"
}

# ── mock binary sanity checks ─────────────────────────────────────────────────

@test "mock-claude-code/claude binary is executable" {
  [ -x "$REPO_ROOT/test/fixtures/agents/mock-claude-code/claude" ]
}

@test "mock-claude-code/claude exits 0 with --version" {
  run "$REPO_ROOT/test/fixtures/agents/mock-claude-code/claude" --version
  [ "$status" -eq 0 ]
}

@test "mock-claude-code/claude exits 0 with auth status" {
  run "$REPO_ROOT/test/fixtures/agents/mock-claude-code/claude" auth status
  [ "$status" -eq 0 ]
}

@test "mock-codex/codex binary is executable" {
  [ -x "$REPO_ROOT/test/fixtures/agents/mock-codex/codex" ]
}

@test "mock-gemini/gemini binary is executable" {
  [ -x "$REPO_ROOT/test/fixtures/agents/mock-gemini/gemini" ]
}

@test "mock-kiro/kiro binary is executable" {
  [ -x "$REPO_ROOT/test/fixtures/agents/mock-kiro/kiro" ]
}

@test "mock-kiro handles 'spec create' subcommand" {
  run "$REPO_ROOT/test/fixtures/agents/mock-kiro/kiro" spec create --feature feat-001
  [ "$status" -eq 0 ]
  [[ "$output" == *"mock-kiro"* ]]
}

@test "mock-kiro handles 'agent run' subcommand" {
  run "$REPO_ROOT/test/fixtures/agents/mock-kiro/kiro" agent run --feature feat-001
  [ "$status" -eq 0 ]
  [[ "$output" == *"mock-kiro"* ]]
}

@test "mock-aider/aider binary is executable" {
  [ -x "$REPO_ROOT/test/fixtures/agents/mock-aider/aider" ]
}

@test "mock-aider/aider exits 0 with --version" {
  run "$REPO_ROOT/test/fixtures/agents/mock-aider/aider" --version
  [ "$status" -eq 0 ]
  [[ "$output" == *"mock-aider"* ]]
}
