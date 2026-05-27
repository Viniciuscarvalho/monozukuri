#!/usr/bin/env bats
# test/integration/loop_command.bats — smoke tests for monozukuri loop

REPO_ROOT="$(cd "$(dirname "$BATS_TEST_FILENAME")/../.." && pwd)"
ORCHESTRATE="$REPO_ROOT/orchestrate.sh"
MOCK_CLAUDE_DIR="$REPO_ROOT/.qa/fixtures/mocks/claude"
MOCK_CODEX_DIR="$REPO_ROOT/.qa/fixtures/mocks/codex"

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

## [FEAT] feat-004: Fourth loop feature
- priority: low

Build the fourth mocked loop feature.

## [FEAT] feat-005: Fifth loop feature
- priority: low

Build the fifth mocked loop feature.
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

make_slow_claude_mock() {
  local mock_dir="$TMPDIR_TEST/slow-claude"
  mkdir -p "$mock_dir"
  cat >"$mock_dir/claude" <<'EOFMOCK'
#!/bin/bash
set -euo pipefail

for arg in "$@"; do
  if [ "$arg" = "--version" ]; then
    echo "claude 1.0.0-slow-mock"
    exit 0
  fi
done

if [ "${1:-}" = "auth" ] && [ "${2:-}" = "status" ]; then
  echo "Authenticated as slow-mock@example.com"
  exit 0
fi

sleep "${SLOW_CLAUDE_DELAY:-0.2}"
exec "$REAL_CLAUDE_MOCK/claude" "$@"
EOFMOCK
  chmod +x "$mock_dir/claude"
  printf '%s\n' "$mock_dir"
}

make_model_asserting_codex_mock() {
  local mock_dir="$TMPDIR_TEST/model-asserting-codex"
  mkdir -p "$mock_dir"
  cat >"$mock_dir/codex" <<'EOFMOCK'
#!/bin/bash
set -euo pipefail

printf '%s\n' "$*" >> "${CODEX_ARGS_FILE:?missing CODEX_ARGS_FILE}"

for arg in "$@"; do
  if [ "$arg" = "opusplan" ]; then
    echo "unexpected codex model: opusplan" >&2
    exit 42
  fi
done

case " $* " in
  *" --model gpt-5.5 "*) ;;
  *" --version "*|*" login status "*) ;;
  *)
    echo "missing expected codex model gpt-5.5: $*" >&2
    exit 43
    ;;
esac

exec "$REAL_CODEX_MOCK/codex" "$@"
EOFMOCK
  chmod +x "$mock_dir/codex"
  printf '%s\n' "$mock_dir"
}

make_resume_tracking_claude_mock() {
  local mock_dir="$TMPDIR_TEST/resume-tracking-claude"
  mkdir -p "$mock_dir"
  cat >"$mock_dir/claude" <<'EOFMOCK'
#!/bin/bash
set -euo pipefail

for arg in "$@"; do
  if [ "$arg" = "--version" ]; then
    echo "claude 1.0.0-resume-tracking-mock"
    exit 0
  fi
done

if [ "${1:-}" = "auth" ] && [ "${2:-}" = "status" ]; then
  echo "Authenticated as resume-tracking-mock@example.com"
  exit 0
fi

if [ "${MONOZUKURI_PHASE:-}" = "code" ]; then
  printf '%s\n' "${MONOZUKURI_FEATURE_ID:-unknown}" >>"${RESUME_TRACK_FILE:?}"
  if [ "${MONOZUKURI_FEATURE_ID:-}" = "feat-003" ] && \
     [ "${RESUME_BLOCK_ON_FEAT3:-0}" = "1" ] && \
     [ ! -f "${RESUME_RELEASE_FILE:?}" ]; then
    touch "${RESUME_FEAT3_STARTED:?}"
    while [ ! -f "$RESUME_RELEASE_FILE" ]; do
      sleep 0.1
    done
  fi
fi

exec "$REAL_CLAUDE_MOCK/claude" "$@"
EOFMOCK
  chmod +x "$mock_dir/claude"
  printf '%s\n' "$mock_dir"
}

