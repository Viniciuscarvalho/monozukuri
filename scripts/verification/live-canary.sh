#!/bin/bash
# VRF-03: pre-release live loop canary against the dedicated sandbox repo.
set -euo pipefail

MODE="plan"
AGENTS_CSV="claude-code,codex,gemini"
TASK_COUNT=2
MAX_COST="5"
SANDBOX_REPO="monozukuri/test-sandbox"
OUT_DIR=".qa/reports/live-canary"
MOCK_CI="success"

usage() {
  cat <<'EOF'
Usage: scripts/verification/live-canary.sh --live|--mock [flags]

Runs monozukuri loop --tasks 2 --agent <agent> against the sandbox repo and
requires two opened PRs with green sandbox CI per agent.

Flags:
  --live                    Clone monozukuri/test-sandbox through gh and use real agents
  --mock                    Use local sandbox, replay agents, and fake green gh checks
  --agents a,b,c            Agents to run (default: claude-code,codex,gemini)
  --tasks N                 Sandbox tasks per agent (default: 2)
  --max-cost USD            Total cost cap across all agents (default: 5)
  --sandbox-repo OWNER/REPO Dedicated sandbox repo (default: monozukuri/test-sandbox)
  --out-dir DIR             Report directory
  --mock-ci success|failure Mock-only PR check result
EOF
}

while [ $# -gt 0 ]; do
  case "$1" in
    --live)
      MODE="live"
      ;;
    --mock)
      MODE="mock"
      ;;
    --agents)
      shift; AGENTS_CSV="$1"
      ;;
    --tasks)
      shift; TASK_COUNT="$1"
      ;;
    --max-cost)
      shift; MAX_COST="$1"
      ;;
    --sandbox-repo)
      shift; SANDBOX_REPO="$1"
      ;;
    --out-dir)
      shift; OUT_DIR="$1"
      ;;
    --mock-ci)
      shift; MOCK_CI="$1"
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

if [ "$MODE" = "plan" ]; then
  usage >&2
  echo "Refusing to run live canary without --live or --mock." >&2
  exit 2
fi
if ! [[ "$TASK_COUNT" =~ ^[0-9]+$ ]] || [ "$TASK_COUNT" -lt 1 ]; then
  echo "--tasks must be a positive integer" >&2
  exit 2
fi
if ! awk -v n="$MAX_COST" 'BEGIN { exit !(n ~ /^[0-9]+([.][0-9]+)?$/ && n > 0 && n <= 5) }'; then
  echo "--max-cost must be a positive USD amount no greater than 5" >&2
  exit 2
fi
case "$MOCK_CI" in
  success|failure) ;;
  *) echo "--mock-ci must be success or failure" >&2; exit 2 ;;
esac

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
ORCHESTRATE="$REPO_ROOT/orchestrate.sh"
mkdir -p "$OUT_DIR"
OUT_DIR="$(cd "$OUT_DIR" && pwd)"
WORK_DIR="$OUT_DIR/work"
rm -rf "$WORK_DIR"
mkdir -p "$WORK_DIR"

IFS=',' read -r -a AGENTS <<< "$AGENTS_CSV"

agent_binary() {
  case "$1" in
    claude-code) printf 'claude\n' ;;
    codex) printf 'codex\n' ;;
    gemini) printf 'gemini\n' ;;
    *) echo "Unsupported canary agent: $1" >&2; return 1 ;;
  esac
}

require_live_tools() {
  command -v gh >/dev/null 2>&1 || { echo "gh CLI is required for live canary" >&2; return 1; }
  local agent bin
  for agent in "${AGENTS[@]}"; do
    bin="$(agent_binary "$agent")"
    command -v "$bin" >/dev/null 2>&1 || {
      echo "$bin CLI is required for live canary agent $agent" >&2
      return 1
    }
  done
}

