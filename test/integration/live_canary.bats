#!/usr/bin/env bats
# test/integration/live_canary.bats - VRF-03 live canary release gate

REPO_ROOT="$(cd "$(dirname "$BATS_TEST_FILENAME")/../.." && pwd)"
CANARY_SCRIPT="$REPO_ROOT/scripts/verification/live-canary.sh"

setup() {
  TMPDIR_TEST="$(mktemp -d)"
}

teardown() {
  rm -rf "$TMPDIR_TEST"
}

@test "live canary harness runs two mock sandbox tasks per agent and requires green PR checks" {
  out_dir="$TMPDIR_TEST/live-canary"

  run bash "$CANARY_SCRIPT" --mock --tasks 2 --max-cost 5 --out-dir "$out_dir"

  [ "$status" -eq 0 ]
  [[ "$output" == *"Live canary: PASS"* ]]
  [ -f "$out_dir/results.json" ]
  [ -f "$out_dir/summary.md" ]

  run jq -e '
    .pass == true and
    .sandbox_repo == "monozukuri/test-sandbox" and
    .task_count == 2 and
    .max_cost_usd == 5 and
    .total_cost_usd <= 5 and
    (.agents | sort) == ["claude-code","codex","gemini"] and
    all(.runs[]; .exit_code == 0 and (.pr_urls | length == 2) and all(.ci_checks[]; .status == "success"))
  ' "$out_dir/results.json"
  [ "$status" -eq 0 ]
}

@test "live canary harness fails release gate when sandbox PR checks are red" {
  out_dir="$TMPDIR_TEST/live-canary-red"

  run bash "$CANARY_SCRIPT" --mock --mock-ci failure --agents codex --tasks 2 --max-cost 5 --out-dir "$out_dir"

  [ "$status" -eq 1 ]
  [[ "$output" == *"Live canary: FAIL"* ]]
  run jq -e '.pass == false and any(.runs[].ci_checks[]; .status == "failure")' "$out_dir/results.json"
  [ "$status" -eq 0 ]
}

@test "loop command exposes canary task and agent flags" {
  run bash "$REPO_ROOT/orchestrate.sh" loop --help

  [ "$status" -eq 0 ]
  [[ "$output" == *"--tasks N"* ]]
  [[ "$output" == *"--agent claude-code|codex|gemini"* ]]
}

@test "release gate layer 5 delegates to the live loop canary with a five dollar cap" {
  layer="$REPO_ROOT/.qa/layers/05-live-canary.sh"
  docs="$REPO_ROOT/docs/release/canary.md"

  [ -f "$docs" ]
  grep -q "scripts/verification/live-canary.sh --live" "$layer"
  grep -q -- "--max-cost 5" "$layer"
  grep -q "monozukuri/test-sandbox" "$docs"
  grep -q "monozukuri loop --tasks 2 --agent" "$docs"
}
