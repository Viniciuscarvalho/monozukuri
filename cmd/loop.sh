#!/bin/bash
# cmd/loop.sh — sub_loop(): sequential non-interactive feature loop
# Sourced by orchestrate.sh; inherits SCRIPT_DIR, LIB_DIR, CMD_DIR,
# SCRIPTS_DIR, TEMPLATES_DIR, PROJECT_ROOT, ROOT_DIR, CONFIG_DIR,
# STATE_DIR, RESULTS_DIR, and all OPT_* variables.

_loop_bootstrap_modules() {
  if [ -f "$LIB_DIR/cli/emit.sh" ]; then
    source "$LIB_DIR/cli/emit.sh"
  else
    monozukuri_emit() { :; }
  fi

  source "$LIB_DIR/core/modules.sh"
  modules_init "$LIB_DIR"

  module_require core/util
  module_require config/load
  module_require core/worktree
  module_require memory/memory
  module_require cli/output
  module_require core/json-io
  module_require core/stack-profile
  module_require core/feature-state
  module_require core/platform
  module_require core/cost
  module_require core/router
  source "$LIB_DIR/agent/contract.sh"
  module_require memory/learning
  module_require run/size-gate
  module_require run/cycle-gate
  module_optional run/local-model "local_model::embed" "local_model::classify" \
                                  "local_model::summarize" "local_model::generate"
  module_optional run/ingest "ingest_trigger_if_merged" "ingest_reap_stale"
  module_optional run/injection-screen "sanitize_with_local_model"
  module_require prompt/sanitize
  module_require schema/validate
  module_require agent/error
  module_require run/policy
  module_require run/manifest
  module_require run/ci-poll
  module_require run/routing
  module_require run/dep-check
  module_require run/implicit-dep
  module_require prompt/context-pack
  module_require prompt/render
  module_require agent/registry
  module_require run/pause
  module_require run/phase-3
  module_require run/phase-4
  module_require run/pipeline
}

_loop_resolve_config_file() {
  local config_file="$OPT_CONFIG"
  if [ ! -f "$config_file" ]; then
    if [ -f ".monozukuri/config.yaml" ]; then
      config_file=".monozukuri/config.yaml"
    elif [ -f ".monozukuri/config.yml" ]; then
      config_file=".monozukuri/config.yml"
    elif [ -f "$TEMPLATES_DIR/config.yaml" ]; then
      config_file="$TEMPLATES_DIR/config.yaml"
    fi
  fi
  printf '%s\n' "$config_file"
}

_loop_make_run_id() {
  local rand
  rand=$(od -An -N3 -tx1 /dev/urandom 2>/dev/null | tr -d ' \n')
  [ -n "$rand" ] || rand=$(printf '%06d' "$$")
  printf 'loop-%s-%s\n' "$(date +%Y-%m-%d)" "$rand"
}

_loop_collect_ids() {
  local ids="${OPT_LOOP_IDS:-}"
  if [ -z "$ids" ] && [ ! -t 0 ]; then
    local line trimmed
    while IFS= read -r line; do
      trimmed=$(printf '%s' "$line" | sed 's/^[[:space:]]*//' | sed 's/[[:space:]]*$//')
      [ -z "$trimmed" ] && continue
      case "$trimmed" in
        \#*) continue ;;
      esac
      if [ -n "$ids" ]; then
        ids="${ids},$trimmed"
      else
        ids="$trimmed"
      fi
    done
  fi
  printf '%s\n' "$ids"
}

_loop_item_for_id() {
  local backlog_file="$1" feat_id="$2"
  node - "$backlog_file" "$feat_id" <<'JSEOF'
const [,, backlogFile, featureId] = process.argv;
const fs = require('fs');
const items = JSON.parse(fs.readFileSync(backlogFile, 'utf8'));
const item = items.find((entry) => entry.id === featureId);
if (!item) process.exit(1);
process.stdout.write(JSON.stringify(item));
JSEOF
}

_loop_pr_label() {
  local feat_id="$1" status="$2"
  local pr_url pr_num
  pr_url=$(fstate_get_pr_url "$feat_id")
  if [ -n "$pr_url" ]; then
    pr_num="${pr_url##*/}"
    printf 'PR #%s\n' "$pr_num"
  elif [ "$status" = "done" ]; then
    printf 'done\n'
  else
    printf '%s\n' "$status"
  fi
}

_loop_validate_caps() {
  local max_cost="$1" max_time="$2" max_tokens="$3"

  if ! awk -v n="$max_cost" 'BEGIN { exit !(n ~ /^[0-9]+([.][0-9]+)?$/ && n > 0) }'; then
    err "--max-cost must be a positive USD amount"
    return 1
  fi
  if ! awk -v n="$max_time" 'BEGIN { exit !(n ~ /^[0-9]+$/ && n > 0) }'; then
    err "--max-time must be a positive integer number of minutes"
    return 1
  fi
  if ! awk -v n="$max_tokens" 'BEGIN { exit !(n ~ /^[0-9]+$/ && n > 0) }'; then
    err "--max-tokens-per-task must be a positive integer"
    return 1
  fi
  if [ "${OPT_LOOP_MAX_COST_EXPLICIT:-false}" != "true" ] && \
     ! awk -v n="$max_cost" 'BEGIN { exit !(n <= 50) }'; then
    err "--max-cost without an explicit override is capped at 50 USD"
    return 1
  fi
  if [ "${OPT_LOOP_MAX_TIME_EXPLICIT:-false}" != "true" ] && \
     [ "$max_time" -gt 1440 ]; then
    err "--max-time without an explicit override is capped at 1440 minutes"
    return 1
  fi
  if [ "$max_tokens" -gt 500000 ]; then
    err "--max-tokens-per-task hard ceiling is 500000"
    return 1
  fi
}