seed_loop_run() {
  local run_id="$1" run_status="$2" task_spec="$3" total_usd="${4:-0}"
  local state_dir="$PROJ_DIR/.monozukuri/state/$run_id"
  mkdir -p "$state_dir" "$PROJ_DIR/.monozukuri/runs/$run_id"
  node - "$state_dir" "$run_id" "$run_status" "$task_spec" "$total_usd" <<'JSEOF'
const [,, stateDir, runId, runStatus, taskSpec, totalUsd] = process.argv;
const fs = require('fs');
const path = require('path');
const now = new Date().toISOString();
const tasks = taskSpec.split(',').filter(Boolean).map((pair, index) => {
  const [id, status] = pair.split(':');
  return { id, order: index + 1, status, updated_at: now };
});
const next = tasks.find((task) => !['completed', 'skipped', 'failed'].includes(task.status));
const manifest = {
  schema_version: 1,
  run_id: runId,
  status: runStatus,
  started_at: now,
  updated_at: now,
  tasks
};
if (runStatus === 'completed') manifest.completed_at = now;
const checkpoint = {
  schema_version: 1,
  run_id: runId,
  status: runStatus,
  last_safe_task_id: '',
  next_task_index: next ? next.order : tasks.length + 1,
  next_task_id: next ? next.id : '',
  updated_at: now
};
const cost = {
  schema_version: 1,
  run_id: runId,
  status: runStatus,
  started_at: now,
  limit_usd: 10,
  limit_minutes: 480,
  max_tokens_per_task: 100000,
  total_usd: Number(totalUsd),
  total_tokens: 0,
  phase_events: Number(totalUsd) > 0 ? [{
    feature_id: 'previous',
    phase: 'seed',
    estimated_tokens: 0,
    estimated_usd: Number(totalUsd),
    recorded_at: now
  }] : [],
  features: []
};
fs.writeFileSync(path.join(stateDir, 'manifest.json'), JSON.stringify(manifest, null, 2));
fs.writeFileSync(path.join(stateDir, 'checkpoint.json'), JSON.stringify(checkpoint, null, 2));
fs.writeFileSync(path.join(stateDir, 'cost.json'), JSON.stringify(cost, null, 2));
fs.writeFileSync(path.join(stateDir, 'progress.jsonl'), '');
fs.copyFileSync(path.join(stateDir, 'cost.json'), path.join(path.dirname(path.dirname(stateDir)), 'runs', runId, 'cost.json'));
JSEOF
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
  [[ "$output" == *"--resume [run-id]"* ]]
  [[ "$output" == *"--retry-failed"* ]]
  [[ "$output" == *"--list-runs"* ]]
  [[ "$output" == *"monozukuri loop status [run-id]"* ]]
  [[ "$output" == *"--follow"* ]]
  [[ "$output" == *"--report-format ascii|md"* ]]
}

@test "loop runs three selected features with mocked pipeline and preserves loop worktrees" {
  cd "$PROJ_DIR"
  run env PATH="$MOCK_CLAUDE_DIR:$PATH" PROGRESS_INTERVAL=0 \
    bash "$ORCHESTRATE" loop feat-001 feat-002 feat-003 --non-interactive --no-ui

  [ "$status" -eq 0 ]
  [[ "$output" == *"[1/3] feat-001 ✓ done"* ]]
  [[ "$output" == *"[2/3] feat-002 ✓ done"* ]]
  [[ "$output" == *"[3/3] feat-003 ✓ done"* ]]
  [[ "$output" == *"+-"* ]]
  [[ "$output" == *"| ID       | Status"* ]]

  loop_dir_count=$(find "$PROJ_DIR/.monozukuri/worktrees" -maxdepth 1 -type d -name 'loop-*' | wc -l | tr -d ' ')
  [ "$loop_dir_count" -eq 1 ]
  [ -d "$PROJ_DIR/.monozukuri/worktrees"/loop-*/feat-001 ]
  [ -d "$PROJ_DIR/.monozukuri/worktrees"/loop-*/feat-002 ]
  [ -d "$PROJ_DIR/.monozukuri/worktrees"/loop-*/feat-003 ]
}

@test "loop prints and persists markdown summary report" {
  cd "$PROJ_DIR"
  run env PATH="$MOCK_CLAUDE_DIR:$PATH" PROGRESS_INTERVAL=0 \
    bash "$ORCHESTRATE" loop feat-001 --report-format md --non-interactive --no-ui

  [ "$status" -eq 0 ]
  [[ "$output" == *"| ID | Status | Phases done | Tokens | Cost | Duration | PR URL |"* ]]
  [[ "$output" == *"| feat-001 | completed |"* ]]
  [[ "$output" == *"| TOTAL | completed |"* ]]

  loop_state_dir=$(find "$PROJ_DIR/.monozukuri/state" -maxdepth 1 -type d -name 'loop-*' | head -1)
  [ -n "$loop_state_dir" ]
  [ -f "$loop_state_dir/summary.md" ]
  grep -q "| ID | Status | Phases done | Tokens | Cost | Duration | PR URL |" "$loop_state_dir/summary.md"
  grep -q "| feat-001 | completed |" "$loop_state_dir/summary.md"
  grep -q "| TOTAL | completed |" "$loop_state_dir/summary.md"
}

