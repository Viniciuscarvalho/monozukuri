#!/usr/bin/env bats
# test/integration/loop_command.bats — smoke tests for monozukuri loop

REPO_ROOT="$(cd "$(dirname "$BATS_TEST_FILENAME")/../.." && pwd)"
ORCHESTRATE="$REPO_ROOT/orchestrate.sh"
MOCK_CLAUDE_DIR="$REPO_ROOT/.qa/fixtures/mocks/claude"

setup() {
  TMPDIR_TEST="$(mktemp -d)"
  PROJ_DIR="$TMPDIR_TEST/project"
  mkdir -p "$PROJ_DIR/.monozukuri"

  git -C "$PROJ_DIR" init -b main -q 2>/dev/null \
    || git -C "$PROJ_DIR" init -q 2>/dev/null || true
  git -C "$PROJ_DIR" -c user.email="test@test.local" -c user.name="Test" \
    commit -q --allow-empty -m "init" 2>/dev/null || true

  cat >"$PROJ_DIR/features.md" <<'EOFEAT'
## [FEAT] feat-001: First loop feature
- priority: high

Build the first mocked loop feature.

## [FEAT] feat-002: Second loop feature
- priority: medium

Build the second mocked loop feature.

## [FEAT] feat-003: Third loop feature
- priority: low

Build the third mocked loop feature.
EOFEAT

  cat >"$PROJ_DIR/.monozukuri/config.yaml" <<'EOCFG'
source:
  adapter: markdown
  markdown:
    file: features.md
autonomy: full_auto
execution:
  base_branch: main
agent: claude-code
pr_creation:
  strategy: none
worktrees:
  auto_cleanup: false
safety:
  breaking_change_pause: false
  max_file_changes: 50
EOCFG

  export TMPDIR_TEST PROJ_DIR
}

teardown() {
  rm -rf "$TMPDIR_TEST"
}

@test "loop --help documents IDs, stdin, and cleanup" {
  run bash "$ORCHESTRATE" loop --help

  [ "$status" -eq 0 ]
  [[ "$output" == *"monozukuri loop <id...> [--cleanup]"* ]]
  [[ "$output" == *"printf 'feat-001\\nfeat-002\\n' | monozukuri loop"* ]]
  [[ "$output" == *"--cleanup"* ]]
}

@test "loop runs three selected features with mocked pipeline and preserves loop worktrees" {
  cd "$PROJ_DIR"
  run env PATH="$MOCK_CLAUDE_DIR:$PATH" PROGRESS_INTERVAL=0 \
    bash "$ORCHESTRATE" loop feat-001 feat-002 feat-003 --non-interactive --no-ui

  [ "$status" -eq 0 ]
  [[ "$output" == *"[1/3] feat-001 ✓ done"* ]]
  [[ "$output" == *"[2/3] feat-002 ✓ done"* ]]
  [[ "$output" == *"[3/3] feat-003 ✓ done"* ]]

  loop_dir_count=$(find "$PROJ_DIR/.monozukuri/worktrees" -maxdepth 1 -type d -name 'loop-*' | wc -l | tr -d ' ')
  [ "$loop_dir_count" -eq 1 ]
  [ -d "$PROJ_DIR/.monozukuri/worktrees"/loop-*/feat-001 ]
  [ -d "$PROJ_DIR/.monozukuri/worktrees"/loop-*/feat-002 ]
  [ -d "$PROJ_DIR/.monozukuri/worktrees"/loop-*/feat-003 ]
}

@test "loop reads feature IDs from stdin when no positional IDs are provided" {
  cd "$PROJ_DIR"
  run bash -c 'printf "%s\n" feat-001 | PATH="$1:$PATH" PROGRESS_INTERVAL=0 bash "$2" loop --non-interactive --no-ui' \
    _ "$MOCK_CLAUDE_DIR" "$ORCHESTRATE"

  [ "$status" -eq 0 ]
  [[ "$output" == *"[1/1] feat-001 ✓ done"* ]]
}

@test "loop reports missing IDs and continues with later selected features" {
  cd "$PROJ_DIR"
  run env PATH="$MOCK_CLAUDE_DIR:$PATH" PROGRESS_INTERVAL=0 \
    bash "$ORCHESTRATE" loop missing-feature feat-001 --non-interactive --no-ui

  [ "$status" -eq 1 ]
  [[ "$output" == *"[1/2] missing-feature ✗ not found"* ]]
  [[ "$output" == *"[2/2] feat-001 ✓ done"* ]]
}

@test "loop --cleanup removes loop worktrees after successful features" {
  cd "$PROJ_DIR"
  run env PATH="$MOCK_CLAUDE_DIR:$PATH" PROGRESS_INTERVAL=0 \
    bash "$ORCHESTRATE" loop feat-001 --cleanup --non-interactive --no-ui

  [ "$status" -eq 0 ]
  [[ "$output" == *"[1/1] feat-001 ✓ done"* ]]
  [ ! -d "$PROJ_DIR/.monozukuri/worktrees" ] || \
    [ -z "$(find "$PROJ_DIR/.monozukuri/worktrees" -mindepth 2 -maxdepth 2 -type d -name 'feat-001' -print -quit)" ]
}