_loop_model_for_agent() {
  local agent="$1" model="${2:-}"
  case "$agent" in
    claude-code)
      case "$model" in
        opus) echo "claude-opus-4-7" ;;
        haiku) echo "claude-haiku-4-5" ;;
        claude-*) echo "$model" ;;
        *) echo "claude-sonnet-4-6" ;;
      esac
      ;;
    codex)
      case "$model" in
        gpt-*) echo "$model" ;;
        mini) echo "gpt-5.4-mini" ;;
        *) echo "gpt-5.5" ;;
      esac
      ;;
    gemini)
      case "$model" in
        gemini-*) echo "$model" ;;
        flash) echo "gemini-2.5-flash" ;;
        *) echo "gemini-2.5-pro" ;;
      esac
      ;;
    *) echo "$model" ;;
  esac
}

_loop_validate_failure_mode() {
  local mode="$1"
  case "$mode" in
    continue|stop|pause) return 0 ;;
    *)
      err "--on-failure must be one of: continue, stop, pause"
      return 1
      ;;
  esac
}

_loop_validate_circuit_breaker() {
  local limit="$1"
  if ! awk -v n="$limit" 'BEGIN { exit !(n ~ /^[0-9]+$/) }'; then
    err "--circuit-breaker must be a non-negative integer"
    return 1
  fi
  if [ "$limit" -eq 0 ] && [ "${OPT_LOOP_I_KNOW_WHAT_IM_DOING:-false}" != "true" ]; then
    err "--circuit-breaker 0 disables a safety guard; pass --i-know-what-im-doing to confirm"
    return 1
  fi
}

_loop_default_failure_mode() {
  local autonomy="$1"
  case "$autonomy" in
    full_auto) echo "continue" ;;
    checkpoint|supervised) echo "pause" ;;
    *) echo "continue" ;;
  esac
}

_loop_prompt_failure_action() {
  local feat_id="$1" action
  LOOP_PAUSE_ACTION="abort"
  while true; do
    printf 'Feature %s failed. Choose retry/skip/abort: ' "$feat_id"
    IFS= read -r action || action="abort"
    case "$action" in
      retry|skip|abort)
        LOOP_PAUSE_ACTION="$action"
        return 0
        ;;
      *)
        printf 'Invalid choice: %s. Expected retry, skip, or abort.\n' "$action"
        ;;
    esac
  done
}

_loop_sync_legacy_cost() {
  local cost_file="$1"
  local legacy_cost_file="${MONOZUKURI_LOOP_LEGACY_COST_FILE:-}"
  [ -n "$legacy_cost_file" ] || return 0
  [ "$legacy_cost_file" != "$cost_file" ] || return 0
  [ -f "$cost_file" ] || return 0

  mkdir -p "$(dirname "$legacy_cost_file")"
  local tmp_file
  tmp_file=$(mktemp "$(dirname "$legacy_cost_file")/cost.XXXXXX")
  cp "$cost_file" "$tmp_file"
  mv "$tmp_file" "$legacy_cost_file"
}

_loop_state_append_progress() {
  local state_dir="$1" event="$2" task_id="${3:-}" phase="${4:-}" status="${5:-}" detail="${6:-}"
  [ -n "$state_dir" ] || return 0
  mkdir -p "$state_dir"
  local progress_file="$state_dir/progress.jsonl"
  local lock_file="$state_dir/.progress.lock"

  if command -v flock >/dev/null 2>&1; then
    (
      flock 9
      node - "$progress_file" "$event" "$task_id" "$phase" "$status" "$detail" <<'JSEOF'
const [,, progressFile, event, taskId, phase, status, detail] = process.argv;
const fs = require('fs');
const runId = require('path').basename(require('path').dirname(progressFile));
const entry = {
  schema_version: 1,
  run_id: runId,
  event,
  ts: new Date().toISOString()
};
if (taskId) entry.task_id = taskId;
if (phase) entry.phase = phase;
if (status) entry.status = status;
if (detail) entry.detail = detail;
fs.appendFileSync(progressFile, JSON.stringify(entry) + '\n');
JSEOF
    ) 9>"$lock_file"
  else
    node - "$progress_file" "$event" "$task_id" "$phase" "$status" "$detail" <<'JSEOF'
const [,, progressFile, event, taskId, phase, status, detail] = process.argv;
const fs = require('fs');
const runId = require('path').basename(require('path').dirname(progressFile));
const entry = {
  schema_version: 1,
  run_id: runId,
  event,
  ts: new Date().toISOString()
};
if (taskId) entry.task_id = taskId;
if (phase) entry.phase = phase;
if (status) entry.status = status;
if (detail) entry.detail = detail;
fs.appendFileSync(progressFile, JSON.stringify(entry) + '\n');
JSEOF
  fi
}

_loop_state_init() {
  local state_dir="$1" loop_run_id="$2" ids_csv="$3"
  mkdir -p "$state_dir"
  : > "$state_dir/progress.jsonl"

  node - "$state_dir" "$loop_run_id" "$ids_csv" <<'JSEOF'
const [,, stateDir, runId, idsCsv] = process.argv;
const fs = require('fs');
const path = require('path');
function atomicWriteJson(file, data) {
  const tmp = path.join(path.dirname(file), `${path.basename(file)}.${process.pid}.${Date.now()}.tmp`);
  const fd = fs.openSync(tmp, 'w');
  try {
    fs.writeFileSync(fd, JSON.stringify(data, null, 2));
    fs.fsyncSync(fd);
  } finally {
    fs.closeSync(fd);
  }
  fs.renameSync(tmp, file);
}
const now = new Date().toISOString();
const ids = idsCsv.split(',').map((id) => id.trim()).filter(Boolean);
atomicWriteJson(path.join(stateDir, 'manifest.json'), {
  schema_version: 1,
  run_id: runId,
  status: 'running',
  started_at: now,
  updated_at: now,
  tasks: ids.map((id, index) => ({
    id,
    order: index + 1,
    status: 'pending',
    updated_at: now
  }))
});
atomicWriteJson(path.join(stateDir, 'checkpoint.json'), {
  schema_version: 1,
  run_id: runId,
  status: 'running',
  last_safe_task_id: '',
  next_task_index: 1,
  next_task_id: ids[0] || '',
  updated_at: now
});
JSEOF
  _loop_state_append_progress "$state_dir" "loop.started" "" "" "running"
}

