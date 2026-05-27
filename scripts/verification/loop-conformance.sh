#!/bin/bash
# VRF-02: Loop conformance across mock Claude Code, Codex, and Gemini adapters.
set -euo pipefail

TASK_COUNT=3
OUT_DIR=".qa/reports/loop-conformance"
AGENTS_CSV="claude-code,codex,gemini"
TASK_TIMEOUT_SECONDS="${MONOZUKURI_VERIFY_TASK_TIMEOUT_SECONDS:-180}"

usage() {
  cat <<'EOF'
Usage: scripts/verification/loop-conformance.sh [--tasks N] [--agents a,b,c] [--out-dir DIR] [--task-timeout-seconds N]

Runs monozukuri loop against mock fixtures for each agent and compares
orchestration behavior, checkpoint structure, and summary report shape.
EOF
}

while [ $# -gt 0 ]; do
  case "$1" in
    --tasks)
      shift; TASK_COUNT="$1"
      ;;
    --agents)
      shift; AGENTS_CSV="$1"
      ;;
    --out-dir)
      shift; OUT_DIR="$1"
      ;;
    --task-timeout-seconds)
      shift; TASK_TIMEOUT_SECONDS="$1"
      ;;
    --help|-h)
      usage
      exit 0
      ;;
    *)
      echo "Unknown argument: $1" >&2
      usage >&2
      exit 2
      ;;
  esac
  shift
done

if ! [[ "$TASK_COUNT" =~ ^[0-9]+$ ]] || [ "$TASK_COUNT" -lt 1 ]; then
  echo "--tasks must be a positive integer" >&2
  exit 2
fi
if ! [[ "$TASK_TIMEOUT_SECONDS" =~ ^[0-9]+$ ]] || [ "$TASK_TIMEOUT_SECONDS" -lt 1 ]; then
  echo "--task-timeout-seconds must be a positive integer" >&2
  exit 2
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
ORCHESTRATE="$REPO_ROOT/orchestrate.sh"
WITH_TIMEOUT="$SCRIPT_DIR/with-timeout.sh"
mkdir -p "$OUT_DIR"
OUT_DIR="$(cd "$OUT_DIR" && pwd)"

agent_path() {
  case "$1" in
    claude-code) printf '%s/.qa/fixtures/mocks/claude\n' "$REPO_ROOT" ;;
    codex) printf '%s/.qa/fixtures/mocks/codex\n' "$REPO_ROOT" ;;
    gemini) printf '%s/.qa/fixtures/mocks/gemini\n' "$REPO_ROOT" ;;
    *)
      echo "Unsupported conformance agent: $1" >&2
      return 1
      ;;
  esac
}

write_project() {
  local project_dir="$1" agent="$2"
  mkdir -p "$project_dir/.monozukuri"
  git -C "$project_dir" init -b main -q 2>/dev/null \
    || git -C "$project_dir" init -q 2>/dev/null || true
  git -C "$project_dir" -c user.email="test@test.local" -c user.name="Test" \
    commit -q --allow-empty -m "init" 2>/dev/null || true

  : > "$project_dir/features.md"
  local index
  for index in $(seq 1 "$TASK_COUNT"); do
    cat >> "$project_dir/features.md" <<EOF
## [FEAT] feat-00${index}: Loop conformance feature ${index}
- priority: high

Build loop conformance feature ${index}.

EOF
  done

  cat > "$project_dir/.monozukuri/config.yaml" <<EOF
source:
  adapter: markdown
  markdown:
    file: features.md
autonomy: full_auto
execution:
  base_branch: main
agent: ${agent}
pr_creation:
  strategy: none
worktrees:
  auto_cleanup: false
safety:
  breaking_change_pause: false
  max_file_changes: 50
EOF
}

feature_ids() {
  local index out=""
  for index in $(seq 1 "$TASK_COUNT"); do
    if [ -n "$out" ]; then
      out="$out feat-00${index}"
    else
      out="feat-00${index}"
    fi
  done
  printf '%s\n' "$out"
}