@test "loop summary snapshot includes completed failed and skipped statuses" {
  cd "$PROJ_DIR"
  failing_mock=$(make_failing_claude_mock)

  run env PATH="$failing_mock:$PATH" REAL_CLAUDE_MOCK="$MOCK_CLAUDE_DIR" PROGRESS_INTERVAL=0 \
    bash "$ORCHESTRATE" loop feat-001 missing-feature feat-002 --on-failure continue --report-format md --non-interactive --no-ui

  [ "$status" -eq 1 ]
  loop_state_dir=$(find "$PROJ_DIR/.monozukuri/state" -maxdepth 1 -type d -name 'loop-*' | head -1)
  [ -n "$loop_state_dir" ]
  [ -f "$loop_state_dir/summary.md" ]

  normalized=$(node - "$loop_state_dir/summary.md" <<'JSEOF'
const fs = require('fs');
const file = process.argv[2];
const lines = fs.readFileSync(file, 'utf8').trim().split(/\n/);
const output = lines.map((line, index) => {
  if (index < 2) return line;
  const cells = line.split('|').slice(1, -1).map((cell) => cell.trim());
  cells[2] = '<phases>';
  cells[3] = '<tokens>';
  cells[4] = '$<cost>';
  cells[5] = '<duration>';
  return `| ${cells.join(' | ')} |`;
});
process.stdout.write(output.join('\n'));
JSEOF
)
  expected='| ID | Status | Phases done | Tokens | Cost | Duration | PR URL |
| --- | --- | ---: | ---: | ---: | ---: | --- |
| feat-001 | failed | <phases> | <tokens> | $<cost> | <duration> |  |
| missing-feature | skipped | <phases> | <tokens> | $<cost> | <duration> |  |
| feat-002 | completed | <phases> | <tokens> | $<cost> | <duration> |  |
| TOTAL | failed | <phases> | <tokens> | $<cost> | <duration> |  |'
  [ "$normalized" = "$expected" ]
}

@test "loop full_auto stdout includes structured progress lines" {
  cd "$PROJ_DIR"
  run env PATH="$MOCK_CLAUDE_DIR:$PATH" PROGRESS_INTERVAL=0 \
    bash "$ORCHESTRATE" loop feat-001 --non-interactive --no-ui

  [ "$status" -eq 0 ]
  [[ "$output" =~ \[[0-9]{2}:[0-9]{2}:[0-9]{2}\]\ \[feat-001\]\ \[-\]\ task.started\ running ]]
  [[ "$output" =~ \[[0-9]{2}:[0-9]{2}:[0-9]{2}\]\ \[feat-001\]\ \[phase[0-9]\]\ phase.cost_recorded\ recorded ]]
  [[ "$output" =~ \[[0-9]{2}:[0-9]{2}:[0-9]{2}\]\ \[feat-001\]\ \[-\]\ task.completed\ completed ]]
}

@test "loop writes progress jsonl in supervised mode" {
  cd "$PROJ_DIR"
  node - "$PROJ_DIR/.monozukuri/config.yaml" <<'JSEOF'
const fs = require('fs');
const file = process.argv[2];
fs.writeFileSync(file, fs.readFileSync(file, 'utf8').replace('autonomy: full_auto', 'autonomy: supervised'));
JSEOF

  run env PATH="$MOCK_CLAUDE_DIR:$PATH" PROGRESS_INTERVAL=0 \
    bash "$ORCHESTRATE" loop feat-001 --non-interactive --no-ui

  [ "$status" -eq 0 ]
  loop_state_dir=$(find "$PROJ_DIR/.monozukuri/state" -maxdepth 1 -type d -name 'loop-*' | head -1)
  [ -n "$loop_state_dir" ]
  grep -q '"event":"task.started"' "$loop_state_dir/progress.jsonl"
  grep -q '"event":"task.completed"' "$loop_state_dir/progress.jsonl"
}