_loop_state_update_task() {
  local state_dir="$1" task_id="$2" status="$3" phase="${4:-}"
  node - "$state_dir/manifest.json" "$task_id" "$status" "$phase" <<'JSEOF'
const [,, manifestFile, taskId, status, phase] = process.argv;
const fs = require('fs');
const path = require('path');
function atomicWriteJson(file, data) {
  const tmp = path.join(path.dirname(file), `${path.basename(file)}.${process.pid}.${Date.now()}.tmp`);
  const fd = fs.openSync(tmp, 'w');
  try {
    fs.writeFileSync(fd, JSON.stringify(data, null, 2));
    fs.fsyncSync(fd);
  } finally {
    fs.closeSync(fd);
  }
  fs.renameSync(tmp, file);
}
const manifest = JSON.parse(fs.readFileSync(manifestFile, 'utf8'));
const task = manifest.tasks.find((entry) => entry.id === taskId);
if (task) {
  task.status = status;
  if (phase) task.phase = phase;
  task.updated_at = new Date().toISOString();
}
manifest.updated_at = new Date().toISOString();
atomicWriteJson(manifestFile, manifest);
JSEOF
}

_loop_state_checkpoint() {
  local state_dir="$1" status="$2" next_task_index="$3" next_task_id="${4:-}" last_safe_task_id="${5:-}" reason="${6:-}"
  node - "$state_dir/checkpoint.json" "$status" "$next_task_index" "$next_task_id" "$last_safe_task_id" "$reason" <<'JSEOF'
const [,, checkpointFile, status, nextTaskIndex, nextTaskId, lastSafeTaskId, reason] = process.argv;
const fs = require('fs');
const path = require('path');
function atomicWriteJson(file, data) {
  const tmp = path.join(path.dirname(file), `${path.basename(file)}.${process.pid}.${Date.now()}.tmp`);
  const fd = fs.openSync(tmp, 'w');
  try {
    fs.writeFileSync(fd, JSON.stringify(data, null, 2));
    fs.fsyncSync(fd);
  } finally {
    fs.closeSync(fd);
  }
  fs.renameSync(tmp, file);
}
const checkpoint = JSON.parse(fs.readFileSync(checkpointFile, 'utf8'));
checkpoint.status = status;
checkpoint.next_task_index = Number(nextTaskIndex || 0);
checkpoint.next_task_id = nextTaskId || '';
checkpoint.last_safe_task_id = lastSafeTaskId || checkpoint.last_safe_task_id || '';
if (reason) checkpoint.reason = reason;
checkpoint.updated_at = new Date().toISOString();
atomicWriteJson(checkpointFile, checkpoint);
JSEOF
}

_loop_state_finalize() {
  local state_dir="$1" status="$2" reason="${3:-}"
  node - "$state_dir/manifest.json" "$state_dir/checkpoint.json" "$status" "$reason" <<'JSEOF'
const [,, manifestFile, checkpointFile, status, reason] = process.argv;
const fs = require('fs');
const path = require('path');
function atomicWriteJson(file, data) {
  const tmp = path.join(path.dirname(file), `${path.basename(file)}.${process.pid}.${Date.now()}.tmp`);
  const fd = fs.openSync(tmp, 'w');
  try {
    fs.writeFileSync(fd, JSON.stringify(data, null, 2));
    fs.fsyncSync(fd);
  } finally {
    fs.closeSync(fd);
  }
  fs.renameSync(tmp, file);
}
const now = new Date().toISOString();
const manifest = JSON.parse(fs.readFileSync(manifestFile, 'utf8'));
manifest.status = status;
manifest.updated_at = now;
manifest.completed_at = now;
if (reason) manifest.reason = reason;
atomicWriteJson(manifestFile, manifest);
const checkpoint = JSON.parse(fs.readFileSync(checkpointFile, 'utf8'));
checkpoint.status = status;
checkpoint.updated_at = now;
if (reason) checkpoint.reason = reason;
atomicWriteJson(checkpointFile, checkpoint);
JSEOF
  _loop_state_append_progress "$state_dir" "loop.completed" "" "" "$status" "$reason"
}

_loop_resume_latest_run_id() {
  local state_root="$1"
  [ -d "$state_root" ] || return 1
  find "$state_root" -maxdepth 1 -type d -name 'loop-*' 2>/dev/null | while IFS= read -r dir; do
    [ -f "$dir/manifest.json" ] && [ -f "$dir/checkpoint.json" ] || continue
    node - "$dir/manifest.json" "$dir" <<'JSEOF' 2>/dev/null || true
const [,, manifestFile, dir] = process.argv;
const fs = require('fs');
const path = require('path');
const manifest = JSON.parse(fs.readFileSync(manifestFile, 'utf8'));
const status = manifest.status || '';
if (status === 'completed') process.exit(0);
const ts = manifest.updated_at || manifest.started_at || '';
console.log(`${ts}|${path.basename(dir)}`);
JSEOF
  done | sort -r | head -1 | awk -F'|' '{print $2}'
}

_loop_list_runs() {
  local state_root="$1"
  if [ ! -d "$state_root" ]; then
    printf 'No resumable loop runs found.\n'
    return 0
  fi
  local output
  output=$(find "$state_root" -maxdepth 1 -type d -name 'loop-*' 2>/dev/null | while IFS= read -r dir; do
    [ -f "$dir/manifest.json" ] && [ -f "$dir/checkpoint.json" ] || continue
    node - "$dir/manifest.json" "$dir" <<'JSEOF' 2>/dev/null || true
const [,, manifestFile, dir] = process.argv;
const fs = require('fs');
const path = require('path');
const manifest = JSON.parse(fs.readFileSync(manifestFile, 'utf8'));
const tasks = Array.isArray(manifest.tasks) ? manifest.tasks : [];
const pending = tasks.filter((task) => !['completed', 'skipped'].includes(task.status)).length;
if ((manifest.status || '') === 'completed') process.exit(0);
console.log(`${manifest.updated_at || manifest.started_at || ''}|${path.basename(dir)}|${manifest.status || 'unknown'}|${pending}`);
JSEOF
  done | sort -r)
  if [ -z "$output" ]; then
    printf 'No resumable loop runs found.\n'
    return 0
  fi
  printf 'RUN_ID STATUS PENDING\n'
  printf '%s\n' "$output" | awk -F'|' '{printf "%s %s %s\n", $2, $3, $4}'
}

