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

AGENTS_UNDER_TEST=(claude-code codex gemini kiro)

# Required headings per phase — one heading per line (bash 3 compatible)
_headings_for() {
  local phase="$1"
  case "$phase" in
    prd)
      printf '%s\n' "## Goal" "## Users" "## Success Metrics" "## Non-Goals"
      ;;
    techspec)
      printf '%s\n' "## Architecture" "## APIs" "## Data Model" "## Risks" "## Test Plan"
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
