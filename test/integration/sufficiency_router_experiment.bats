#!/usr/bin/env bats
# test/integration/sufficiency_router_experiment.bats - MEM-05 experiment harness

REPO_ROOT="$(cd "$(dirname "$BATS_TEST_FILENAME")/../.." && pwd)"
SCRIPT="$REPO_ROOT/scripts/experiments/sufficiency-router.js"

setup() {
  TMPDIR_TEST="$(mktemp -d)"
  OUT_DIR="$TMPDIR_TEST/sufficiency-router"
}

teardown() {
  rm -rf "$TMPDIR_TEST"
}

@test "sufficiency router experiment selects the fixed 5 fixture features" {
  run node "$SCRIPT" --fake --out-dir "$OUT_DIR" --agents claude-code --strategies summary --phases prd

  [ "$status" -eq 0 ]
  [ -f "$OUT_DIR/features.json" ]
  run jq -e '
    length == 5 and
    .[0].id == "feat-node-001" and
    any(.[]; .id == "feat-py-004") and
    any(.[]; .id == "feat-go-005")
  ' "$OUT_DIR/features.json"
  [ "$status" -eq 0 ]
}

@test "sufficiency router prompts distinguish full summary and on-demand strategies" {
  run node "$SCRIPT" --fake --out-dir "$OUT_DIR" --agents claude-code --strategies inject-full,summary,on-demand --phases prd --max-features 1

  [ "$status" -eq 0 ]
  full_prompt="$OUT_DIR/raw/claude-code/inject-full/feat-node-001/prd.prompt.md"
  summary_prompt="$OUT_DIR/raw/claude-code/summary/feat-node-001/prd.prompt.md"
  demand_prompt="$OUT_DIR/raw/claude-code/on-demand/feat-node-001/prd.prompt.md"
  [ -f "$full_prompt" ]
  [ -f "$summary_prompt" ]
  [ -f "$demand_prompt" ]
  grep -q "rationale:" "$full_prompt"
  ! grep -q "rationale:" "$summary_prompt"
  grep -q "MEMORY_ESCALATE:" "$demand_prompt"
}

@test "on-demand strategy escalates when the agent requests memory ids" {
  run node "$SCRIPT" --fake --fake-behavior escalate --out-dir "$OUT_DIR" --agents codex --strategies on-demand --phases techspec --max-features 1

  [ "$status" -eq 0 ]
  [ -f "$OUT_DIR/raw/codex/on-demand/feat-node-001/techspec.escalated.prompt.md" ]
  run jq -e '
    .runs[0].strategy == "on-demand" and
    .runs[0].escalated == true and
    .runs[0].escalation_reason == "requested_ids" and
    .runs[0].attempts == 2
  ' "$OUT_DIR/results.json"
  [ "$status" -eq 0 ]
}

@test "on-demand strategy escalates once when summary output fails schema validation" {
  run node "$SCRIPT" --fake --fake-behavior invalid-summary --out-dir "$OUT_DIR" --agents gemini --strategies on-demand --phases prd --max-features 1

  [ "$status" -eq 0 ]
  run jq -e '
    .runs[0].escalated == true and
    .runs[0].escalation_reason == "schema_invalid" and
    .runs[0].schema_valid == true and
    .runs[0].attempts == 2
  ' "$OUT_DIR/results.json"
  [ "$status" -eq 0 ]
}

@test "sufficiency router aggregates C wins across at least two agents" {
  run node "$SCRIPT" --fake --out-dir "$OUT_DIR" --agents claude-code,codex,gemini --strategies inject-full,summary,on-demand --phases prd --max-features 1

  [ "$status" -eq 0 ]
  [ -f "$OUT_DIR/results.csv" ]
  run jq -e '
    .decision.strategy_c_winning_agents >= 2 and
    .decision.proceed == true and
    .aggregates["claude-code"]["on-demand"].schema_pass_rate == 1
  ' "$OUT_DIR/results.json"
  [ "$status" -eq 0 ]
}
