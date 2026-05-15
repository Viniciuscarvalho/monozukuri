#!/usr/bin/env bats
# test/unit/lib_prompt_render.bats — unit tests for lib/prompt/render.sh

setup() {
  REPO_ROOT="$(cd "$(dirname "$BATS_TEST_FILENAME")/../.." && pwd)"
  export REPO_ROOT
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
  [[ "$output" == *"## Problem"* ]]
  [[ "$output" == *"## Solution"* ]]
  [[ "$output" == *"## Functional requirements"* ]]
  [[ "$output" == *"## Out of scope"* ]]
}

@test "prd template substitutes feature id" {
  run render_phase_prompt prd
  [[ "$output" == *"feat-001"* ]]
}

@test "prd template substitutes feature title" {
  run render_phase_prompt prd
  [[ "$output" == *"Add login"* ]]
}

# ── TechSpec template ────────────────────────────────────────────────────────

@test "techspec template renders required headings" {
  run render_phase_prompt techspec
  [ "$status" -eq 0 ]
  [[ "$output" == *"## Approach"* ]]
  [[ "$output" == *"## File change map"* ]]
  [[ "$output" == *"## Components"* ]]
  [[ "$output" == *"## Testing"* ]]
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

@test "prd template substitutes worktree path via sed" {
  run render_phase_prompt prd
  # prd.tmpl.md title line contains FEATURE_ID; sed path substitutes it
  [[ "$output" == *"feat-001"* ]]
}

# ── Rich path (CONTEXT_JSON) substitutions ────────────────────────────────────

@test "code template substitutes MONOZUKURI_WORKTREE via rich context path" {
  local ctx
  ctx=$(mktemp)
  jq -n \
    --arg MONOZUKURI_FEATURE_ID "feat-rich" \
    --arg MONOZUKURI_WORKTREE   "/tmp/rich-worktree" \
    --arg MONOZUKURI_AUTONOMY   "full_auto" \
    --arg FEATURE_TITLE         "Rich test" \
    --arg STACK                 "Node 18" \
    --arg ORIGINAL_PROMPT       "" \
    '{MONOZUKURI_FEATURE_ID: $MONOZUKURI_FEATURE_ID,
      MONOZUKURI_WORKTREE: $MONOZUKURI_WORKTREE,
      MONOZUKURI_AUTONOMY: $MONOZUKURI_AUTONOMY,
      FEATURE_TITLE: $FEATURE_TITLE,
      STACK: $STACK,
      ORIGINAL_PROMPT: $ORIGINAL_PROMPT}' > "$ctx"
  export CONTEXT_JSON="$ctx"
  run render_phase_prompt code
  unset CONTEXT_JSON
  rm -f "$ctx"
  [ "$status" -eq 0 ]
  [[ "$output" == *"/tmp/rich-worktree"* ]]
  [[ "$output" != *"{{MONOZUKURI_WORKTREE}}"* ]]
}

@test "code template substitutes MONOZUKURI_FEATURE_ID via rich context path" {
  local ctx
  ctx=$(mktemp)
  jq -n \
    --arg MONOZUKURI_FEATURE_ID "feat-rich" \
    --arg MONOZUKURI_WORKTREE   "/tmp/rich-worktree" \
    --arg MONOZUKURI_AUTONOMY   "full_auto" \
    --arg FEATURE_TITLE         "Rich test" \
    --arg STACK                 "Node 18" \
    --arg ORIGINAL_PROMPT       "" \
    '{MONOZUKURI_FEATURE_ID: $MONOZUKURI_FEATURE_ID,
      MONOZUKURI_WORKTREE: $MONOZUKURI_WORKTREE,
      MONOZUKURI_AUTONOMY: $MONOZUKURI_AUTONOMY,
      FEATURE_TITLE: $FEATURE_TITLE,
      STACK: $STACK,
      ORIGINAL_PROMPT: $ORIGINAL_PROMPT}' > "$ctx"
  export CONTEXT_JSON="$ctx"
  run render_phase_prompt code
  unset CONTEXT_JSON
  rm -f "$ctx"
  [ "$status" -eq 0 ]
  [[ "$output" == *"feat-rich"* ]]
  [[ "$output" != *"{{MONOZUKURI_FEATURE_ID}}"* ]]
}

