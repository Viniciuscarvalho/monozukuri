#!/usr/bin/env bats
# test/integration/init_wizard.bats
# Verifies that monozukuri init generates config with 'agent:' (not 'skill.command:')
# when run non-interactively with mock-claude in PATH.

setup() {
  REPO_ROOT="$(cd "$(dirname "$BATS_TEST_FILENAME")/../.." && pwd)"
  ORCHESTRATE="$REPO_ROOT/orchestrate.sh"
  MOCK_CLAUDE="$REPO_ROOT/test/fixtures/agents/mock-claude-code"

  # Create a fresh empty git project
  TMP_PROJECT="$(mktemp -d)"
  cd "$TMP_PROJECT"
  git init -q
  git commit --allow-empty -m "init" -q

  # Prepend mock claude so agent detection finds it
  export PATH="$MOCK_CLAUDE:$PATH"
}

teardown() {
  rm -rf "$TMP_PROJECT"
}

@test "init --non-interactive creates .monozukuri/config.yaml" {
  run bash "$ORCHESTRATE" init --non-interactive
  [ "$status" -eq 0 ]
  [ -f "$TMP_PROJECT/.monozukuri/config.yaml" ]
}

@test "init --non-interactive config has 'agent:' key" {
  run bash "$ORCHESTRATE" init --non-interactive
  [ "$status" -eq 0 ]
  grep -q "^agent:" "$TMP_PROJECT/.monozukuri/config.yaml"
}

@test "init --non-interactive config sets agent to claude-code" {
  run bash "$ORCHESTRATE" init --non-interactive
  [ "$status" -eq 0 ]
  grep -q "^agent: claude-code" "$TMP_PROJECT/.monozukuri/config.yaml"
}

@test "init --non-interactive config has no 'skill.command: feature-marker' hardcode" {
  run bash "$ORCHESTRATE" init --non-interactive
  [ "$status" -eq 0 ]
  ! grep -q "skill:" "$TMP_PROJECT/.monozukuri/config.yaml"
}

@test "init --non-interactive creates features.md" {
  run bash "$ORCHESTRATE" init --non-interactive
  [ "$status" -eq 0 ]
  [ -f "$TMP_PROJECT/features.md" ]
}
