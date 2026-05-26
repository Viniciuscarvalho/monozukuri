#!/usr/bin/env bats
# test/integration/vrf_verification.bats - v2 verification harnesses

REPO_ROOT="$(cd "$(dirname "$BATS_TEST_FILENAME")/../.." && pwd)"
MRP_SCRIPT="$REPO_ROOT/scripts/verification/mrp-matrix.js"
LOOP_SCRIPT="$REPO_ROOT/scripts/verification/loop-conformance.sh"

setup() {
  TMPDIR_TEST="$(mktemp -d)"
}

teardown() {
  rm -rf "$TMPDIR_TEST"
}

@test "MRP v2 matrix records five iterations per agent and proves code token savings" {
  results="$TMPDIR_TEST/mrp-results.json"
  dashboard="$TMPDIR_TEST/mrp-dashboard.md"

  run node "$MRP_SCRIPT" --mock --results "$results" --dashboard "$dashboard"

  [ "$status" -eq 0 ]
  [ -f "$results" ]
  [ -f "$dashboard" ]
  [[ "$output" == *"MRP v2 matrix: PASS"* ]]
  grep -q "Memory v2 MRP Matrix" "$dashboard"

  run jq -e '
    (.agents | sort) == ["claude-code","codex","gemini"] and
    (.iterations == 5) and
    (.records | length == 15) and
    all(.records[]; .total_tokens and .code_tokens and .total_ms and (.first_pass_success_rate_by_phase.code | type == "number") and (.memory_hit_rate | type == "number")) and
    all(.assertions[]; .pass == true and .iteration5_code_tokens < (.iteration1_code_tokens * 0.75))
  ' "$results"
  [ "$status" -eq 0 ]
}

@test "MRP v2 matrix fails the gate when iteration 5 code tokens are not below 75 percent" {
  fixture="$TMPDIR_TEST/mrp-failing.json"
  results="$TMPDIR_TEST/mrp-results.json"
  dashboard="$TMPDIR_TEST/mrp-dashboard.md"
  cat > "$fixture" <<'JSON'
{
  "agents": {
    "claude-code": [10000, 9700, 9600, 9500, 9400],
    "codex": [10000, 9800, 9700, 9600, 9500],
    "gemini": [10000, 9900, 9800, 9700, 9600]
  }
}
JSON

  run node "$MRP_SCRIPT" --mock --fixture "$fixture" --results "$results" --dashboard "$dashboard"

  [ "$status" -eq 1 ]
  [[ "$output" == *"MRP v2 matrix: FAIL"* ]]
  run jq -e 'any(.assertions[]; .pass == false)' "$results"
  [ "$status" -eq 0 ]
}

@test "loop conformance runs three mock tasks for Claude Codex and Gemini with matching orchestration behavior" {
  out_dir="$TMPDIR_TEST/loop-conformance"

  run bash "$LOOP_SCRIPT" --tasks 3 --out-dir "$out_dir"

  [ "$status" -eq 0 ]
  [[ "$output" == *"Loop conformance: PASS"* ]]
  [ -f "$out_dir/report.json" ]
  [ -f "$out_dir/summary.md" ]
  grep -q "Loop Conformance Suite" "$out_dir/summary.md"

  run jq -e '
    (.agents | sort) == ["claude-code","codex","gemini"] and
    (.task_count == 3) and
    (.pass == true) and
    all(.runs[]; .exit_code == 0 and (.event_sequence == ["loop.started","task.started","phase.cost_recorded","task.completed","task.started","phase.cost_recorded","task.completed","task.started","phase.cost_recorded","task.completed","loop.completed"])) and
    (.diffs | length == 0)
  ' "$out_dir/report.json"
  [ "$status" -eq 0 ]
}

@test "v2 verification workflow runs MRP nightly and loop conformance in mock mode" {
  workflow="$REPO_ROOT/.github/workflows/v2-verification.yml"

  [ -f "$workflow" ]
  grep -q "cron:" "$workflow"
  grep -q "scripts/verification/mrp-matrix.js --mock" "$workflow"
  grep -q "scripts/verification/loop-conformance.sh --tasks 3" "$workflow"
}