@test "context_pack_build emits MONOZUKURI_WORKTREE in JSON" {
  source "$REPO_ROOT/lib/prompt/context-pack.sh"
  local out
  out=$(mktemp)
  export MONOZUKURI_WORKTREE="/tmp/wt-pack-test"
  export MONOZUKURI_AUTONOMY="checkpoint"
  context_pack_build "feat-pack" "$out"
  run jq -r '.MONOZUKURI_WORKTREE' "$out"
  rm -f "$out"
  [ "$status" -eq 0 ]
  [[ "$output" == "/tmp/wt-pack-test" ]]
}

@test "context_pack_build emits MONOZUKURI_AUTONOMY in JSON" {
  source "$REPO_ROOT/lib/prompt/context-pack.sh"
  local out
  out=$(mktemp)
  export MONOZUKURI_WORKTREE="/tmp/wt-pack-test"
  export MONOZUKURI_AUTONOMY="full_auto"
  context_pack_build "feat-pack" "$out"
  run jq -r '.MONOZUKURI_AUTONOMY' "$out"
  rm -f "$out"
  [ "$status" -eq 0 ]
  [[ "$output" == "full_auto" ]]
}

@test "context_pack_build emits MONOZUKURI_FEATURE_ID in JSON" {
  source "$REPO_ROOT/lib/prompt/context-pack.sh"
  local out
  out=$(mktemp)
  context_pack_build "feat-pack" "$out"
  run jq -r '.MONOZUKURI_FEATURE_ID' "$out"
  rm -f "$out"
  [ "$status" -eq 0 ]
  [[ "$output" == "feat-pack" ]]
}

@test "render_phase_prompt prefixes SKILL.md for adapters with skill injection" {
  export ADAPTER="codex"
  export MONOZUKURI_SKILL_INJECTION="1"
  run render_phase_prompt prd
  unset ADAPTER MONOZUKURI_SKILL_INJECTION
  [ "$status" -eq 0 ]
  [[ "$output" == *"## Monozukuri portable skill instructions"* ]]
  [[ "$output" == *"mz-create-prd"* ]]
  [[ "$output" == *"## Problem"* ]]
}

@test "render_phase_prompt separates injected SKILL.md from phase prompt" {
  export ADAPTER="codex"
  export MONOZUKURI_SKILL_INJECTION="1"
  run render_phase_prompt prd
  unset ADAPTER MONOZUKURI_SKILL_INJECTION
  [ "$status" -eq 0 ]
  [[ "$output" == *$'--- END mz-create-prd SKILL.md ---\n\n# PRD'* ]]
}

@test "render_phase_prompt does not prefix SKILL.md when injection is disabled" {
  export ADAPTER="codex"
  export MONOZUKURI_SKILL_INJECTION="0"
  run render_phase_prompt prd
  unset ADAPTER MONOZUKURI_SKILL_INJECTION
  [ "$status" -eq 0 ]
  [[ "$output" != *"## Monozukuri portable skill instructions"* ]]
}

@test "render_phase_prompt auto mode reads agent_capabilities skill_injection flag" {
  agent_capabilities() {
    printf '%s\n' '{"supports":{"skill_injection":true,"skill_injection_every_turn":true}}'
  }

  export ADAPTER="kiro"
  unset MONOZUKURI_SKILL_INJECTION
  run render_phase_prompt prd
  unset ADAPTER
  unset -f agent_capabilities

  [ "$status" -eq 0 ]
  [[ "$output" == *"## Monozukuri portable skill instructions"* ]]
}

@test "render_phase_prompt auto mode skips injection when capability is false" {
  agent_capabilities() {
    printf '%s\n' '{"supports":{"skill_injection":false,"skill_injection_every_turn":false}}'
  }

  export ADAPTER="codex"
  unset MONOZUKURI_SKILL_INJECTION
  run render_phase_prompt prd
  unset ADAPTER
  unset -f agent_capabilities

  [ "$status" -eq 0 ]
  [[ "$output" != *"## Monozukuri portable skill instructions"* ]]
}

@test "render_phase_prompt skips continuation skill injection unless every_turn is enabled" {
  agent_capabilities() {
    printf '%s\n' '{"supports":{"skill_injection":true,"skill_injection_every_turn":false}}'
  }

  export ADAPTER="codex"
  export MONOZUKURI_MULTI_TURN_ACTIVE="1"
  unset MONOZUKURI_SKILL_INJECTION
  run render_phase_prompt techspec
  unset ADAPTER MONOZUKURI_MULTI_TURN_ACTIVE
  unset -f agent_capabilities

  [ "$status" -eq 0 ]
  [[ "$output" != *"## Monozukuri portable skill instructions"* ]]
}