write_mock_gh() {
  local bin_dir="$1" state_file="$2"
  mkdir -p "$bin_dir"
  printf '0\n' > "$state_file"
  cat > "$bin_dir/gh" <<'EOF'
#!/bin/bash
set -euo pipefail
state="${MONOZUKURI_CANARY_FAKE_GH_STATE:?missing fake gh state}"
case "${1:-}" in
  pr)
    case "${2:-}" in
      create)
        n=$(cat "$state" 2>/dev/null || echo 0)
        n=$((n + 1))
        printf '%s\n' "$n" > "$state"
        printf 'https://github.com/monozukuri/test-sandbox/pull/%s\n' "$n"
        ;;
      checks)
        printf '[{"name":"sandbox-ci","state":"COMPLETED","conclusion":"SUCCESS"}]\n'
        ;;
      view)
        printf '{"state":"OPEN","mergedAt":null}\n'
        ;;
      *)
        exit 0
        ;;
    esac
    ;;
  run)
    exit 0
    ;;
  repo)
    if [ "${2:-}" = "clone" ]; then
      git clone "$3" "$4"
    fi
    ;;
  *)
    exit 0
    ;;
esac
EOF
  chmod +x "$bin_dir/gh"
}

write_mock_sandbox() {
  local origin_dir="$1" seed_dir="$2"
  git init --bare "$origin_dir" >/dev/null
  git init -b main "$seed_dir" >/dev/null 2>&1 || git init "$seed_dir" >/dev/null
  mkdir -p "$seed_dir/.monozukuri"
  cat > "$seed_dir/features.md" <<'EOF'
## [FEAT] canary-001: Add deterministic sandbox greeting
- priority: high
- effort: 1

Add a tiny deterministic greeting used by the release canary.

## [FEAT] canary-002: Add sandbox health endpoint fixture
- priority: high
- effort: 1

Add a tiny deterministic health fixture used by the release canary.
EOF
  cat > "$seed_dir/.monozukuri/config.yaml" <<'EOF'
source:
  adapter: markdown
  markdown:
    file: features.md
autonomy: full_auto
execution:
  base_branch: main
agent: claude-code
pr_creation:
  strategy: ready
worktrees:
  auto_cleanup: false
safety:
  breaking_change_pause: false
  max_file_changes: 50
EOF
  git -C "$seed_dir" add features.md .monozukuri/config.yaml
  git -C "$seed_dir" -c user.email="canary@test.local" -c user.name="Canary" commit -m "init sandbox" >/dev/null
  git -C "$seed_dir" remote add origin "$origin_dir"
  git -C "$seed_dir" push -u origin main >/dev/null
  git --git-dir="$origin_dir" symbolic-ref HEAD refs/heads/main
}

clone_sandbox() {
  local dest="$1" origin_dir="$2"
  if [ "$MODE" = "mock" ]; then
    git clone --branch main "$origin_dir" "$dest" >/dev/null 2>&1
  else
    gh repo clone "$SANDBOX_REPO" "$dest" >/dev/null
  fi
}

latest_loop_state() {
  local project_dir="$1"
  find "$project_dir/.monozukuri/state" -maxdepth 1 -type d -name 'loop-*' 2>/dev/null | sort | tail -1
}

extract_run_json() {
  local agent="$1" project_dir="$2" run_dir="$3" exit_code="$4" ci_status="$5"
  node - "$agent" "$project_dir" "$run_dir" "$exit_code" "$ci_status" "$TASK_COUNT" <<'JSEOF'
const fs = require('fs');
const path = require('path');
const [,, agent, projectDir, runDir, exitCodeRaw, ciStatus, taskCountRaw] = process.argv;
function readJson(file, fallback) {
  try { return JSON.parse(fs.readFileSync(file, 'utf8')); } catch { return fallback; }
}
const manifest = readJson(path.join(runDir, 'manifest.json'), {tasks: []});
const cost = readJson(path.join(runDir, 'cost.json'), {});
const taskIds = (manifest.tasks || []).map((task) => task.id);
const prUrls = [];
for (const id of taskIds) {
  const result = readJson(path.join(projectDir, '.monozukuri', 'state', id, 'results.json'), {});
  if (result.pr_url) prUrls.push(result.pr_url);
}
const checks = prUrls.map((url) => ({pr_url: url, status: ciStatus}));
const totalCost = Number(cost.total_cost_usd ?? cost.total_cost ?? cost.cost_usd ?? 0);
const pass = Number(exitCodeRaw) === 0 &&
  taskIds.length === Number(taskCountRaw) &&
  prUrls.length === Number(taskCountRaw) &&
  checks.every((check) => check.status === 'success');
process.stdout.write(JSON.stringify({
  agent,
  exit_code: Number(exitCodeRaw),
  task_ids: taskIds,
  pr_urls: prUrls,
  ci_checks: checks,
  cost_usd: totalCost,
  pass
}));
JSEOF
}

