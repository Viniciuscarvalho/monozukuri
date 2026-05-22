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

make_failing_claude_mock() {
  local mock_dir="$TMPDIR_TEST/failing-claude"
  mkdir -p "$mock_dir"
  cat >"$mock_dir/claude" <<'EOFMOCK'
#!/bin/bash
set -euo pipefail

for arg in "$@"; do
  if [ "$arg" = "--version" ]; then
    echo "claude 1.0.0-failing-mock"
    exit 0
  fi
done

if [ "${1:-}" = "auth" ] && [ "${2:-}" = "status" ]; then
  echo "Authenticated as failing-mock@example.com"
  exit 0
fi

if [ "${MONOZUKURI_PHASE:-}" = "code" ] && [ "${MONOZUKURI_FEATURE_ID:-}" = "feat-001" ]; then
  echo "injected code failure for feat-001" >&2
  exit 42
fi

exec "$REAL_CLAUDE_MOCK/claude" "$@"
EOFMOCK
  chmod +x "$mock_dir/claude"
  printf '%s\n' "$mock_dir"
}

make_always_failing_claude_mock() {
  local mock_dir="$TMPDIR_TEST/always-failing-claude"
  mkdir -p "$mock_dir"
  cat >"$mock_dir/claude" <<'EOFMOCK'
#!/bin/bash
set -euo pipefail

for arg in "$@"; do
  if [ "$arg" = "--version" ]; then
    echo "claude 1.0.0-always-failing-mock"
    exit 0
  fi
done

if [ "${1:-}" = "auth" ] && [ "${2:-}" = "status" ]; then
  echo "Authenticated as always-failing-mock@example.com"
  exit 0
fi

if [ "${MONOZUKURI_PHASE:-}" = "code" ]; then
  echo "injected code failure for ${MONOZUKURI_FEATURE_ID:-unknown}" >&2
  exit 42
fi

exec "$REAL_CLAUDE_MOCK/claude" "$@"
EOFMOCK
  chmod +x "$mock_dir/claude"
  printf '%s\n' "$mock_dir"
}

