#!/usr/bin/env bats
# test/unit/render.bats — Tests for render.sh node-based (CONTEXT_JSON) path

setup() {
  REPO_ROOT="$(cd "$(dirname "$BATS_TEST_FILENAME")/../.." && pwd)"
  LIB_DIR="$REPO_ROOT/lib"
  PROMPT_PHASES_DIR="$LIB_DIR/prompt/phases"
  FIXTURE_CTX="$REPO_ROOT/test/fixtures/contexts/simple.json"
  export PROMPT_PHASES_DIR LIB_DIR FIXTURE_CTX
  source "$LIB_DIR/prompt/render.sh"

  export MONOZUKURI_FEATURE_ID="feat-001"
  export FEATURE_TITLE="Add login"
  export MONOZUKURI_AUTONOMY="checkpoint"
  export MONOZUKURI_WORKTREE="/tmp/render-test-wt"
}

teardown() {
  unset CONTEXT_JSON 2>/dev/null || true
}

# ── node availability guard ────────────────────────────────────────────────────

@test "node is available (required for CONTEXT_JSON path)" {
  command -v node
}

# ── CONTEXT_JSON path: prd template ──────────────────────────────────────────

@test "prd: renders with CONTEXT_JSON and has new required headings" {
  CONTEXT_JSON="$FIXTURE_CTX" run render_phase_prompt prd
  [ "$status" -eq 0 ]
  [[ "$output" == *"## Problem"* ]]
  [[ "$output" == *"## Solution"* ]]
  [[ "$output" == *"## Functional requirements"* ]]
}

@test "prd: FEATURE_ID substituted from context JSON" {
  CONTEXT_JSON="$FIXTURE_CTX" run render_phase_prompt prd
  [ "$status" -eq 0 ]
  [[ "$output" == *"feat-001"* ]]
}

@test "prd: FEATURE_TITLE substituted from context JSON" {
  CONTEXT_JSON="$FIXTURE_CTX" run render_phase_prompt prd
  [ "$status" -eq 0 ]
  [[ "$output" == *"Add login"* ]]
}

@test "prd: STACK substituted from context JSON" {
  CONTEXT_JSON="$FIXTURE_CTX" run render_phase_prompt prd
  [ "$status" -eq 0 ]
  [[ "$output" == *"Node.js"* ]]
}

@test "prd: project_learnings expanded via {{#each}}" {
  CONTEXT_JSON="$FIXTURE_CTX" run render_phase_prompt prd
  [ "$status" -eq 0 ]
  [[ "$output" == *"Always write tests first."* ]]
  [[ "$output" == *"Use TypeScript strict mode."* ]]
}

@test "prd: agent fill-in tokens remain intact" {
  CONTEXT_JSON="$FIXTURE_CTX" run render_phase_prompt prd
  [ "$status" -eq 0 ]
  [[ "$output" == *"{{PROBLEM_STATEMENT}}"* ]]
}

@test "prd: {{#each}} block markers are not in output" {
  CONTEXT_JSON="$FIXTURE_CTX" run render_phase_prompt prd
  [ "$status" -eq 0 ]
  [[ "$output" != *"{{#each"* ]]
  [[ "$output" != *"{{/each}}"* ]]
}

# ── CONTEXT_JSON path: techspec template ─────────────────────────────────────

@test "techspec: renders with CONTEXT_JSON and has required headings" {
  CONTEXT_JSON="$FIXTURE_CTX" run render_phase_prompt techspec
  [ "$status" -eq 0 ]
  [[ "$output" == *"## Approach"* ]]
  [[ "$output" == *"## File change map"* ]]
  [[ "$output" == *"## Components"* ]]
  [[ "$output" == *"## Testing"* ]]
}

@test "techspec: MAX_FILES substituted from context JSON" {
  CONTEXT_JSON="$FIXTURE_CTX" run render_phase_prompt techspec
  [ "$status" -eq 0 ]
  [[ "$output" == *"8"* ]]
}

@test "techspec: project_learnings expanded" {
  CONTEXT_JSON="$FIXTURE_CTX" run render_phase_prompt techspec
  [ "$status" -eq 0 ]
  [[ "$output" == *"Always write tests first."* ]]
}

# ── CONTEXT_JSON path: empty learnings ───────────────────────────────────────

@test "prd: empty project_learnings array leaves no {{#each}} markers" {
  local ctx_file
  ctx_file=$(mktemp)
  SRC="$FIXTURE_CTX" DST="$ctx_file" node -e '
    const c = JSON.parse(require("fs").readFileSync(process.env.SRC, "utf-8"));
    c.project_learnings = [];
    require("fs").writeFileSync(process.env.DST, JSON.stringify(c));
  '
  CONTEXT_JSON="$ctx_file" run render_phase_prompt prd
  [ "$status" -eq 0 ]
  [[ "$output" != *"{{#each"* ]]
  rm -f "$ctx_file"
}

# ── Fallback to sed path when CONTEXT_JSON is absent ─────────────────────────

@test "prd: sed path used when CONTEXT_JSON is not set" {
  unset CONTEXT_JSON
  run render_phase_prompt prd
  [ "$status" -eq 0 ]
  # FEATURE_ID substituted via sed rule
  [[ "$output" == *"feat-001"* ]]
}

@test "prd: sed path used when CONTEXT_JSON file does not exist" {
  CONTEXT_JSON="/nonexistent/path.json" run render_phase_prompt prd
  [ "$status" -eq 0 ]
  [[ "$output" == *"feat-001"* ]]
}
