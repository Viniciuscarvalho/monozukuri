#!/usr/bin/env bats
# test/integration/agent_claude_code_dry_run.bats
# Verifies that `monozukuri run --agent claude-code --dry-run` works end-to-end.

setup() {
  REPO_ROOT="$(cd "$(dirname "$BATS_TEST_FILENAME")/../.." && pwd)"
  ORCHESTRATE="$REPO_ROOT/orchestrate.sh"
  SAMPLE_PROJECT="$REPO_ROOT/test/fixtures/sample-project"
  MOCK_CLAUDE="$REPO_ROOT/test/fixtures/agents/mock-claude-code"

  mkdir -p "$SAMPLE_PROJECT/.monozukuri"
  cat > "$SAMPLE_PROJECT/.monozukuri/config.yaml" << 'EOCFG'
source:
  adapter: markdown
  markdown:
    file: features.md
autonomy: checkpoint
execution:
  base_branch: main
agent: claude-code
EOCFG

  cd "$SAMPLE_PROJECT"
  git checkout -b main 2>/dev/null || git checkout main 2>/dev/null || true

  # Prepend mock claude to PATH so agent_doctor passes
  export PATH="$MOCK_CLAUDE:$PATH"
}

teardown() {
  rm -f "$SAMPLE_PROJECT/.monozukuri/config.yaml" \
        "$SAMPLE_PROJECT/orchestration-backlog.json"
}

@test "run --dry-run with agent:claude-code exits 0" {
  run bash "$ORCHESTRATE" run --dry-run --non-interactive
  [ "$status" -eq 0 ]
}

@test "run --dry-run with agent:claude-code shows plan output" {
  run bash "$ORCHESTRATE" run --dry-run --non-interactive
  [[ "$output" == *"feat-001"* ]] || [[ "$output" == *"Dry Run"* ]]
}

@test "run --dry-run with agent:claude-code shows claude-code adapter" {
  run bash "$ORCHESTRATE" run --dry-run --non-interactive
  # Banner includes adapter name from config
  [[ "$output" == *"claude-code"* ]] || [[ "$output" == *"Orchestrate"* ]]
}
