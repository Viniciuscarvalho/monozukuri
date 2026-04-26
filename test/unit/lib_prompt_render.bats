#!/usr/bin/env bats
# test/unit/lib_prompt_render.bats — unit tests for lib/prompt/render.sh

setup() {
  REPO_ROOT="$(cd "$(dirname "$BATS_TEST_FILENAME")/../.." && pwd)"
  LIB_DIR="$REPO_ROOT/lib"
  PROMPT_PHASES_DIR="$LIB_DIR/prompt/phases"
  export PROMPT_PHASES_DIR
  source "$LIB_DIR/prompt/render.sh"

  export MONOZUKURI_FEATURE_ID="feat-001"
  export MONOZUKURI_AUTONOMY="checkpoint"
  export MONOZUKURI_WORKTREE="/tmp/test-worktree"
  export MONOZUKURI_RUN_DIR="/tmp/test-run"
  export FEATURE_TITLE="Add login"
  export FEATURE_DESCRIPTION="Users need to authenticate."
  export LEARNINGS_BLOCK="- Always write tests first."
}

# ── render.sh loads cleanly ──────────────────────────────────────────────────

@test "render.sh sources without error" {
  run bash -c "source '$LIB_DIR/prompt/render.sh' && echo ok"
  [ "$status" -eq 0 ]
  [[ "$output" == *"ok"* ]]
}

@test "render_phase_prompt returns 1 for unknown phase" {
  run render_phase_prompt "nonexistent"
  [ "$status" -eq 1 ]
}

# ── PRD template ─────────────────────────────────────────────────────────────

@test "prd template renders required headings" {
  run render_phase_prompt prd
  [ "$status" -eq 0 ]
  [[ "$output" == *"## Goal"* ]]
  [[ "$output" == *"## Users"* ]]
  [[ "$output" == *"## Success Metrics"* ]]
  [[ "$output" == *"## Non-Goals"* ]]
}

@test "prd template substitutes feature id" {
  run render_phase_prompt prd
  [[ "$output" == *"feat-001"* ]]
}

@test "prd template substitutes feature title" {
  run render_phase_prompt prd
  [[ "$output" == *"Add login"* ]]
}

@test "prd template substitutes learnings block" {
  run render_phase_prompt prd
  [[ "$output" == *"Always write tests first"* ]]
}

# ── TechSpec template ────────────────────────────────────────────────────────

@test "techspec template renders required headings" {
  run render_phase_prompt techspec
  [ "$status" -eq 0 ]
  [[ "$output" == *"## Architecture"* ]]
  [[ "$output" == *"## APIs"* ]]
  [[ "$output" == *"## Data Model"* ]]
  [[ "$output" == *"## Risks"* ]]
  [[ "$output" == *"## Test Plan"* ]]
}

# ── Tasks template ───────────────────────────────────────────────────────────

@test "tasks template renders output contract section" {
  run render_phase_prompt tasks
  [ "$status" -eq 0 ]
  [[ "$output" == *"## Output contract"* ]]
  [[ "$output" == *"tasks.json"* ]]
}

# ── Code template ────────────────────────────────────────────────────────────

@test "code template renders instructions section" {
  run render_phase_prompt code
  [ "$status" -eq 0 ]
  [[ "$output" == *"## Instructions"* ]]
  [[ "$output" == *"/tmp/test-worktree"* ]]
}

# ── Tests template ───────────────────────────────────────────────────────────

@test "tests template renders output contract section" {
  run render_phase_prompt tests
  [ "$status" -eq 0 ]
  [[ "$output" == *"## Output contract"* ]]
  [[ "$output" == *"tests.md"* ]]
}

# ── PR template ──────────────────────────────────────────────────────────────

@test "pr template renders instructions section" {
  run render_phase_prompt pr
  [ "$status" -eq 0 ]
  [[ "$output" == *"## Instructions"* ]]
  [[ "$output" == *"gh pr create"* ]]
}

# ── Token substitution edge cases ────────────────────────────────────────────

@test "prd template substitutes run dir correctly" {
  run render_phase_prompt prd
  [[ "$output" == *"/tmp/test-run"* ]]
}

@test "prd template uses default learnings when LEARNINGS_BLOCK is empty" {
  LEARNINGS_BLOCK="" run render_phase_prompt prd
  [[ "$output" == *"No prior learnings."* ]]
}