verify_run_ci_status() {
  local run_file="$1"
  if [ "$MODE" = "mock" ]; then
    printf '%s\n' "$MOCK_CI"
    return 0
  fi

  local status="success"
  local pr_url pr_num checks_json check_status
  while IFS= read -r pr_url; do
    [ -n "$pr_url" ] || continue
    pr_num="${pr_url##*/}"
    checks_json=$(gh pr checks "$pr_num" --json name,state,conclusion 2>/dev/null || printf '[]')
    check_status=$(printf '%s' "$checks_json" | node -e "
const fs = require('fs');
let data = [];
try { data = JSON.parse(fs.readFileSync(0, 'utf8')); } catch {}
if (!Array.isArray(data) || data.length === 0) { console.log('failure'); process.exit(0); }
const states = data.map((c) => String(c.conclusion || c.state || '').toLowerCase());
console.log(states.every((s) => s === 'success' || s === 'completed') ? 'success' : 'failure');
" 2>/dev/null || printf 'failure')
    if [ "$check_status" != "success" ]; then
      status="failure"
    fi
  done < <(node -e "const r=JSON.parse(require('fs').readFileSync(process.argv[1],'utf8')); for (const url of r.pr_urls || []) console.log(url)" "$run_file")
  printf '%s\n' "$status"
}

mock_bin_dir="$WORK_DIR/mock-bin"
mock_origin="$WORK_DIR/mock-origin.git"
mock_seed="$WORK_DIR/mock-seed"
fake_gh_state="$WORK_DIR/fake-gh-count"
if [ "$MODE" = "mock" ]; then
  write_mock_gh "$mock_bin_dir" "$fake_gh_state"
  write_mock_sandbox "$mock_origin" "$mock_seed"
else
  require_live_tools
fi

run_files=()
remaining="$MAX_COST"
for agent in "${AGENTS[@]}"; do
  agent="$(printf '%s' "$agent" | sed 's/^[[:space:]]*//' | sed 's/[[:space:]]*$//')"
  [ -n "$agent" ] || continue
  agent_binary "$agent" >/dev/null

  project_dir="$WORK_DIR/$agent/project"
  run_out_dir="$OUT_DIR/$agent"
  mkdir -p "$run_out_dir"
  clone_sandbox "$project_dir" "$mock_origin"

  stdout_file="$run_out_dir/stdout.txt"
  stderr_file="$run_out_dir/stderr.txt"
  exit_code=0
  if [ "$MODE" = "mock" ]; then
    PATH="$mock_bin_dir:$REPO_ROOT/.qa/fixtures/mocks/claude:$REPO_ROOT/.qa/fixtures/mocks/codex:$REPO_ROOT/.qa/fixtures/mocks/gemini:$PATH" \
      MONOZUKURI_CANARY_FAKE_GH_STATE="$fake_gh_state" \
      PROGRESS_INTERVAL=0 \
      CI_POLL_TIMEOUT=5 \
      CI_POLL_INTERVAL=1 \
      MONOZUKURI_HOME="$REPO_ROOT" \
      bash -c 'cd "$1" && bash "$2" loop --tasks "$3" --agent "$4" --max-cost "$5" --non-interactive --no-ui' \
      _ "$project_dir" "$ORCHESTRATE" "$TASK_COUNT" "$agent" "$remaining" \
      > "$stdout_file" 2> "$stderr_file" || exit_code=$?
  else
    PROGRESS_INTERVAL=0 \
      MONOZUKURI_HOME="$REPO_ROOT" \
      bash -c 'cd "$1" && bash "$2" loop --tasks "$3" --agent "$4" --max-cost "$5" --non-interactive --no-ui' \
      _ "$project_dir" "$ORCHESTRATE" "$TASK_COUNT" "$agent" "$remaining" \
      > "$stdout_file" 2> "$stderr_file" || exit_code=$?
  fi

  state_dir="$(latest_loop_state "$project_dir")"
  if [ -z "$state_dir" ]; then
    echo "No loop state created for canary agent $agent" >&2
    exit_code=1
    mkdir -p "$run_out_dir/empty-state"
    state_dir="$run_out_dir/empty-state"
    printf '{"tasks":[]}\n' > "$state_dir/manifest.json"
    printf '{"total_cost_usd":0}\n' > "$state_dir/cost.json"
  fi

  cp "$state_dir/manifest.json" "$run_out_dir/manifest.json" 2>/dev/null || true
  cp "$state_dir/cost.json" "$run_out_dir/cost.json" 2>/dev/null || true
  run_json="$(extract_run_json "$agent" "$project_dir" "$state_dir" "$exit_code" "pending")"
  printf '%s\n' "$run_json" > "$run_out_dir/run.json"
  ci_status="$(verify_run_ci_status "$run_out_dir/run.json")"
  run_json="$(extract_run_json "$agent" "$project_dir" "$state_dir" "$exit_code" "$ci_status")"
  printf '%s\n' "$run_json" > "$run_out_dir/run.json"
  run_files+=("$run_out_dir/run.json")

  spent="$(node -e "const r=JSON.parse(require('fs').readFileSync(process.argv[1],'utf8')); console.log(Number(r.cost_usd||0).toFixed(6))" "$run_out_dir/run.json")"
  remaining="$(awk -v cap="$remaining" -v spent="$spent" 'BEGIN { remaining=cap-spent; if (remaining < 0) remaining=0; printf "%.6f", remaining }')"
  if ! awk -v n="$remaining" 'BEGIN { exit !(n > 0) }'; then
    break
  fi
done

node - "$OUT_DIR" "$SANDBOX_REPO" "$TASK_COUNT" "$MAX_COST" "${AGENTS[@]}" <<'JSEOF'
const fs = require('fs');
const path = require('path');
const [,, outDir, sandboxRepo, taskCountRaw, maxCostRaw, ...agents] = process.argv;
const runs = agents
  .map((agent) => path.join(outDir, agent.trim(), 'run.json'))
  .filter((file) => fs.existsSync(file))
  .map((file) => JSON.parse(fs.readFileSync(file, 'utf8')));
const totalCost = runs.reduce((sum, run) => sum + Number(run.cost_usd || 0), 0);
const diffs = [];
for (const run of runs) {
  if (run.exit_code !== 0) diffs.push(`${run.agent}: loop exited ${run.exit_code}`);
  if (run.pr_urls.length !== Number(taskCountRaw)) diffs.push(`${run.agent}: opened ${run.pr_urls.length}/${taskCountRaw} PRs`);
  for (const check of run.ci_checks) {
    if (check.status !== 'success') diffs.push(`${run.agent}: ${check.pr_url} CI ${check.status}`);
  }
}
if (runs.length !== agents.filter(Boolean).length) diffs.push(`ran ${runs.length}/${agents.length} agents`);
if (totalCost > Number(maxCostRaw)) diffs.push(`cost ${totalCost.toFixed(4)} exceeds cap ${maxCostRaw}`);
const result = {
  schema_version: 1,
  generated_at: new Date().toISOString(),
  sandbox_repo: sandboxRepo,
  agents: agents.filter(Boolean).map((agent) => agent.trim()),
  task_count: Number(taskCountRaw),
  max_cost_usd: Number(maxCostRaw),
  total_cost_usd: Number(totalCost.toFixed(6)),
  pass: diffs.length === 0 && runs.every((run) => run.pass),
  diffs,
  runs
};
fs.writeFileSync(path.join(outDir, 'results.json'), JSON.stringify(result, null, 2) + '\n');
const lines = [
  '# Live Canary',
  '',
  `Sandbox: ${sandboxRepo}`,
  `Tasks per agent: ${taskCountRaw}`,
  `Cost cap: $${maxCostRaw}`,
  `Total cost: $${result.total_cost_usd.toFixed(4)}`,
  '',
  '| Agent | Exit | PRs | CI | Cost |',
  '| --- | ---: | ---: | --- | ---: |',
  ...runs.map((run) => `| ${run.agent} | ${run.exit_code} | ${run.pr_urls.length} | ${run.ci_checks.map((c) => c.status).join(', ')} | $${Number(run.cost_usd || 0).toFixed(4)} |`),
  '',
  result.pass ? 'Gate: PASS' : `Gate: FAIL\n\n${diffs.map((diff) => `- ${diff}`).join('\n')}`,
  ''
];
fs.writeFileSync(path.join(outDir, 'summary.md'), lines.join('\n'));
console.log(`Live canary: ${result.pass ? 'PASS' : 'FAIL'}`);
console.log(`results: ${path.join(outDir, 'results.json')}`);
console.log(`summary: ${path.join(outDir, 'summary.md')}`);
process.exit(result.pass ? 0 : 1);
JSEOF
