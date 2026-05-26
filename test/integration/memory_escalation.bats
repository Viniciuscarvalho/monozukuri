#!/usr/bin/env bats
# test/integration/memory_escalation.bats — Memory v2 escalation prompt loop

setup() {
  REPO_ROOT="$(cd "$(dirname "$BATS_TEST_FILENAME")/../.." && pwd)"
  TMPDIR_TEST="$(mktemp -d)"
  PROJECT_DIR="$TMPDIR_TEST/project"
  mkdir -p "$PROJECT_DIR/.monozukuri/runs" "$PROJECT_DIR/tasks/prd-feat-memory-escalation"
  export ROOT_DIR="$PROJECT_DIR"
  export CONFIG_DIR="$PROJECT_DIR/.monozukuri"
  export MONOZUKURI_RUN_DIR="$CONFIG_DIR/runs"
  export MONOZUKURI_RUN_ID="run-memory-escalation"
  export MONOZUKURI_WORKTREE="$PROJECT_DIR"
  export MONOZUKURI_FEATURE_ID="feat-memory-escalation"
  export MONOZUKURI_PHASE="prd"
  export MONOZUKURI_AUTONOMY="checkpoint"
  export MONOZUKURI_AGENT="codex"
  export ADAPTER="codex"
  export FEATURE_TITLE="Memory escalation feature"
  export FEATURE_DESCRIPTION="Verify raw learning escalation."
  export PROMPT_PHASES_DIR="$REPO_ROOT/lib/prompt/phases"
  export LOG_FILE="$TMPDIR_TEST/agent.log"
  export CONTEXT_JSON="$TMPDIR_TEST/context.json"
  source "$REPO_ROOT/lib/agent/adapter-codex.sh"
  source "$REPO_ROOT/lib/prompt/context-pack.sh"
  source "$REPO_ROOT/lib/prompt/render.sh"
  source "$REPO_ROOT/lib/memory/v2.sh"
}

teardown() {
  rm -rf "$TMPDIR_TEST"
}

write_memory_store() {
  cat > "$CONFIG_DIR/memory-v2.json" <<'JSON'
[
  {
    "id": "lrn-2026-05-25-001",
    "scope": "project",
    "insight": "Prefer direct Bats for CLI behavior changes.",
    "rationale": "Raw rationale should only appear after a structured memory escalation.",
    "source": {
      "feature_id": "MEM-07",
      "phase": "tests",
      "run_id": "run-memory-escalation",
      "artifact": "test/integration/memory_escalation.bats"
    },
    "applied_count": 4,
    "last_applied": null,
    "promoted_from": "manual",
    "agent_specific": null,
    "tags": ["memory", "tests"]
  }
]
JSON
}

@test "rendered prompt tells agents how to request raw learning detail" {
  write_memory_store
  context_pack_build "$MONOZUKURI_FEATURE_ID" "$CONTEXT_JSON"

  run render_phase_prompt prd

  [ "$status" -eq 0 ]
  [[ "$output" == *'Se precisar de detalhe sobre um learning, emita <request-memory id="lrn-xxx"/> no início da sua resposta'* ]]
}

@test "memory escalation logs event rebuilds context and re-prompts once" {
  write_memory_store
  context_pack_build "$MONOZUKURI_FEATURE_ID" "$CONTEXT_JSON"
  call_count_file="$TMPDIR_TEST/calls"
  : > "$call_count_file"

  agent_run_phase() {
    local calls
    calls="$(wc -l < "$call_count_file" | tr -d ' ')"
    echo "call" >> "$call_count_file"
    if [ "$calls" -eq 0 ]; then
      printf '<request-memory id="lrn-2026-05-25-001"/>\n' > "$LOG_FILE"
      return 0
    fi
    cp "$CONTEXT_JSON" "$TMPDIR_TEST/expanded-context.json"
    printf 'final answer\n' > "$LOG_FILE"
    return 0
  }

  run memory_v2_run_phase_with_escalation prd "$MONOZUKURI_FEATURE_ID" "$MONOZUKURI_WORKTREE" "$LOG_FILE" "$CONTEXT_JSON"

  [ "$status" -eq 0 ]
  [ "$(wc -l < "$call_count_file" | tr -d ' ')" -eq 2 ]
  run jq -e '
    [.project_learnings[].summary] |
    any(contains("raw_memory: lrn-2026-05-25-001")) and
    any(contains("Raw rationale should only appear after a structured memory escalation."))
  ' "$TMPDIR_TEST/expanded-context.json"
  [ "$status" -eq 0 ]
  run jq -e '.[] | select(.id == "lrn-2026-05-25-001") | .applied_count == 5' "$CONFIG_DIR/memory-v2.json"
  [ "$status" -eq 0 ]

  local trace="$MONOZUKURI_RUN_DIR/$MONOZUKURI_FEATURE_ID/memory-injections.jsonl"
  [ -f "$trace" ]
  run jq -e '
    select(.event == "escalation") |
    .phase == "prd" and
    .learnings == ["lrn-2026-05-25-001"] and
    .attempt == 1
  ' "$trace"
  [ "$status" -eq 0 ]

  local decision_trace="$MONOZUKURI_RUN_DIR/$MONOZUKURI_RUN_ID/memory-trace.jsonl"
  [ -f "$decision_trace" ]
  run jq -s -e '
    any(.[]; .event == "escalation_requested" and .learning_id == "lrn-2026-05-25-001" and .phase == "prd" and .attempt == 1) and
    any(.[]; .event == "escalation_granted" and .learning_id == "lrn-2026-05-25-001" and .phase == "prd" and .attempt == 1 and (.tokens | type == "number"))
  ' "$decision_trace"
  [ "$status" -eq 0 ]
}

@test "memory escalation stops after three requests in one phase" {
  write_memory_store
  context_pack_build "$MONOZUKURI_FEATURE_ID" "$CONTEXT_JSON"

  agent_run_phase() {
    printf '<request-memory id="lrn-2026-05-25-001"/>\n' > "$LOG_FILE"
    return 0
  }

  run memory_v2_run_phase_with_escalation prd "$MONOZUKURI_FEATURE_ID" "$MONOZUKURI_WORKTREE" "$LOG_FILE" "$CONTEXT_JSON"

  [ "$status" -ne 0 ]
  [ "$(jq -s '[.[] | select(.event == "escalation")] | length' "$MONOZUKURI_RUN_DIR/$MONOZUKURI_FEATURE_ID/memory-injections.jsonl")" -eq 3 ]
  run jq -s -e '
    any(.[]; .event == "escalation_requested" and .learning_id == "lrn-2026-05-25-001" and .phase == "prd" and .attempt == 4) and
    any(.[]; .event == "escalation_denied" and .learning_id == "lrn-2026-05-25-001" and .phase == "prd" and .attempt == 4 and .reason == "cap_reached")
  ' "$MONOZUKURI_RUN_DIR/$MONOZUKURI_RUN_ID/memory-trace.jsonl"
  [ "$status" -eq 0 ]
}