_loop_manifest_ids_csv() {
  local state_dir="$1"
  node - "$state_dir/manifest.json" <<'JSEOF'
const [,, manifestFile] = process.argv;
const fs = require('fs');
const manifest = JSON.parse(fs.readFileSync(manifestFile, 'utf8'));
const ids = (manifest.tasks || [])
  .sort((a, b) => Number(a.order || 0) - Number(b.order || 0))
  .map((task) => task.id)
  .filter(Boolean);
process.stdout.write(ids.join(','));
JSEOF
}

_loop_state_task_status() {
  local state_dir="$1" task_id="$2"
  node - "$state_dir/manifest.json" "$task_id" <<'JSEOF' 2>/dev/null || echo ""
const [,, manifestFile, taskId] = process.argv;
const fs = require('fs');
const manifest = JSON.parse(fs.readFileSync(manifestFile, 'utf8'));
const task = (manifest.tasks || []).find((entry) => entry.id === taskId);
process.stdout.write(task ? (task.status || '') : '');
JSEOF
}

_loop_prepare_resume_state() {
  local state_dir="$1" retry_failed="$2"
  node - "$state_dir/manifest.json" "$state_dir/checkpoint.json" "$retry_failed" <<'JSEOF'
const [,, manifestFile, checkpointFile, retryFailed] = process.argv;
const fs = require('fs');
const path = require('path');
function atomicWriteJson(file, data) {
  const tmp = path.join(path.dirname(file), `${path.basename(file)}.${process.pid}.${Date.now()}.tmp`);
  const fd = fs.openSync(tmp, 'w');
  try {
    fs.writeFileSync(fd, JSON.stringify(data, null, 2));
    fs.fsyncSync(fd);
  } finally {
    fs.closeSync(fd);
  }
  fs.renameSync(tmp, file);
}
const now = new Date().toISOString();
const manifest = JSON.parse(fs.readFileSync(manifestFile, 'utf8'));
const resumeEvents = [];
for (const task of manifest.tasks || []) {
  if (task.status === 'running') {
    task.status = 'inconclusive';
    task.updated_at = now;
    resumeEvents.push(`inconclusive ${task.id}`);
  }
  if (task.status === 'failed' && retryFailed === 'true') {
    task.status = 'pending';
    task.updated_at = now;
    resumeEvents.push(`retry-failed ${task.id}`);
  }
}
manifest.status = 'running';
manifest.updated_at = now;
delete manifest.completed_at;
atomicWriteJson(manifestFile, manifest);
const checkpoint = JSON.parse(fs.readFileSync(checkpointFile, 'utf8'));
const next = (manifest.tasks || []).find((task) => !['completed', 'skipped', 'failed'].includes(task.status));
checkpoint.status = 'running';
checkpoint.next_task_index = next ? Number(next.order || 1) : ((manifest.tasks || []).length + 1);
checkpoint.next_task_id = next ? next.id : '';
checkpoint.updated_at = now;
atomicWriteJson(checkpointFile, checkpoint);
process.stdout.write(resumeEvents.join('\n'));
JSEOF
}

_loop_cost_init() {
  local cost_file="$1" loop_run_id="$2" max_cost="$3" max_time="$4" max_tokens="$5"
  node - "$cost_file" "$loop_run_id" "$max_cost" "$max_time" "$max_tokens" <<'JSEOF'
const [,, costFile, runId, maxCost, maxTime, maxTokens] = process.argv;
const fs = require('fs');
const path = require('path');
function atomicWriteJson(file, data) {
  const tmp = path.join(path.dirname(file), `${path.basename(file)}.${process.pid}.${Date.now()}.tmp`);
  const fd = fs.openSync(tmp, 'w');
  try {
    fs.writeFileSync(fd, JSON.stringify(data, null, 2));
    fs.fsyncSync(fd);
  } finally {
    fs.closeSync(fd);
  }
  fs.renameSync(tmp, file);
}
atomicWriteJson(costFile, {
  schema_version: 1,
  run_id: runId,
  status: 'running',
  started_at: new Date().toISOString(),
  limit_usd: Number(maxCost),
  limit_minutes: Number(maxTime),
  max_tokens_per_task: Number(maxTokens),
  total_usd: 0,
  total_tokens: 0,
  phase_events: [],
  features: []
});
JSEOF
  _loop_sync_legacy_cost "$cost_file"
}

_loop_cost_record_feature() {
  local cost_file="$1" feat_id="$2" feature_cost_file="$3" status="$4"
  node - "$cost_file" "$feat_id" "$feature_cost_file" "$status" <<'JSEOF'
const [,, costFile, featId, featureCostFile, status] = process.argv;
const fs = require('fs');
const path = require('path');
function atomicWriteJson(file, data) {
  const tmp = path.join(path.dirname(file), `${path.basename(file)}.${process.pid}.${Date.now()}.tmp`);
  const fd = fs.openSync(tmp, 'w');
  try {
    fs.writeFileSync(fd, JSON.stringify(data, null, 2));
    fs.fsyncSync(fd);
  } finally {
    fs.closeSync(fd);
  }
  fs.renameSync(tmp, file);
}
const data = JSON.parse(fs.readFileSync(costFile, 'utf8'));
let feature = { cumulative_tokens: 0, cumulative_usd: 0, phases: [] };
try {
  feature = JSON.parse(fs.readFileSync(featureCostFile, 'utf8'));
} catch (_) {}
const entry = {
  id: featId,
  status,
  tokens: Number(feature.cumulative_tokens || 0),
  usd: Number(feature.cumulative_usd || 0),
  phases: Array.isArray(feature.phases) ? feature.phases : [],
  recorded_at: new Date().toISOString()
};
data.features.push(entry);
const featureTokens = data.features.reduce((sum, f) => sum + Number(f.tokens || 0), 0);
const featureUsd = data.features.reduce((sum, f) => sum + Number(f.usd || 0), 0);
const phaseTokens = Array.isArray(data.phase_events)
  ? data.phase_events.reduce((sum, entry) => sum + Number(entry.estimated_tokens || 0), 0)
  : 0;
const phaseUsd = Array.isArray(data.phase_events)
  ? data.phase_events.reduce((sum, entry) => sum + Number(entry.estimated_usd || 0), 0)
  : 0;
data.total_tokens = Math.max(Number(data.total_tokens || 0), featureTokens, phaseTokens);
data.total_usd = Number(Math.max(Number(data.total_usd || 0), featureUsd, phaseUsd).toFixed(4));
data.updated_at = new Date().toISOString();
atomicWriteJson(costFile, data);
JSEOF
  _loop_sync_legacy_cost "$cost_file"
}