@test "loop persists checkpoint schema files for a completed run" {
  cd "$PROJ_DIR"
  run env PATH="$MOCK_CLAUDE_DIR:$PATH" PROGRESS_INTERVAL=0 \
    bash "$ORCHESTRATE" loop feat-001 --non-interactive --no-ui

  [ "$status" -eq 0 ]

  loop_state_dir=$(find "$PROJ_DIR/.monozukuri/state" -maxdepth 1 -type d -name 'loop-*' | head -1)
  [ -n "$loop_state_dir" ]
  [ -f "$loop_state_dir/manifest.json" ]
  [ -f "$loop_state_dir/progress.jsonl" ]
  [ -f "$loop_state_dir/cost.json" ]
  [ -f "$loop_state_dir/checkpoint.json" ]

  node -e "
    const fs = require('fs');
    const path = '$loop_state_dir';
    const manifest = JSON.parse(fs.readFileSync(path + '/manifest.json', 'utf8'));
    const cost = JSON.parse(fs.readFileSync(path + '/cost.json', 'utf8'));
    const checkpoint = JSON.parse(fs.readFileSync(path + '/checkpoint.json', 'utf8'));
    const lines = fs.readFileSync(path + '/progress.jsonl', 'utf8').trim().split(/\n+/).filter(Boolean).map(JSON.parse);
    if (manifest.run_id !== path.split('/').pop()) throw new Error('manifest run_id mismatch');
    if (!Array.isArray(manifest.tasks) || manifest.tasks.length !== 1) throw new Error('missing manifest task');
    if (manifest.tasks[0].id !== 'feat-001') throw new Error('wrong task id');
    if (manifest.tasks[0].order !== 1) throw new Error('wrong task order');
    if (manifest.tasks[0].status !== 'completed') throw new Error('wrong task status');
    if (cost.run_id !== manifest.run_id) throw new Error('cost run_id mismatch');
    if (!Array.isArray(cost.phase_events) || cost.phase_events.length === 0) throw new Error('missing cost phase events');
    if (checkpoint.status !== 'completed') throw new Error('wrong checkpoint status');
    if (checkpoint.next_task_index !== 2) throw new Error('wrong checkpoint next index');
    if (!lines.some((entry) => entry.event === 'task.completed' && entry.task_id === 'feat-001')) {
      throw new Error('missing task completed progress event');
    }
    if (!lines.some((entry) => entry.event === 'phase.cost_recorded' && entry.task_id === 'feat-001')) {
      throw new Error('missing phase progress event');
    }
  "
}

@test "loop checkpoint files stay parseable across interrupted runs" {
  cd "$PROJ_DIR"
  slow_mock=$(make_slow_claude_mock)

  for delay in 0.05 0.10 0.15 0.20 0.25 0.30 0.35 0.40 0.45 0.50; do
    env PATH="$slow_mock:$PATH" REAL_CLAUDE_MOCK="$MOCK_CLAUDE_DIR" SLOW_CLAUDE_DELAY=0.25 PROGRESS_INTERVAL=0 \
      bash "$ORCHESTRATE" loop feat-001 --non-interactive --no-ui \
      >"$TMPDIR_TEST/interrupted-$delay.out" 2>"$TMPDIR_TEST/interrupted-$delay.err" &
    loop_pid=$!
    sleep "$delay"
    kill -INT "$loop_pid" 2>/dev/null || true
    wait "$loop_pid" 2>/dev/null || true

    while IFS= read -r json_file; do
      node -e "JSON.parse(require('fs').readFileSync(process.argv[1], 'utf8'))" "$json_file"
    done < <(find "$PROJ_DIR/.monozukuri/state" -path '*/loop-*/*.json' -type f 2>/dev/null)

    while IFS= read -r progress_file; do
      node -e "
        const fs = require('fs');
        const lines = fs.readFileSync(process.argv[1], 'utf8').split(/\n/).filter(Boolean);
        for (const line of lines) JSON.parse(line);
      " "$progress_file"
    done < <(find "$PROJ_DIR/.monozukuri/state" -path '*/loop-*/progress.jsonl' -type f 2>/dev/null)
  done
}

@test "loop maps default model to the active non-Claude agent" {
  cd "$PROJ_DIR"
  codex_mock=$(make_model_asserting_codex_mock)
  args_file="$TMPDIR_TEST/codex-args.txt"
  : >"$args_file"

  run env PATH="$codex_mock:$PATH" REAL_CODEX_MOCK="$MOCK_CODEX_DIR" \
    CODEX_ARGS_FILE="$args_file" PROGRESS_INTERVAL=0 \
    bash "$ORCHESTRATE" loop feat-001 --agent codex --non-interactive --no-ui

  [ "$status" -eq 0 ]
  grep -q -- "--model gpt-5.5" "$args_file"
  ! grep -q -- "opusplan" "$args_file"
}