run_agent() {
  local agent="$1"
  local run_dir="$OUT_DIR/$agent"
  local project_dir="$run_dir/project"
  local mock_path
  mock_path="$(agent_path "$agent")"
  mkdir -p "$run_dir"
  write_project "$project_dir" "$agent"

  local stdout_file="$run_dir/stdout.txt" stderr_file="$run_dir/stderr.txt"
  local exit_code=0 ids
  ids="$(feature_ids)"
  PATH="$mock_path:$PATH" \
    PROGRESS_INTERVAL=0 \
    MONOZUKURI_HOME="$REPO_ROOT" \
    "$WITH_TIMEOUT" --label "loop-conformance:$agent" --seconds "$TASK_TIMEOUT_SECONDS" -- \
    bash -c 'cd "$1" && bash "$2" loop $3 --non-interactive --no-ui' \
    _ "$project_dir" "$ORCHESTRATE" "$ids" \
    > "$stdout_file" 2> "$stderr_file" || exit_code=$?

  local state_dir
  state_dir=$(find "$project_dir/.monozukuri/state" -maxdepth 1 -type d -name 'loop-*' | sort | tail -1)
  if [ -z "$state_dir" ]; then
    echo "No loop state created for $agent" >&2
    return 1
  fi
  cp "$state_dir/manifest.json" "$run_dir/manifest.json"
  cp "$state_dir/checkpoint.json" "$run_dir/checkpoint.json"
  cp "$state_dir/progress.jsonl" "$run_dir/progress.jsonl"
  cp "$state_dir/summary.md" "$run_dir/summary.md"

  node - "$run_dir" "$agent" "$exit_code" <<'JSEOF'
const fs = require('fs');
const path = require('path');
const [,, runDir, agent, exitCodeRaw] = process.argv;
function readJson(name) {
  return JSON.parse(fs.readFileSync(path.join(runDir, name), 'utf8'));
}
function eventSequence(progressPath) {
  const events = [];
  const seenCost = new Set();
  for (const line of fs.readFileSync(progressPath, 'utf8').split(/\n/).filter(Boolean)) {
    let event;
    try {
      event = JSON.parse(line);
    } catch {
      continue;
    }
    if (event.event === 'phase.cost_recorded') {
      const task = event.task_id || '';
      if (seenCost.has(task)) continue;
      seenCost.add(task);
    }
    if (['loop.started', 'task.started', 'phase.cost_recorded', 'task.completed', 'loop.completed'].includes(event.event)) {
      events.push(event.event);
    }
  }
  return events;
}
function summaryShape(summaryPath) {
  return fs.readFileSync(summaryPath, 'utf8')
    .split(/\n/)
    .filter((line) => /^\|/.test(line))
    .map((line, index) => {
      if (index < 2) return line;
      const cells = line.split('|').slice(1, -1).map((cell) => cell.trim());
      if (cells.length >= 7) {
        cells[2] = '<phases>';
        cells[3] = '<tokens>';
        cells[4] = '$<cost>';
        cells[5] = '<duration>';
        cells[6] = cells[6] ? '<pr>' : '';
      }
      return `| ${cells.join(' | ')} |`;
    });
}
const manifest = readJson('manifest.json');
const checkpoint = readJson('checkpoint.json');
const taskStatuses = (manifest.tasks || []).map((task) => `${task.id}:${task.status}`);
const payload = {
  agent,
  exit_code: Number(exitCodeRaw),
  manifest_status: manifest.status,
  checkpoint_status: checkpoint.status,
  task_statuses: taskStatuses,
  manifest_keys: Object.keys(manifest).sort(),
  checkpoint_keys: Object.keys(checkpoint).sort(),
  event_sequence: eventSequence(path.join(runDir, 'progress.jsonl')),
  summary_shape: summaryShape(path.join(runDir, 'summary.md'))
};
fs.writeFileSync(path.join(runDir, 'normalized.json'), JSON.stringify(payload, null, 2) + '\n');
JSEOF
}

IFS=',' read -r -a AGENTS <<< "$AGENTS_CSV"
for agent in "${AGENTS[@]}"; do
  run_agent "$agent"
done

node - "$OUT_DIR" "$TASK_COUNT" "${AGENTS[@]}" <<'JSEOF'
const fs = require('fs');
const path = require('path');
const [,, outDir, taskCountRaw, ...agents] = process.argv;
const runs = agents.map((agent) => JSON.parse(fs.readFileSync(path.join(outDir, agent, 'normalized.json'), 'utf8')));
const baseline = runs[0];
const diffs = [];
function same(left, right) {
  return JSON.stringify(left) === JSON.stringify(right);
}
for (const run of runs) {
  if (run.exit_code !== 0) diffs.push(`${run.agent}: loop exited ${run.exit_code}`);
  if (run.manifest_status !== 'completed') diffs.push(`${run.agent}: manifest status ${run.manifest_status}`);
  if (run.checkpoint_status !== 'completed') diffs.push(`${run.agent}: checkpoint status ${run.checkpoint_status}`);
  if (!same(run.task_statuses, baseline.task_statuses)) diffs.push(`${run.agent}: task statuses differ`);
  if (!same(run.manifest_keys, baseline.manifest_keys)) diffs.push(`${run.agent}: manifest shape differs`);
  if (!same(run.checkpoint_keys, baseline.checkpoint_keys)) diffs.push(`${run.agent}: checkpoint shape differs`);
  if (!same(run.event_sequence, baseline.event_sequence)) diffs.push(`${run.agent}: event sequence differs`);
  if (!same(run.summary_shape, baseline.summary_shape)) diffs.push(`${run.agent}: summary shape differs`);
}
const report = {
  schema_version: 1,
  generated_at: new Date().toISOString(),
  agents,
  task_count: Number(taskCountRaw),
  pass: diffs.length === 0,
  diffs,
  runs
};
fs.writeFileSync(path.join(outDir, 'report.json'), JSON.stringify(report, null, 2) + '\n');
const summary = [
  '# Loop Conformance Suite',
  '',
  `Generated: ${report.generated_at}`,
  '',
  '| Agent | Exit | Manifest | Checkpoint | Tasks | Gate |',
  '| --- | ---: | --- | --- | --- | --- |',
  ...runs.map((run) => `| ${run.agent} | ${run.exit_code} | ${run.manifest_status} | ${run.checkpoint_status} | ${run.task_statuses.join(', ')} | ${report.pass ? 'PASS' : 'FAIL'} |`),
  '',
  report.pass ? 'Gate: PASS' : `Gate: FAIL\n\n${diffs.map((diff) => `- ${diff}`).join('\n')}`,
  ''
].join('\n');
fs.writeFileSync(path.join(outDir, 'summary.md'), summary);
console.log(`Loop conformance: ${report.pass ? 'PASS' : 'FAIL'}`);
console.log(`report: ${path.join(outDir, 'report.json')}`);
console.log(`dashboard: ${path.join(outDir, 'summary.md')}`);
process.exit(report.pass ? 0 : 1);
JSEOF
