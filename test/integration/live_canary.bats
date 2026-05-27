#!/usr/bin/env bats
# test/integration/live_canary.bats - fast PR wiring checks for VRF-03 canary

REPO_ROOT="$(cd "$(dirname "$BATS_TEST_FILENAME")/../.." && pwd)"

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