_loop_cost_record_circuit_breaker() {
  local cost_file="$1" limit="$2" consecutive_failures="$3" failed_feature_ids="$4"
  node - "$cost_file" "$limit" "$consecutive_failures" "$failed_feature_ids" <<'JSEOF'
const [,, costFile, limit, consecutiveFailures, failedFeatureIds] = process.argv;
const fs = require('fs');
const path = require('path');
function atomicWriteJson(file, data) {
  const tmp = path.join(path.dirname(file), `${path.basename(file)}.${process.pid}.${Date.now()}.tmp`);
  const fd = fs.openSync(tmp, 'w');
  try {
    fs.writeFileSync(fd, JSON.stringify(data, null, 2));
    fs.fsyncSync(fd);
  } finally {
    fs.closeSync(fd);
  }
  fs.renameSync(tmp, file);
}
const data = JSON.parse(fs.readFileSync(costFile, 'utf8'));
data.circuit_breaker = {
  tripped: true,
  limit: Number(limit),
  consecutive_failures: Number(consecutiveFailures),
  failed_feature_ids: failedFeatureIds ? failedFeatureIds.split(',').filter(Boolean) : [],
  resume_requires: '--circuit-breaker 0 --i-know-what-im-doing'
};
data.updated_at = new Date().toISOString();
atomicWriteJson(costFile, data);
JSEOF
  _loop_sync_legacy_cost "$cost_file"
}

_loop_cost_finalize() {
  local cost_file="$1" status="$2" elapsed_seconds="$3" reason="${4:-}"
  node - "$cost_file" "$status" "$elapsed_seconds" "$reason" <<'JSEOF'
const [,, costFile, status, elapsedSeconds, reason] = process.argv;
const fs = require('fs');
const path = require('path');
function atomicWriteJson(file, data) {
  const tmp = path.join(path.dirname(file), `${path.basename(file)}.${process.pid}.${Date.now()}.tmp`);
  const fd = fs.openSync(tmp, 'w');
  try {
    fs.writeFileSync(fd, JSON.stringify(data, null, 2));
    fs.fsyncSync(fd);
  } finally {
    fs.closeSync(fd);
  }
  fs.renameSync(tmp, file);
}
const data = JSON.parse(fs.readFileSync(costFile, 'utf8'));
data.status = status;
data.elapsed_seconds = Number(elapsedSeconds);
if (reason) data.reason = reason;
data.finished_at = new Date().toISOString();
atomicWriteJson(costFile, data);
JSEOF
  _loop_sync_legacy_cost "$cost_file"
}

_loop_cost_field() {
  local cost_file="$1" field="$2"
  node -p "try{JSON.parse(require('fs').readFileSync('$cost_file','utf8'))['$field']||0}catch(e){0}" \
    2>/dev/null || echo "0"
}

sub_loop() {
  trap 'exit 130' INT

  _loop_bootstrap_modules

  # Reuse run's incompatible-skill guard without invoking sub_run.
  if ! declare -f _run_check_incompatible_skills >/dev/null 2>&1; then
    source "$CMD_DIR/run.sh"
  fi

  local config_file
  config_file=$(_loop_resolve_config_file)
  load_config "$config_file"

  if declare -f routing_load >/dev/null 2>&1; then
    routing_load "$ROOT_DIR"
  fi

  if [ "${OPT_LOOP_LIST_RUNS:-false}" = "true" ]; then
    _loop_list_runs "$STATE_DIR"
    return 0
  fi

  local resume_mode=false
  [ "${OPT_RESUME:-false}" = "true" ] && resume_mode=true

  local loop_run_id
  if [ "$resume_mode" = "true" ]; then
    loop_run_id="${OPT_LOOP_RESUME_ID:-}"
    if [ -z "$loop_run_id" ]; then
      loop_run_id=$(_loop_resume_latest_run_id "$STATE_DIR" || true)
    fi
    if [ -z "$loop_run_id" ]; then
      err "No resumable loop runs found."
      return 1
    fi
  else
    loop_run_id=$(_loop_make_run_id)
  fi
  local loop_state_dir="$STATE_DIR/$loop_run_id"
  local worktree_run_id="$loop_run_id"
  if [ "$resume_mode" = "true" ]; then
    worktree_run_id="${loop_run_id}-resume-$(date +%H%M%S)-$$"
  fi
  WORKTREE_ROOT="$ROOT_DIR/.monozukuri/worktrees/$worktree_run_id"
  AUTO_CLEANUP=false
  if [ "${OPT_LOOP_CLEANUP:-false}" = "true" ]; then
    AUTO_CLEANUP=true
  fi
  BRANCH_PREFIX="${BRANCH_PREFIX:-feat}/$worktree_run_id"

  export ROOT_DIR CONFIG_DIR STATE_DIR RESULTS_DIR WORKTREE_ROOT
  export WORKTREE_BASE BRANCH_PREFIX BASE_BRANCH ADAPTER AUTONOMY MODEL_DEFAULT MODEL_PLAN MODEL_EXECUTE
  mkdir -p "$STATE_DIR" "$RESULTS_DIR" "$WORKTREE_ROOT" "$CONFIG_DIR/runs/$loop_run_id" "$loop_state_dir"

  if [ "$resume_mode" = "true" ]; then
    [ -f "$loop_state_dir/manifest.json" ] || { err "Loop resume manifest not found: $loop_state_dir/manifest.json"; return 1; }
    [ -f "$loop_state_dir/checkpoint.json" ] || { err "Loop resume checkpoint not found: $loop_state_dir/checkpoint.json"; return 1; }
    printf 'Resuming loop run: %s\n' "$loop_run_id"
    local resume_events
    resume_events=$(_loop_prepare_resume_state "$loop_state_dir" "${OPT_LOOP_RETRY_FAILED:-false}")
    if [ -n "$resume_events" ]; then
      while IFS=' ' read -r resume_event resume_task_id; do
        [ -n "$resume_event" ] && [ -n "$resume_task_id" ] || continue
        case "$resume_event" in
          inconclusive)
            _loop_state_append_progress "$loop_state_dir" "task.inconclusive" "$resume_task_id" "" "inconclusive" "resume-running"
            ;;
          retry-failed)
            _loop_state_append_progress "$loop_state_dir" "task.retry_failed" "$resume_task_id" "" "pending" "resume-retry-failed"
            ;;
        esac
      done <<EOF
