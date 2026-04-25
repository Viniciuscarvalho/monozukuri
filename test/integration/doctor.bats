#!/usr/bin/env bats
# test/integration/doctor.bats — integration tests for monozukuri doctor

setup() {
  REPO_ROOT="$(cd "$(dirname "$BATS_TEST_FILENAME")/../.." && pwd)"
  ORCHESTRATE="$REPO_ROOT/scripts/orchestrate.sh"
  SAMPLE_PROJECT="$REPO_ROOT/test/fixtures/sample-project"
  cd "$SAMPLE_PROJECT"
}

@test "doctor subcommand is recognised" {
  run bash "$ORCHESTRATE" --help
  [ "$status" -eq 0 ]
  [[ "$output" == *"doctor"* ]]
}

@test "doctor runs and checks node" {
  run bash "$ORCHESTRATE" doctor
  # Exit 0 (all pass) or 11 (missing deps) — both are valid in CI
  [ "$status" -eq 0 ] || [ "$status" -eq 11 ]
  [[ "$output" == *"node"* ]]
}

@test "doctor checks jq" {
  run bash "$ORCHESTRATE" doctor
  [[ "$output" == *"jq"* ]]
}

@test "doctor checks claude CLI" {
  run bash "$ORCHESTRATE" doctor
  [[ "$output" == *"claude"* ]]
}
