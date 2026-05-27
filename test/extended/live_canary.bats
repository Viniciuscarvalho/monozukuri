#!/usr/bin/env bats
# test/extended/live_canary.bats - long-running VRF-03 canary harness checks

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
