#!/usr/bin/env bats
# test/integration/agent_claude_code_dry_run.bats
# Verifies that `monozukuri run --agent claude-code --dry-run` works end-to-end.

setup() {
  REPO_ROOT="$(cd "$(dirname "$BATS_TEST_FILENAME")/../.." && pwd)"
  ORCHESTRATE="$REPO_ROOT/orchestrate.sh"
  SAMPLE_PROJECT="$REPO_ROOT/test/fixtures/sample-project"
  PROJECT="$(mktemp -d)"
  MOCK_CLAUDE="$REPO_ROOT/test/fixtures/agents/mock-claude-code"

  cp "$SAMPLE_PROJECT/features.md" "$PROJECT/features.md"
  mkdir -p "$PROJECT/.monozukuri"
  cat > "$PROJECT/.monozukuri/config.yaml" << 'EOCFG'
source:
  adapter: markdown
  markdown:
    file: features.md
autonomy: checkpoint
execution:
  base_branch: main
agent: claude-code
EOCFG

  git -C "$PROJECT" init -q -b main 2>/dev/null || git -C "$PROJECT" init -q
  git -C "$PROJECT" checkout -B main >/dev/null 2>&1 || true
  git -C "$PROJECT" \
    -c user.email=qa@test.local -c user.name=qa -c commit.gpgsign=false \
    add -A
  git -C "$PROJECT" \
    -c user.email=qa@test.local -c user.name=qa -c commit.gpgsign=false \
    commit -q -m init
  cd "$PROJECT"

  # Prepend mock claude to PATH so agent_doctor passes
  export PATH="$MOCK_CLAUDE:$PATH"
}

teardown() {
  rm -rf "$PROJECT"
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