@test "loop --help documents IDs, stdin, and cleanup" {
  run bash "$ORCHESTRATE" loop --help

  [ "$status" -eq 0 ]
  [[ "$output" == *"monozukuri loop <id...> [--cleanup]"* ]]
  [[ "$output" == *"printf 'feat-001\\nfeat-002\\n' | monozukuri loop"* ]]
  [[ "$output" == *"--cleanup"* ]]
  [[ "$output" == *"--max-cost USD"* ]]
  [[ "$output" == *"--max-time MINUTES"* ]]
  [[ "$output" == *"--max-tokens-per-task N"* ]]
  [[ "$output" == *"--on-failure MODE"* ]]
  [[ "$output" == *"--circuit-breaker N"* ]]
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

@test "loop stops before the next feature when max cost is reached" {
  cd "$PROJ_DIR"
  run env PATH="$MOCK_CLAUDE_DIR:$PATH" PROGRESS_INTERVAL=0 \
    bash "$ORCHESTRATE" loop feat-001 feat-002 --max-cost 0.01 --non-interactive --no-ui

  [ "$status" -eq 4 ]
  [[ "$output" == *"[1/2] feat-001 ✓ done"* ]]
  [[ "$output" != *"[2/2] feat-002"* ]]
  [[ "$output" == *"Loop cost:"* ]]
  [[ "$output" == *"cap reached"* ]]

  cost_file=$(find "$PROJ_DIR/.monozukuri/runs" -maxdepth 2 -type f -path '*/loop-*/cost.json' | head -1)
  [ -n "$cost_file" ]
  node -e "
    const fs = require('fs');
    const data = JSON.parse(fs.readFileSync('$cost_file', 'utf8'));
    if (data.limit_usd !== 0.01) throw new Error('wrong limit_usd');
    if (data.status !== 'cap-reached') throw new Error('wrong status');
    if (!Array.isArray(data.phase_events) || data.phase_events.length === 0) throw new Error('missing phase events');
    if (!data.features.some((f) => f.id === 'feat-001')) throw new Error('missing feat-001');
  "
}

@test "loop stops before the next feature when per-task token cap is reached" {
  cd "$PROJ_DIR"
  run env PATH="$MOCK_CLAUDE_DIR:$PATH" PROGRESS_INTERVAL=0 \
    bash "$ORCHESTRATE" loop feat-001 feat-002 --max-tokens-per-task 1000 --non-interactive --no-ui

  [ "$status" -eq 4 ]
  [[ "$output" == *"[1/2] feat-001 ✓ done"* ]]
  [[ "$output" != *"[2/2] feat-002"* ]]
  [[ "$output" == *"Loop cap reached: tokens"* ]]
}

@test "loop rejects max tokens per task above hard ceiling" {
  cd "$PROJ_DIR"
  run bash "$ORCHESTRATE" loop feat-001 --max-tokens-per-task 500001 --non-interactive --no-ui

  [ "$status" -eq 1 ]
  [[ "$output" == *"--max-tokens-per-task hard ceiling is 500000"* ]]
}

@test "loop --on-failure stop aborts after a failed feature" {
  cd "$PROJ_DIR"
  failing_mock=$(make_failing_claude_mock)

  run env PATH="$failing_mock:$PATH" REAL_CLAUDE_MOCK="$MOCK_CLAUDE_DIR" PROGRESS_INTERVAL=0 \
    bash "$ORCHESTRATE" loop feat-001 feat-002 --on-failure stop --non-interactive --no-ui

  [ "$status" -eq 3 ]
  [[ "$output" == *"[1/2] feat-001 ✗"* ]]
  [[ "$output" != *"[2/2] feat-002"* ]]
  [[ "$output" == *"Loop stopped after failure"* ]]
}

@test "loop --on-failure continue marks failed feature and runs the next one" {
  cd "$PROJ_DIR"
  failing_mock=$(make_failing_claude_mock)

  run env PATH="$failing_mock:$PATH" REAL_CLAUDE_MOCK="$MOCK_CLAUDE_DIR" PROGRESS_INTERVAL=0 \
    bash "$ORCHESTRATE" loop feat-001 feat-002 --on-failure continue --non-interactive --no-ui

  [ "$status" -eq 1 ]
  [[ "$output" == *"[1/2] feat-001 ✗ failed"* ]]
  [[ "$output" == *"[2/2] feat-002 ✓ done"* ]]

  status_file="$PROJ_DIR/.monozukuri/state/feat-001/status.json"
  [ -f "$status_file" ]
  node -e "
    const fs = require('fs');
    const data = JSON.parse(fs.readFileSync('$status_file', 'utf8'));
    if (data.status !== 'failed') throw new Error('expected failed status');
  "
}

@test "loop trips circuit breaker after three consecutive failures even with continue mode" {
  cd "$PROJ_DIR"
  failing_mock=$(make_always_failing_claude_mock)
  stdout_file="$TMPDIR_TEST/loop-stdout.txt"
  stderr_file="$TMPDIR_TEST/loop-stderr.txt"

  run bash -c '
    PATH="$1:$PATH" REAL_CLAUDE_MOCK="$2" PROGRESS_INTERVAL=0 \
      bash "$3" loop feat-001 feat-002 feat-003 --on-failure continue --non-interactive --no-ui \
      >"$4" 2>"$5"
    printf "%s" "$?"
  ' _ "$failing_mock" "$MOCK_CLAUDE_DIR" "$ORCHESTRATE" "$stdout_file" "$stderr_file"

  [ "$status" -eq 0 ]
  [ "$output" -eq 5 ]
  grep -q "\\[1/3\\] feat-001 ✗ failed" "$stdout_file"
  grep -q "\\[2/3\\] feat-002 ✗ failed" "$stdout_file"
  grep -q "\\[3/3\\] feat-003 ✗ failed" "$stdout_file"
  grep -q "Circuit breaker tripped: 3 consecutive failures" "$stdout_file"
  grep -q "Circuit breaker tripped: 3 consecutive failures" "$stderr_file"

  cost_file=$(find "$PROJ_DIR/.monozukuri/runs" -maxdepth 2 -type f -path '*/loop-*/cost.json' | head -1)
  [ -n "$cost_file" ]
  node -e "
    const fs = require('fs');
    const data = JSON.parse(fs.readFileSync('$cost_file', 'utf8'));
    if (data.status !== 'circuit-breaker-tripped') throw new Error('wrong status');
    if (!data.circuit_breaker || data.circuit_breaker.tripped !== true) throw new Error('missing circuit breaker state');
    if (data.circuit_breaker.consecutive_failures !== 3) throw new Error('wrong failure count');
    if (!Array.isArray(data.circuit_breaker.failed_feature_ids) || data.circuit_breaker.failed_feature_ids.length !== 3) {
      throw new Error('missing failed feature ids');
    }
  "
}

@test "loop rejects disabling the circuit breaker without explicit danger acknowledgement" {
  cd "$PROJ_DIR"

  run bash "$ORCHESTRATE" loop feat-001 --circuit-breaker 0 --non-interactive --no-ui

  [ "$status" -eq 1 ]
  [[ "$output" == *"--circuit-breaker 0 disables a safety guard"* ]]
  [[ "$output" == *"--i-know-what-im-doing"* ]]
}

@test "loop --on-failure pause in non-tty stops with a clear message" {
  cd "$PROJ_DIR"
  failing_mock=$(make_failing_claude_mock)

  run env PATH="$failing_mock:$PATH" REAL_CLAUDE_MOCK="$MOCK_CLAUDE_DIR" PROGRESS_INTERVAL=0 \
    bash "$ORCHESTRATE" loop feat-001 feat-002 --on-failure pause --non-interactive --no-ui

  [ "$status" -eq 3 ]
  [[ "$output" == *"[1/2] feat-001 ✗ failed"* ]]
  [[ "$output" != *"[2/2] feat-002"* ]]
  [[ "$output" == *"pause requested but stdin is not a TTY"* ]]
}

@test "loop defaults checkpoint autonomy to pause on failure" {
  cd "$PROJ_DIR"
  node -e "
    const fs = require('fs');
    const file = '$PROJ_DIR/.monozukuri/config.yaml';
    fs.writeFileSync(file, fs.readFileSync(file, 'utf8').replace('autonomy: full_auto', 'autonomy: checkpoint'));
  "
  failing_mock=$(make_failing_claude_mock)

  run env PATH="$failing_mock:$PATH" REAL_CLAUDE_MOCK="$MOCK_CLAUDE_DIR" PROGRESS_INTERVAL=0 \
    bash "$ORCHESTRATE" loop feat-001 feat-002 --non-interactive --no-ui

  [ "$status" -eq 3 ]
  [[ "$output" == *"[1/2] feat-001 ✗ failed"* ]]
  [[ "$output" != *"[2/2] feat-002"* ]]
  [[ "$output" == *"pause requested but stdin is not a TTY"* ]]
}

@test "loop defaults full_auto autonomy to continue on failure" {
  cd "$PROJ_DIR"
  failing_mock=$(make_failing_claude_mock)

  run env PATH="$failing_mock:$PATH" REAL_CLAUDE_MOCK="$MOCK_CLAUDE_DIR" PROGRESS_INTERVAL=0 \
    bash "$ORCHESTRATE" loop feat-001 feat-002 --non-interactive --no-ui

  [ "$status" -eq 1 ]
  [[ "$output" == *"[1/2] feat-001 ✗ failed"* ]]
  [[ "$output" == *"[2/2] feat-002 ✓ done"* ]]
}

@test "loop defaults supervised autonomy to pause on failure" {
  cd "$PROJ_DIR"
  node -e "
    const fs = require('fs');
    const file = '$PROJ_DIR/.monozukuri/config.yaml';
    fs.writeFileSync(file, fs.readFileSync(file, 'utf8').replace('autonomy: full_auto', 'autonomy: supervised'));
  "
  failing_mock=$(make_failing_claude_mock)

  run env PATH="$failing_mock:$PATH" REAL_CLAUDE_MOCK="$MOCK_CLAUDE_DIR" PROGRESS_INTERVAL=0 \
    bash "$ORCHESTRATE" loop feat-001 feat-002 --non-interactive --no-ui

  [ "$status" -eq 3 ]
  [[ "$output" == *"[1/2] feat-001 ✗ failed"* ]]
  [[ "$output" != *"[2/2] feat-002"* ]]
  [[ "$output" == *"pause requested but stdin is not a TTY"* ]]
}