@test "loop reads feature IDs from stdin when no positional IDs are provided" {
  cd "$PROJ_DIR"
  run bash -c 'printf "%s\n" feat-001 | PATH="$1:$PATH" PROGRESS_INTERVAL=0 bash "$2" loop --non-interactive --no-ui' \
    _ "$MOCK_CLAUDE_DIR" "$ORCHESTRATE"

  [ "$status" -eq 0 ]
  [[ "$output" == *"[1/1] feat-001 ✓ done"* ]]
}

@test "loop stdin ignores blank lines and comments" {
  cd "$PROJ_DIR"
  run bash -c '
    printf "%s\n" "" "# picked by script" "feat-001" "   " "  # trailing comment" "feat-002" |
      PATH="$1:$PATH" PROGRESS_INTERVAL=0 bash "$2" loop --non-interactive --no-ui
  ' _ "$MOCK_CLAUDE_DIR" "$ORCHESTRATE"

  [ "$status" -eq 0 ]
  [[ "$output" == *"[1/2] feat-001 ✓ done"* ]]
  [[ "$output" == *"[2/2] feat-002 ✓ done"* ]]
}

@test "loop composes with pick top IDs over stdin" {
  cd "$PROJ_DIR"
  run bash -c '
    PATH="$1:$PATH" PROGRESS_INTERVAL=0 bash "$2" pick --top 2 |
      PATH="$1:$PATH" PROGRESS_INTERVAL=0 bash "$2" loop --non-interactive --no-ui
  ' _ "$MOCK_CLAUDE_DIR" "$ORCHESTRATE"

  [ "$status" -eq 0 ]
  [[ "$output" == *"[1/2] feat-001 ✓ done"* ]]
  [[ "$output" == *"[2/2] feat-002 ✓ done"* ]]
}

@test "loop composes with pick json and jq ids over stdin" {
  cd "$PROJ_DIR"
  run bash -c '
    PATH="$1:$PATH" PROGRESS_INTERVAL=0 bash "$2" pick --top 2 --json |
      jq -r ".[].id" |
      PATH="$1:$PATH" PROGRESS_INTERVAL=0 bash "$2" loop --non-interactive --no-ui
  ' _ "$MOCK_CLAUDE_DIR" "$ORCHESTRATE"

  [ "$status" -eq 0 ]
  [[ "$output" == *"[1/2] feat-001 ✓ done"* ]]
  [[ "$output" == *"[2/2] feat-002 ✓ done"* ]]
}

