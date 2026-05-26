#!/usr/bin/env bats
# test/integration/memory_injection_tracking.bats — Memory v2 prompt injection traces

REPO_ROOT="$(cd "$(dirname "$BATS_TEST_FILENAME")/../.." && pwd)"

setup() {
  TMPDIR_TEST="$(mktemp -d)"
  PROJECT_DIR="$TMPDIR_TEST/project"
  mkdir -p "$PROJECT_DIR/.monozukuri" "$PROJECT_DIR/.monozukuri/runs"
  export ROOT_DIR="$PROJECT_DIR"
  export CONFIG_DIR="$PROJECT_DIR/.monozukuri"
  export MONOZUKURI_RUN_DIR="$CONFIG_DIR/runs"
  export MONOZUKURI_WORKTREE="$PROJECT_DIR"
  export MONOZUKURI_AUTONOMY="checkpoint"
  export MONOZUKURI_AGENT="codex"
  export ADAPTER="codex"
  export FEATURE_TITLE="Track learning injections"
  export FEATURE_DESCRIPTION="Verify Memory v2 prompt provenance."
  export PROMPT_PHASES_DIR="$REPO_ROOT/lib/prompt/phases"
  source "$REPO_ROOT/lib/prompt/context-pack.sh"
  source "$REPO_ROOT/lib/prompt/render.sh"
}

teardown() {
  rm -rf "$TMPDIR_TEST"
}

write_memory_store() {
  cat > "$CONFIG_DIR/memory-v2.json" <<'JSON'
[
  {
    "id": "lrn-2026-05-24-101",
    "scope": "project",
    "insight": "Prefer direct Bats for CLI behavior changes.",
    "rationale": "CLI regressions are easiest to catch through the public shell entrypoint.",
    "source": {
      "feature_id": "MEM-03",
      "phase": "tests",
      "run_id": "manual",
      "artifact": "test/integration/memory_injection_tracking.bats"
    },
    "applied_count": 0,
    "last_applied": null,
    "promoted_from": "manual",
    "agent_specific": null,
    "tags": ["memory", "tests"]
  }
]
JSON
}

@test "rendered phase includes learning id marker and writes injection trace" {
  write_memory_store
  local ctx="$TMPDIR_TEST/context.json"
  export MONOZUKURI_FEATURE_ID="feat-memory-001"

  context_pack_build "$MONOZUKURI_FEATURE_ID" "$ctx"
  CONTEXT_JSON="$ctx" run render_phase_prompt prd

  [ "$status" -eq 0 ]
  [[ "$output" == *"<!-- learning: lrn-2026-05-24-101 -->"* ]]

  local trace="$MONOZUKURI_RUN_DIR/$MONOZUKURI_FEATURE_ID/memory-injections.jsonl"
  [ -f "$trace" ]
  run jq -e '
    .phase == "prd" and
    .learnings == ["lrn-2026-05-24-101"] and
    (.tokens | type == "number") and
    (.tokens > 0) and
    (.timestamp | type == "string")
  ' "$trace"
  [ "$status" -eq 0 ]
}

@test "successful phases increment applied_count for injected learnings across three features" {
  write_memory_store

  local feat ctx
  for feat in feat-memory-001 feat-memory-002 feat-memory-003; do
    ctx="$TMPDIR_TEST/$feat-context.json"
    export MONOZUKURI_FEATURE_ID="$feat"
    context_pack_build "$feat" "$ctx"
    CONTEXT_JSON="$ctx" run render_phase_prompt prd
    [ "$status" -eq 0 ]
    memory_v2_mark_phase_success prd
  done

  run jq -e '
    .[0].id == "lrn-2026-05-24-101" and
    .[0].applied_count == 3 and
    (.[0].last_applied | type == "string")
  ' "$CONFIG_DIR/memory-v2.json"
  [ "$status" -eq 0 ]
}

@test "corrupted memory v2 store does not block prompt rendering" {
  printf '{not-json' > "$CONFIG_DIR/memory-v2.json"
  local ctx="$TMPDIR_TEST/corrupt-context.json"
  export MONOZUKURI_FEATURE_ID="feat-memory-corrupt"

  context_pack_build "$MONOZUKURI_FEATURE_ID" "$ctx"
  CONTEXT_JSON="$ctx" run render_phase_prompt prd

  [ "$status" -eq 0 ]
  [[ "$output" == *"## Problem"* ]]
  [[ "$output" != *"<!-- learning:"* ]]
  [ ! -f "$MONOZUKURI_RUN_DIR/$MONOZUKURI_FEATURE_ID/memory-injections.jsonl" ]
}