$resume_events
EOF
    fi
    _loop_state_append_progress "$loop_state_dir" "loop.resumed" "" "" "running"
  fi

  local max_cost="${OPT_LOOP_MAX_COST:-10}"
  local max_time="${OPT_LOOP_MAX_TIME:-480}"
  local max_tokens="${OPT_LOOP_MAX_TOKENS_PER_TASK:-100000}"
  _loop_validate_caps "$max_cost" "$max_time" "$max_tokens" || return 1
  local on_failure="${OPT_LOOP_ON_FAILURE:-}"
  [ -n "$on_failure" ] || on_failure=$(_loop_default_failure_mode "$AUTONOMY")
  _loop_validate_failure_mode "$on_failure" || return 1
  local circuit_breaker="${OPT_LOOP_CIRCUIT_BREAKER:-3}"
  _loop_validate_circuit_breaker "$circuit_breaker" || return 1

  MONOZUKURI_MAX_FEATURE_TOKENS="$max_tokens"
  MODEL_AGENT="${MONOZUKURI_AGENT:-claude-code}"
  MODEL_PRIMARY=$(_loop_model_for_agent "$MODEL_AGENT" "${MODEL_DEFAULT:-}")
  export MONOZUKURI_MAX_FEATURE_TOKENS MODEL_AGENT MODEL_PRIMARY

  _run_check_incompatible_skills
  mem_refresh_env

  local ids_csv
  if [ "$resume_mode" = "true" ]; then
    ids_csv=$(_loop_manifest_ids_csv "$loop_state_dir")
  else
    ids_csv=$(_loop_collect_ids)
  fi
  if [ -z "$ids_csv" ]; then
    err "No feature IDs provided."
    err "Usage: monozukuri loop <id...> or pipe IDs on stdin"
    return 1
  fi

  run_adapter >/dev/null
  local backlog_file="$ROOT_DIR/$BACKLOG_OUTPUT"

  local ids=()
  local IFS_ORIG="$IFS"
  IFS=","
  read -r -a ids <<< "$ids_csv"
  IFS="$IFS_ORIG"

  local loop_cost_file="$loop_state_dir/cost.json"
  local legacy_loop_cost_file="$CONFIG_DIR/runs/$loop_run_id/cost.json"
  MONOZUKURI_LOOP_COST_FILE="$loop_cost_file"
  MONOZUKURI_LOOP_LEGACY_COST_FILE="$legacy_loop_cost_file"
  MONOZUKURI_LOOP_STATE_DIR="$loop_state_dir"
  export MONOZUKURI_LOOP_COST_FILE MONOZUKURI_LOOP_LEGACY_COST_FILE MONOZUKURI_LOOP_STATE_DIR
  if [ "$resume_mode" != "true" ]; then
    _loop_state_init "$loop_state_dir" "$loop_run_id" "$ids_csv"
    _loop_cost_init "$loop_cost_file" "$loop_run_id" "$max_cost" "$max_time" "$max_tokens"
  elif [ ! -f "$loop_cost_file" ]; then
    _loop_cost_init "$loop_cost_file" "$loop_run_id" "$max_cost" "$max_time" "$max_tokens"
  else
    _loop_sync_legacy_cost "$loop_cost_file"
  fi

  local total="${#ids[@]}"
  local index=0 any_failed=0 cap_reached=0 cap_reason="" failure_stopped=0 failure_stop_reason=""
  local circuit_tripped=0 circuit_message="" consecutive_failures=0 consecutive_failed_ids=""
  local loop_started_at
  loop_started_at=$(date +%s)
  local feat_id item_json title body priority labels deps next_feat_id
  for feat_id in "${ids[@]}"; do
    index=$((index + 1))
    feat_id=$(printf '%s' "$feat_id" | sed 's/^[[:space:]]*//' | sed 's/[[:space:]]*$//')
    [ -z "$feat_id" ] && continue

    if [ "$resume_mode" = "true" ]; then
      local resume_task_status
      resume_task_status=$(_loop_state_task_status "$loop_state_dir" "$feat_id")
      case "$resume_task_status" in
        completed)
          printf '[%d/%d] %s ↷ skipped (completed)\n' "$index" "$total" "$feat_id"
          _loop_state_append_progress "$loop_state_dir" "task.skipped" "$feat_id" "" "completed" "resume-completed"
          continue
          ;;
        failed)
          if [ "${OPT_LOOP_RETRY_FAILED:-false}" != "true" ]; then
            any_failed=1
            printf '[%d/%d] %s ↷ skipped (failed)\n' "$index" "$total" "$feat_id"
            _loop_state_append_progress "$loop_state_dir" "task.skipped" "$feat_id" "" "failed" "resume-failed"
            continue
          fi
          ;;
        skipped)
          printf '[%d/%d] %s ↷ skipped\n' "$index" "$total" "$feat_id"
          _loop_state_append_progress "$loop_state_dir" "task.skipped" "$feat_id" "" "skipped" "resume-skipped"
          continue
          ;;
      esac
    fi

    local current_total_usd
    current_total_usd=$(_loop_cost_field "$loop_cost_file" "total_usd")
    if awk -v c="$current_total_usd" -v limit="$max_cost" 'BEGIN { exit !(c >= limit) }'; then
      cap_reached=1
      cap_reason="cost"
      break
    fi

    _loop_state_update_task "$loop_state_dir" "$feat_id" "running"
    _loop_state_checkpoint "$loop_state_dir" "running" "$index" "$feat_id" "" ""
    _loop_state_append_progress "$loop_state_dir" "task.started" "$feat_id" "" "running"

    local elapsed_now
    elapsed_now=$(( $(date +%s) - loop_started_at ))
    if [ "$elapsed_now" -ge $(( max_time * 60 )) ]; then
      cap_reached=1
      cap_reason="time"
      break
    fi

    if ! item_json=$(_loop_item_for_id "$backlog_file" "$feat_id"); then
      printf '[%d/%d] %s ✗ not found\n' "$index" "$total" "$feat_id"
      any_failed=1
      local next_index=$((index + 1))
      local next_id=""
      [ "$index" -lt "$total" ] && next_id="${ids[$index]}"
      _loop_state_update_task "$loop_state_dir" "$feat_id" "skipped"
      _loop_state_checkpoint "$loop_state_dir" "running" "$next_index" "$next_id" "$feat_id" "not-found"
      _loop_state_append_progress "$loop_state_dir" "task.skipped" "$feat_id" "" "skipped" "not-found"
      consecutive_failures=$((consecutive_failures + 1))
      if [ -n "$consecutive_failed_ids" ]; then
        consecutive_failed_ids="${consecutive_failed_ids},$feat_id"
      else
        consecutive_failed_ids="$feat_id"
      fi
      if [ "$circuit_breaker" -gt 0 ] && [ "$consecutive_failures" -ge "$circuit_breaker" ]; then
        circuit_tripped=1
        circuit_message="Circuit breaker tripped: $consecutive_failures consecutive failures"
        printf '%s\n' "$circuit_message"
        printf '%s\n' "$circuit_message" >&2
        _loop_cost_record_circuit_breaker "$loop_cost_file" "$circuit_breaker" "$consecutive_failures" "$consecutive_failed_ids"
        _loop_state_checkpoint "$loop_state_dir" "circuit-breaker-tripped" "$next_index" "$next_id" "$feat_id" "$circuit_message"
        break
      fi
      continue
    fi

    title=$(echo "$item_json"    | node -p "JSON.parse(require('fs').readFileSync('/dev/stdin','utf-8')).title")
    body=$(echo "$item_json"     | node -p "JSON.parse(require('fs').readFileSync('/dev/stdin','utf-8')).body")
    priority=$(echo "$item_json" | node -p "JSON.parse(require('fs').readFileSync('/dev/stdin','utf-8')).priority")
    labels=$(echo "$item_json"   | node -p "JSON.parse(require('fs').readFileSync('/dev/stdin','utf-8')).labels.join(', ')")
    deps=$(echo "$item_json"     | node -p "JSON.parse(require('fs').readFileSync('/dev/stdin','utf-8')).dependencies.join(', ')||'none'")

    next_feat_id=""
    if [ "$index" -lt "$total" ]; then
      next_feat_id="${ids[$index]}"
    fi

    local loop_log="$CONFIG_DIR/runs/$loop_run_id/$feat_id/loop.log"
    mkdir -p "$(dirname "$loop_log")"

    local retry_feature="true"
    while [ "$retry_feature" = "true" ]; do
      retry_feature="false"
      local feature_exit=0
      run_feature "$feat_id" "$title" "$body" "$priority" "$labels" "$deps" "$index" "$total" "$next_feat_id" \
        >"$loop_log" 2>&1 || feature_exit=$?

      local final_status label
      final_status=$(fstate_get_status "$feat_id")
      _loop_cost_record_feature "$loop_cost_file" "$feat_id" "$STATE_DIR/$feat_id/cost.json" "$final_status"

      if { [ "$feature_exit" -eq 0 ] && [ "$final_status" = "done" ]; } || [ "$final_status" = "pr-created" ]; then
        label=$(_loop_pr_label "$feat_id" "$final_status")
        printf '[%d/%d] %s ✓ %s\n' "$index" "$total" "$feat_id" "$label"
        local next_index=$((index + 1))
        local next_id=""
        [ "$index" -lt "$total" ] && next_id="${ids[$index]}"
        _loop_state_update_task "$loop_state_dir" "$feat_id" "completed"
        _loop_state_checkpoint "$loop_state_dir" "running" "$next_index" "$next_id" "$feat_id" ""
        _loop_state_append_progress "$loop_state_dir" "task.completed" "$feat_id" "" "completed"
        consecutive_failures=0
        consecutive_failed_ids=""
      else
        [ -n "$final_status" ] || final_status="failed"
        if [ "$final_status" != "failed" ]; then
          fstate_transition "$feat_id" "failed" "loop-feature-failed"
          final_status="failed"
        fi
        printf '[%d/%d] %s ✗ %s\n' "$index" "$total" "$feat_id" "$final_status"
        consecutive_failures=$((consecutive_failures + 1))
        if [ -n "$consecutive_failed_ids" ]; then
          consecutive_failed_ids="${consecutive_failed_ids},$feat_id"
        else
          consecutive_failed_ids="$feat_id"
        fi
        if [ "$circuit_breaker" -gt 0 ] && [ "$consecutive_failures" -ge "$circuit_breaker" ]; then
          any_failed=1
          circuit_tripped=1
          circuit_message="Circuit breaker tripped: $consecutive_failures consecutive failures"
          printf '%s\n' "$circuit_message"
          printf '%s\n' "$circuit_message" >&2
          _loop_cost_record_circuit_breaker "$loop_cost_file" "$circuit_breaker" "$consecutive_failures" "$consecutive_failed_ids"
          local next_index=$((index + 1))
          local next_id=""
          [ "$index" -lt "$total" ] && next_id="${ids[$index]}"
          _loop_state_update_task "$loop_state_dir" "$feat_id" "failed"
          _loop_state_checkpoint "$loop_state_dir" "circuit-breaker-tripped" "$next_index" "$next_id" "$feat_id" "$circuit_message"
          _loop_state_append_progress "$loop_state_dir" "task.failed" "$feat_id" "" "failed" "$circuit_message"
          break
        fi

        case "$on_failure" in
          continue)
            any_failed=1
            local next_index=$((index + 1))
            local next_id=""
            [ "$index" -lt "$total" ] && next_id="${ids[$index]}"
            _loop_state_update_task "$loop_state_dir" "$feat_id" "failed"
            _loop_state_checkpoint "$loop_state_dir" "running" "$next_index" "$next_id" "$feat_id" "feature-failed"
            _loop_state_append_progress "$loop_state_dir" "task.failed" "$feat_id" "" "failed" "feature-failed"
            ;;
          stop)
            any_failed=1
            failure_stopped=1
            failure_stop_reason="$feat_id"
            local next_index=$((index + 1))
            local next_id=""
            [ "$index" -lt "$total" ] && next_id="${ids[$index]}"
            _loop_state_update_task "$loop_state_dir" "$feat_id" "failed"
            _loop_state_checkpoint "$loop_state_dir" "stopped" "$next_index" "$next_id" "$feat_id" "feature-failed"
            _loop_state_append_progress "$loop_state_dir" "task.failed" "$feat_id" "" "failed" "feature-failed"
            ;;
          pause)
            if [ ! -t 0 ]; then
              any_failed=1
              failure_stopped=1
              failure_stop_reason="$feat_id"
              printf 'Loop pause requested but stdin is not a TTY; stopping after failure: %s.\n' "$feat_id"
              local next_index=$((index + 1))
              local next_id=""
              [ "$index" -lt "$total" ] && next_id="${ids[$index]}"
              _loop_state_update_task "$loop_state_dir" "$feat_id" "failed"
              _loop_state_checkpoint "$loop_state_dir" "stopped" "$next_index" "$next_id" "$feat_id" "pause-non-tty"
              _loop_state_append_progress "$loop_state_dir" "task.failed" "$feat_id" "" "failed" "pause-non-tty"
            else
              local pause_action
              _loop_prompt_failure_action "$feat_id"
              pause_action="$LOOP_PAUSE_ACTION"
              case "$pause_action" in
                retry)
                  retry_feature="true"
                  ;;
                skip)
                  any_failed=1
                  local next_index=$((index + 1))
                  local next_id=""
                  [ "$index" -lt "$total" ] && next_id="${ids[$index]}"
                  _loop_state_update_task "$loop_state_dir" "$feat_id" "skipped"
                  _loop_state_checkpoint "$loop_state_dir" "running" "$next_index" "$next_id" "$feat_id" "operator-skip"
                  _loop_state_append_progress "$loop_state_dir" "task.skipped" "$feat_id" "" "skipped" "operator-skip"
                  ;;
                abort)
                  any_failed=1
                  failure_stopped=1
                  failure_stop_reason="$feat_id"
                  local next_index=$((index + 1))
                  local next_id=""
                  [ "$index" -lt "$total" ] && next_id="${ids[$index]}"
                  _loop_state_update_task "$loop_state_dir" "$feat_id" "failed"
                  _loop_state_checkpoint "$loop_state_dir" "stopped" "$next_index" "$next_id" "$feat_id" "operator-abort"
                  _loop_state_append_progress "$loop_state_dir" "task.failed" "$feat_id" "" "failed" "operator-abort"
                  ;;
              esac
            fi
            ;;
        esac
      fi
    done

    if [ "$AUTO_CLEANUP" = "true" ]; then
      wt_remove "$feat_id"
    fi

    local total_usd feature_tokens elapsed_after
    total_usd=$(_loop_cost_field "$loop_cost_file" "total_usd")
    feature_tokens=$(node -p "try{const d=JSON.parse(require('fs').readFileSync('$STATE_DIR/$feat_id/cost.json','utf8'));d.cumulative_tokens||0}catch(e){0}" 2>/dev/null || echo "0")
    elapsed_after=$(( $(date +%s) - loop_started_at ))
    if awk -v c="$total_usd" -v limit="$max_cost" 'BEGIN { exit !(c >= limit) }'; then
      cap_reached=1
      cap_reason="cost"
      break
    fi
    if [ "$elapsed_after" -ge $(( max_time * 60 )) ]; then
      cap_reached=1
      cap_reason="time"
      break
    fi
    if [ "$feature_tokens" -ge "$max_tokens" ]; then
      cap_reached=1
      cap_reason="tokens"
      break
    fi
    if [ "$failure_stopped" -eq 1 ]; then
      break
    fi
    if [ "$circuit_tripped" -eq 1 ]; then
      break
    fi
  done

  rm -f "$backlog_file"
  local elapsed_total final_status final_cost final_tokens
  elapsed_total=$(( $(date +%s) - loop_started_at ))
  if [ "$circuit_tripped" -eq 1 ]; then
    final_status="circuit-breaker-tripped"
  elif [ "$cap_reached" -eq 1 ]; then
    final_status="cap-reached"
  elif [ "$failure_stopped" -eq 1 ]; then
    final_status="stopped"
  elif [ "$any_failed" -eq 0 ]; then
    final_status="completed"
  else
    final_status="failed"
  fi
  _loop_cost_finalize "$loop_cost_file" "$final_status" "$elapsed_total" "$cap_reason"
  _loop_state_finalize "$loop_state_dir" "$final_status" "$cap_reason"
  final_cost=$(_loop_cost_field "$loop_cost_file" "total_usd")
  final_tokens=$(_loop_cost_field "$loop_cost_file" "total_tokens")
  printf 'Loop cost: $%.4f / $%s, tokens: %s, elapsed: %ss / %sm\n' \
    "$final_cost" "$max_cost" "$final_tokens" "$elapsed_total" "$max_time"
  if [ "$circuit_tripped" -eq 1 ]; then
    return "${EXIT_CIRCUIT_BREAKER:-5}"
  fi
  if [ "$cap_reached" -eq 1 ]; then
    printf 'Loop cap reached: %s; no further features will start.\n' "$cap_reason"
    return "${EXIT_BUDGET_CAP:-4}"
  fi
  if [ "$failure_stopped" -eq 1 ]; then
    printf 'Loop stopped after failure: %s; no further features will start.\n' "$failure_stop_reason"
    return "${EXIT_LOOP_STOPPED:-3}"
  fi
  [ "$any_failed" -eq 0 ] || return 1
  return 0
}