@test "loop reports missing IDs and continues with later selected features" {
  cd "$PROJ_DIR"
  run env PATH="$MOCK_CLAUDE_DIR:$PATH" PROGRESS_INTERVAL=0 \
    bash "$ORCHESTRATE" loop missing-feature feat-001 --non-interactive --no-ui

  [ "$status" -eq 1 ]
  [[ "$output" == *"[1/2] missing-feature ✗ not found"* ]]
  [[ "$output" == *"[2/2] feat-001 ✓ done"* ]]

  loop_state_dir=$(find "$PROJ_DIR/.monozukuri/state" -maxdepth 1 -type d -name 'loop-*' | head -1)
  [ -n "$loop_state_dir" ]
  node -e "
    const fs = require('fs');
    const manifest = JSON.parse(fs.readFileSync('$loop_state_dir/manifest.json', 'utf8'));
    const missing = manifest.tasks.find((task) => task.id === 'missing-feature');
    const completed = manifest.tasks.find((task) => task.id === 'feat-001');
    if (!missing || missing.status !== 'skipped') throw new Error('missing feature was not skipped');
    if (!completed || completed.status !== 'completed') throw new Error('feat-001 was not completed');
  "
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

  loop_state_dir=$(find "$PROJ_DIR/.monozukuri/state" -maxdepth 1 -type d -name 'loop-*' | head -1)
  [ -n "$loop_state_dir" ]
  node -e "
    const fs = require('fs');
    const manifest = JSON.parse(fs.readFileSync('$loop_state_dir/manifest.json', 'utf8'));
    const failed = manifest.tasks.find((task) => task.id === 'feat-001');
    const completed = manifest.tasks.find((task) => task.id === 'feat-002');
    if (!failed || failed.status !== 'failed') throw new Error('feat-001 was not failed');
    if (!completed || completed.status !== 'completed') throw new Error('feat-002 was not completed');
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

@test "loop --list-runs shows only resumable loop runs" {
  cd "$PROJ_DIR"
  seed_loop_run "loop-2026-05-22-complete" "completed" "feat-001:completed"
  seed_loop_run "loop-2026-05-22-resumable" "running" "feat-001:completed,feat-002:running,feat-003:pending"

  run bash "$ORCHESTRATE" loop --list-runs --non-interactive --no-ui

  [ "$status" -eq 0 ]
  [[ "$output" == *"RUN_ID STATUS PENDING"* ]]
  [[ "$output" == *"loop-2026-05-22-resumable running 2"* ]]
  [[ "$output" != *"loop-2026-05-22-complete"* ]]
}

@test "loop status renders progress jsonl as structured lines" {
  cd "$PROJ_DIR"
  seed_loop_run "loop-2026-05-22-status" "running" "feat-001:running"
  progress_file="$PROJ_DIR/.monozukuri/state/loop-2026-05-22-status/progress.jsonl"
  cat >"$progress_file" <<'EOF'
{"schema_version":1,"run_id":"loop-2026-05-22-status","event":"task.started","ts":"2026-05-22T19:00:00.000Z","task_id":"feat-001","status":"running"}
{"schema_version":1,"run_id":"loop-2026-05-22-status","event":"phase.cost_recorded","ts":"2026-05-22T19:00:02.000Z","task_id":"feat-001","phase":"phase1","status":"recorded","detail":"tokens recorded"}
EOF

  run bash "$ORCHESTRATE" loop status loop-2026-05-22-status

  [ "$status" -eq 0 ]
  [[ "$output" == *"Run: loop-2026-05-22-status"* ]]
  [[ "$output" == *"[19:00:00] [feat-001] [-] task.started running"* ]]
  [[ "$output" == *"[19:00:02] [feat-001] [phase1] phase.cost_recorded recorded tokens recorded"* ]]
}

@test "loop status --follow prints appended progress updates" {
  cd "$PROJ_DIR"
  seed_loop_run "loop-2026-05-22-follow" "running" "feat-001:running"
  progress_file="$PROJ_DIR/.monozukuri/state/loop-2026-05-22-follow/progress.jsonl"
  printf '%s\n' \
    '{"schema_version":1,"run_id":"loop-2026-05-22-follow","event":"task.started","ts":"2026-05-22T19:00:00.000Z","task_id":"feat-001","status":"running"}' \
    >"$progress_file"

  bash "$ORCHESTRATE" loop status loop-2026-05-22-follow --follow \
    >"$TMPDIR_TEST/follow.out" 2>"$TMPDIR_TEST/follow.err" &
  follow_pid=$!

  sleep 0.2
  printf '%s\n' \
    '{"schema_version":1,"run_id":"loop-2026-05-22-follow","event":"phase.cost_recorded","ts":"2026-05-22T19:00:04.000Z","task_id":"feat-001","phase":"phase2","status":"recorded"}' \
    >>"$progress_file"

  for _ in 1 2 3 4 5 6 7 8 9 10; do
    grep -q "\\[19:00:04\\] \\[feat-001\\] \\[phase2\\] phase.cost_recorded recorded" "$TMPDIR_TEST/follow.out" && break
    sleep 0.5
  done
  kill "$follow_pid" 2>/dev/null || true
  wait "$follow_pid" 2>/dev/null || true

  grep -q "Run: loop-2026-05-22-follow" "$TMPDIR_TEST/follow.out"
  grep -q "\\[19:00:04\\] \\[feat-001\\] \\[phase2\\] phase.cost_recorded recorded" "$TMPDIR_TEST/follow.out"
}

@test "loop --resume skips completed tasks and restarts running tasks in a new worktree" {
  cd "$PROJ_DIR"
  seed_loop_run "loop-2026-05-22-resume" "running" "feat-001:completed,feat-002:running,feat-003:pending"
  tracking_mock=$(make_resume_tracking_claude_mock)
  track_file="$TMPDIR_TEST/resume-track.txt"
  : >"$track_file"
  mkdir -p "$PROJ_DIR/.monozukuri/worktrees/loop-2026-05-22-resume/feat-002"

  run env PATH="$tracking_mock:$PATH" REAL_CLAUDE_MOCK="$MOCK_CLAUDE_DIR" \
    RESUME_TRACK_FILE="$track_file" PROGRESS_INTERVAL=0 \
    bash "$ORCHESTRATE" loop --resume loop-2026-05-22-resume --non-interactive --no-ui

  [ "$status" -eq 0 ]
  [[ "$output" == *"Resuming loop run: loop-2026-05-22-resume"* ]]
  [[ "$output" == *"[1/3] feat-001 ↷ skipped (completed)"* ]]
  [[ "$output" == *"[2/3] feat-002 ✓ done"* ]]
  [[ "$output" == *"[3/3] feat-003 ✓ done"* ]]
  ! grep -q '^feat-001$' "$track_file"
  grep -q '^feat-002$' "$track_file"
  grep -q '^feat-003$' "$track_file"
  [ -d "$PROJ_DIR/.monozukuri/worktrees/loop-2026-05-22-resume/feat-002" ]
  new_feat2=$(find "$PROJ_DIR/.monozukuri/worktrees" -path '*/loop-2026-05-22-resume-resume-*/feat-002' -type d | head -1)
  [ -n "$new_feat2" ]

  node -e "
    const fs = require('fs');
    const dir = '$PROJ_DIR/.monozukuri/state/loop-2026-05-22-resume';
    const manifest = JSON.parse(fs.readFileSync(dir + '/manifest.json', 'utf8'));
    const events = fs.readFileSync(dir + '/progress.jsonl', 'utf8').trim().split(/\n+/).filter(Boolean).map(JSON.parse);
    for (const id of ['feat-001', 'feat-002', 'feat-003']) {
      const task = manifest.tasks.find((entry) => entry.id === id);
      if (!task || task.status !== 'completed') throw new Error(id + ' not completed');
    }
    if (!events.some((entry) => entry.event === 'task.inconclusive' && entry.task_id === 'feat-002')) {
      throw new Error('missing inconclusive progress event');
    }
  "
}

@test "loop --resume skips failed tasks unless retry-failed is passed" {
  cd "$PROJ_DIR"
  tracking_mock=$(make_resume_tracking_claude_mock)
  track_file="$TMPDIR_TEST/retry-failed-track.txt"
  : >"$track_file"
  seed_loop_run "loop-2026-05-22-failed-skip" "failed" "feat-001:failed,feat-002:pending"

  run env PATH="$tracking_mock:$PATH" REAL_CLAUDE_MOCK="$MOCK_CLAUDE_DIR" \
    RESUME_TRACK_FILE="$track_file" PROGRESS_INTERVAL=0 \
    bash "$ORCHESTRATE" loop --resume loop-2026-05-22-failed-skip --non-interactive --no-ui

  [ "$status" -eq 1 ]
  [[ "$output" == *"[1/2] feat-001 ↷ skipped (failed)"* ]]
  [[ "$output" == *"[2/2] feat-002 ✓ done"* ]]
  ! grep -q '^feat-001$' "$track_file"
  grep -q '^feat-002$' "$track_file"

  : >"$track_file"
  seed_loop_run "loop-2026-05-22-failed-retry" "failed" "feat-001:failed"
  run env PATH="$tracking_mock:$PATH" REAL_CLAUDE_MOCK="$MOCK_CLAUDE_DIR" \
    RESUME_TRACK_FILE="$track_file" PROGRESS_INTERVAL=0 \
    bash "$ORCHESTRATE" loop --resume loop-2026-05-22-failed-retry --retry-failed --non-interactive --no-ui

  [ "$status" -eq 0 ]
  [[ "$output" == *"[1/1] feat-001 ✓ done"* ]]
  grep -q '^feat-001$' "$track_file"
}

@test "loop --resume applies max-cost to the accumulated run total" {
  cd "$PROJ_DIR"
  tracking_mock=$(make_resume_tracking_claude_mock)
  track_file="$TMPDIR_TEST/accumulated-cap-track.txt"
  : >"$track_file"
  seed_loop_run "loop-2026-05-22-cost-cap" "running" "feat-001:pending" "11"

  run env PATH="$tracking_mock:$PATH" REAL_CLAUDE_MOCK="$MOCK_CLAUDE_DIR" \
    RESUME_TRACK_FILE="$track_file" PROGRESS_INTERVAL=0 \
    bash "$ORCHESTRATE" loop --resume loop-2026-05-22-cost-cap --max-cost 10 --non-interactive --no-ui

  [ "$status" -eq 4 ]
  [[ "$output" == *"Resuming loop run: loop-2026-05-22-cost-cap"* ]]
  [[ "$output" != *"[1/1] feat-001"* ]]
  [[ "$output" == *"Loop cap reached: cost"* ]]
  [ ! -s "$track_file" ]

  node -e "
    const fs = require('fs');
    const cost = JSON.parse(fs.readFileSync('$PROJ_DIR/.monozukuri/state/loop-2026-05-22-cost-cap/cost.json', 'utf8'));
    if (cost.total_usd < 11) throw new Error('cost accumulator was reset');
    if (cost.status !== 'cap-reached') throw new Error('wrong cost status');
  "
}

@test "loop resumes after kill during code phase without rerunning completed tasks" {
  cd "$PROJ_DIR"
  tracking_mock=$(make_resume_tracking_claude_mock)
  track_file="$TMPDIR_TEST/kill-resume-track.txt"
  started_file="$TMPDIR_TEST/feat3-started"
  release_file="$TMPDIR_TEST/release-feat3"
  : >"$track_file"
  seed_loop_run "loop-2026-05-22-kill" "running" "feat-001:completed,feat-002:completed,feat-003:pending,feat-004:pending,feat-005:pending"
  run_id="loop-2026-05-22-kill"

  env PATH="$tracking_mock:$PATH" REAL_CLAUDE_MOCK="$MOCK_CLAUDE_DIR" \
    RESUME_TRACK_FILE="$track_file" RESUME_BLOCK_ON_FEAT3=1 \
    RESUME_FEAT3_STARTED="$started_file" RESUME_RELEASE_FILE="$release_file" \
    PROGRESS_INTERVAL=0 \
    bash "$ORCHESTRATE" loop --resume "$run_id" --max-tokens-per-task 500000 --non-interactive --no-ui \
    >"$TMPDIR_TEST/kill-loop.out" 2>"$TMPDIR_TEST/kill-loop.err" &
  loop_pid=$!

  for _ in $(seq 1 600); do
    [ -f "$started_file" ] && break
    sleep 0.1
  done
  [ -f "$started_file" ]
  inconclusive_feat3=$(find "$PROJ_DIR/.monozukuri/worktrees" -path "*/$run_id-resume-*/feat-003" -type d | head -1)
  [ -n "$inconclusive_feat3" ]

  kill -9 "$loop_pid" 2>/dev/null || true
  touch "$release_file"
  wait "$loop_pid" 2>/dev/null || true
  sleep 0.3

  run env PATH="$tracking_mock:$PATH" REAL_CLAUDE_MOCK="$MOCK_CLAUDE_DIR" \
    RESUME_TRACK_FILE="$track_file" PROGRESS_INTERVAL=0 \
    bash "$ORCHESTRATE" loop --resume "$run_id" --max-tokens-per-task 500000 --non-interactive --no-ui

  [ "$status" -eq 0 ]
  [[ "$output" == *"Resuming loop run: $run_id"* ]]
  [[ "$output" == *"[1/5] feat-001 ↷ skipped (completed)"* ]]
  [[ "$output" == *"[2/5] feat-002 ↷ skipped (completed)"* ]]
  [[ "$output" == *"[3/5] feat-003 ✓ done"* ]]
  [[ "$output" == *"[4/5] feat-004 ✓ done"* ]]
  [[ "$output" == *"[5/5] feat-005 ✓ done"* ]]

  [ "$(grep -c '^feat-001$' "$track_file" || true)" -eq 0 ]
  [ "$(grep -c '^feat-002$' "$track_file" || true)" -eq 0 ]
  [ "$(grep -c '^feat-003$' "$track_file")" -eq 2 ]
  [ "$(grep -c '^feat-004$' "$track_file")" -eq 1 ]
  [ "$(grep -c '^feat-005$' "$track_file")" -eq 1 ]
  [ -d "$inconclusive_feat3" ]
  new_feat3=$(find "$PROJ_DIR/.monozukuri/worktrees" -path "*/$run_id-resume-*/feat-003" -type d | grep -v "^$inconclusive_feat3$" | head -1)
  [ -n "$new_feat3" ]

  node -e "
    const fs = require('fs');
    const dir = '$PROJ_DIR/.monozukuri/state/$run_id';
    const manifest = JSON.parse(fs.readFileSync(dir + '/manifest.json', 'utf8'));
    const events = fs.readFileSync(dir + '/progress.jsonl', 'utf8').trim().split(/\n+/).filter(Boolean).map(JSON.parse);
    for (const task of manifest.tasks) {
      if (task.status !== 'completed') throw new Error(task.id + ' not completed');
    }
    if (!events.some((entry) => entry.event === 'task.inconclusive' && entry.task_id === 'feat-003')) {
      throw new Error('missing feat-003 inconclusive event');
    }
  "
}
