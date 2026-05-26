#!/bin/bash
# lib/memory/v2.sh — Memory v2 prompt injection and application tracking.

_memory_v2_config_dir() {
  printf '%s\n' "${CONFIG_DIR:-${ROOT_DIR:-$(pwd)}/.monozukuri}"
}

_memory_v2_store_path() {
  local config_dir
  config_dir=$(_memory_v2_config_dir)
  printf '%s/memory-v2.json\n' "$config_dir"
}

_memory_v2_cache_dir() {
  local config_dir
  config_dir=$(_memory_v2_config_dir)
  printf '%s/cache/memory\n' "$config_dir"
}

_memory_v2_summary_script() {
  local script_dir
  script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
  printf '%s/summary.js\n' "$script_dir"
}

memory_v2_token_count() {
  local text="${1:-}"
  node "$(_memory_v2_summary_script)" count "$text"
}

summarize_for_phase() {
  local phase="${1:?summarize_for_phase: PHASE required}"
  local feat_id="${2:?summarize_for_phase: FEAT_ID required}"
  local learnings="${3:-[]}"
  local cache_dir
  cache_dir=$(_memory_v2_cache_dir)
  local trace_path=""
  trace_path=$(_memory_v2_decision_trace_path 2>/dev/null || true)
  printf '%s' "$learnings" | node "$(_memory_v2_summary_script)" summarize \
    "$phase" "$feat_id" "$cache_dir" "${MONOZUKURI_MEMORY_SUMMARY_TOKEN_CAP:-500}" "$trace_path"
}

_memory_v2_feature_trace_path() {
  local feat_id="${1:-${MONOZUKURI_FEATURE_ID:-}}"
  [ -n "$feat_id" ] || return 1
  local run_dir="${MONOZUKURI_RUN_DIR:-$(_memory_v2_config_dir)/runs}"
  printf '%s/%s/memory-injections.jsonl\n' "$run_dir" "$feat_id"
}

_memory_v2_decision_trace_path() {
  local run_id="${MONOZUKURI_RUN_ID:-}"
  [ -n "$run_id" ] || run_id="${MONOZUKURI_FEATURE_ID:-}"
  [ -n "$run_id" ] || return 1
  local run_dir="${MONOZUKURI_RUN_DIR:-$(_memory_v2_config_dir)/runs}"
  printf '%s/%s/memory-trace.jsonl\n' "$run_dir" "$run_id"
}

_memory_v2_log_decision_events() {
  local event="${1:?_memory_v2_log_decision_events: EVENT required}"
  local phase="${2:?_memory_v2_log_decision_events: PHASE required}"
  local ids_csv="${3:-}"
  local attempt="${4:-0}"
  local detail="${5:-}"
  local trace_path
  trace_path=$(_memory_v2_decision_trace_path) || return 0
  [ -n "$ids_csv" ] || return 0
  mkdir -p "$(dirname "$trace_path")"
  node - "$trace_path" "$event" "$phase" "$ids_csv" "$attempt" "$detail" "${MONOZUKURI_FEATURE_ID:-}" <<'JSEOF' || true
const fs = require('fs');
const [,, tracePath, event, phase, idsCsv, attemptRaw, detail, featureId] = process.argv;
const ids = idsCsv.split(',').map((id) => id.trim()).filter(Boolean);
const attempt = Number(attemptRaw) || 0;
for (const id of ids) {
  const payload = {
    event,
    phase,
    feature_id: featureId || undefined,
    learning_id: id,
    attempt,
    timestamp: new Date().toISOString()
  };
  if (event === 'escalation_denied') payload.reason = detail || 'unknown';
  if (event === 'escalation_granted') payload.tokens = Number(detail) || 0;
  fs.appendFileSync(tracePath, JSON.stringify(payload) + '\n');
}
JSEOF
}

_memory_v2_log_granted_from_context() {
  local phase="${1:?_memory_v2_log_granted_from_context: PHASE required}"
  local ids_csv="${2:-}"
  local attempt="${3:-0}"
  local ctx_json="${4:-}"
  local trace_path
  trace_path=$(_memory_v2_decision_trace_path) || return 0
  [ -n "$ids_csv" ] || return 0
  [ -n "$ctx_json" ] || return 0
  [ -f "$ctx_json" ] || return 0
  mkdir -p "$(dirname "$trace_path")"
  node - "$trace_path" "$phase" "$ids_csv" "$attempt" "$ctx_json" "${MONOZUKURI_FEATURE_ID:-}" <<'JSEOF' || true
const fs = require('fs');
const [,, tracePath, phase, idsCsv, attemptRaw, ctxPath, featureId] = process.argv;
const ids = idsCsv.split(',').map((id) => id.trim()).filter(Boolean);
const attempt = Number(attemptRaw) || 0;
let context = {};
try {
  context = JSON.parse(fs.readFileSync(ctxPath, 'utf8'));
} catch {
  context = {};
}
const entries = Array.isArray(context.project_learnings) ? context.project_learnings : [];
for (const id of ids) {
  const entry = entries.find((item) => item && item.id === id && item.raw) ||
    entries.find((item) => item && item.id === id);
  const summary = entry && entry.summary ? String(entry.summary) : '';
  const tokens = Math.max(0, Math.ceil(Buffer.byteLength(summary, 'utf8') / 4));
  fs.appendFileSync(tracePath, JSON.stringify({
    event: 'escalation_granted',
    phase,
    feature_id: featureId || undefined,
    learning_id: id,
    attempt,
    tokens,
    timestamp: new Date().toISOString()
  }) + '\n');
}
JSEOF
}

memory_v2_context_entries() {
  local feat_id="${1:?memory_v2_context_entries: FEAT_ID required}"
  local store_path
  store_path=$(_memory_v2_store_path)
  [ -f "$store_path" ] || { printf '[]\n'; return 0; }

  local phase="${MONOZUKURI_PHASE:-context}"
  local cache_dir
  cache_dir=$(_memory_v2_cache_dir)
  node "$(_memory_v2_summary_script)" context \
    "$phase" "$feat_id" "$cache_dir" "${MONOZUKURI_MEMORY_SUMMARY_TOKEN_CAP:-500}" \
    "${MONOZUKURI_AGENT:-${ADAPTER:-}}" "${MONOZUKURI_MEMORY_ESCALATION_IDS:-}" \
    "$(_memory_v2_decision_trace_path 2>/dev/null || true)" \
    < "$store_path" 2>/dev/null || printf '[]\n'
}

memory_v2_request_instruction() {
  printf '%s\n' '## Memory escalation'
  printf '%s\n' 'Se precisar de detalhe sobre um learning, emita <request-memory id="lrn-xxx"/> no início da sua resposta.'
}

memory_v2_trace_prompt() {
  local phase="${1:?memory_v2_trace_prompt: PHASE required}"
  local prompt="${2:-}"
  local feat_id="${MONOZUKURI_FEATURE_ID:-}"
  [ -n "$feat_id" ] || return 0

  local trace_path
  trace_path=$(_memory_v2_feature_trace_path "$feat_id") || return 0

  local prompt_file
  prompt_file=$(mktemp)
  printf '%s' "$prompt" > "$prompt_file"
  node - "$phase" "$trace_path" "$prompt_file" <<'JSEOF' || true
const fs = require('fs');
const path = require('path');
const [,, phase, tracePath, promptFile] = process.argv;
const prompt = fs.readFileSync(promptFile, 'utf8');
const ids = [];
const seen = new Set();
for (const match of prompt.matchAll(/<!--\s*learning:\s*([A-Za-z0-9_.:-]+)\s*-->/g)) {
  if (!seen.has(match[1])) {
    ids.push(match[1]);
    seen.add(match[1]);
  }
}
if (ids.length === 0) process.exit(0);
const injectionLines = prompt.split(/\n/).filter((line) => /<!--\s*learning:/.test(line));
const chars = injectionLines.join('\n').length;
const tokens = Math.max(1, Math.floor(chars / 4));
fs.mkdirSync(path.dirname(tracePath), {recursive: true});
fs.appendFileSync(tracePath, JSON.stringify({
  phase,
  learnings: ids,
  tokens,
  timestamp: new Date().toISOString()
}) + '\n');
JSEOF
  rm -f "$prompt_file" 2>/dev/null || true
}

memory_v2_log_escalation() {
  local phase="${1:?memory_v2_log_escalation: PHASE required}"
  local ids_csv="${2:-}"
  local attempt="${3:-1}"
  local feat_id="${MONOZUKURI_FEATURE_ID:-}"
  [ -n "$feat_id" ] || return 0
  [ -n "$ids_csv" ] || return 0

  local trace_path
  trace_path=$(_memory_v2_feature_trace_path "$feat_id") || return 0
  mkdir -p "$(dirname "$trace_path")"
  node - "$phase" "$ids_csv" "$attempt" "$trace_path" <<'JSEOF' || true
const fs = require('fs');
const [,, phase, idsCsv, attempt, tracePath] = process.argv;
const ids = idsCsv.split(',').map((id) => id.trim()).filter(Boolean);
if (ids.length === 0) process.exit(0);
fs.appendFileSync(tracePath, JSON.stringify({
  event: 'escalation',
  phase,
  learnings: ids,
  attempt: Number(attempt) || 1,
  timestamp: new Date().toISOString()
}) + '\n');
JSEOF
}

_memory_v2_join_ids() {
  local existing="${1:-}"
  local requested="${2:-}"
  node - "$existing" "$requested" <<'JSEOF'
const [,, existing, requested] = process.argv;
const seen = new Set();
const out = [];
for (const chunk of [existing, requested]) {
  for (const id of String(chunk || '').split(/[,\n]/).map((v) => v.trim()).filter(Boolean)) {
    if (!seen.has(id)) {
      seen.add(id);
      out.push(id);
    }
  }
}
console.log(out.join(','));
JSEOF
}

memory_v2_run_phase_with_escalation() {
  local phase="${1:?memory_v2_run_phase_with_escalation: PHASE required}"
  local feat_id="${2:?memory_v2_run_phase_with_escalation: FEAT_ID required}"
  local wt_path="${3:?memory_v2_run_phase_with_escalation: WORKTREE required}"
  local log_file="${4:?memory_v2_run_phase_with_escalation: LOG_FILE required}"
  local ctx_json="${5:-${CONTEXT_JSON:-}}"
  local max_escalations="${MONOZUKURI_MEMORY_MAX_ESCALATIONS_PER_PHASE:-3}"
  local attempt=0
  local exit_code=0
  local previous_ids="${MONOZUKURI_MEMORY_ESCALATION_IDS:-}"
  local accumulated_ids="$previous_ids"
  local previous_defer="${MONOZUKURI_MEMORY_DEFER_PHASE_SUCCESS:-}"

  export MONOZUKURI_FEATURE_ID="$feat_id"
  export MONOZUKURI_WORKTREE="$wt_path"
  export MONOZUKURI_PHASE="$phase"
  [ -n "$ctx_json" ] && export CONTEXT_JSON="$ctx_json"
  export MONOZUKURI_MEMORY_DEFER_PHASE_SUCCESS=1

  while :; do
    exit_code=0
    agent_run_phase || exit_code=$?
    [ "$exit_code" -ne 0 ] && {
      export MONOZUKURI_MEMORY_ESCALATION_IDS="$previous_ids"
      export MONOZUKURI_MEMORY_DEFER_PHASE_SUCCESS="$previous_defer"
      return "$exit_code"
    }

    local requested_ids=""
    if declare -f parse_memory_requests &>/dev/null && [ -f "$log_file" ]; then
      requested_ids=$(parse_memory_requests "$(cat "$log_file")" | paste -sd, -)
    fi
    [ -z "$requested_ids" ] && {
      memory_v2_mark_phase_success "$phase" 2>/dev/null || true
      export MONOZUKURI_MEMORY_ESCALATION_IDS="$previous_ids"
      export MONOZUKURI_MEMORY_DEFER_PHASE_SUCCESS="$previous_defer"
      return 0
    }

    local next_attempt=$((attempt + 1))
    _memory_v2_log_decision_events "escalation_requested" "$phase" "$requested_ids" "$next_attempt"

    if [ "$attempt" -ge "$max_escalations" ]; then
      _memory_v2_log_decision_events "escalation_denied" "$phase" "$requested_ids" "$next_attempt" "cap_reached"
      printf 'memory escalation limit reached for %s/%s after %s attempt(s)\n' \
        "$feat_id" "$phase" "$max_escalations" >&2
      export MONOZUKURI_MEMORY_ESCALATION_IDS="$previous_ids"
      export MONOZUKURI_MEMORY_DEFER_PHASE_SUCCESS="$previous_defer"
      return 1
    fi

    attempt="$next_attempt"
    memory_v2_log_escalation "$phase" "$requested_ids" "$attempt"
    accumulated_ids=$(_memory_v2_join_ids "$accumulated_ids" "$requested_ids")
    export MONOZUKURI_MEMORY_ESCALATION_IDS="$accumulated_ids"

    if [ -n "$ctx_json" ] && declare -f context_pack_build &>/dev/null; then
      context_pack_build "$feat_id" "$ctx_json" 2>/dev/null || true
      export CONTEXT_JSON="$ctx_json"
    fi
    _memory_v2_log_granted_from_context "$phase" "$requested_ids" "$attempt" "$ctx_json"
  done
}

_memory_v2_acquire_lock() {
  local store_path="$1"
  local lock_dir="${store_path}.lock"
  local attempts=0
  while ! mkdir "$lock_dir" 2>/dev/null; do
    attempts=$((attempts + 1))
    if [ "$attempts" -ge 100 ]; then
      rmdir "$lock_dir" 2>/dev/null || true
      mkdir "$lock_dir" 2>/dev/null || true
      break
    fi
    sleep 0.1
  done
}

_memory_v2_release_lock() {
  local store_path="$1"
  rmdir "${store_path}.lock" 2>/dev/null || true
}

memory_v2_increment_applied() {
  local ids_csv="${1:-}"
  [ -n "$ids_csv" ] || return 0
  local store_path
  store_path=$(_memory_v2_store_path)
  [ -f "$store_path" ] || return 0

  _memory_v2_acquire_lock "$store_path"
  node - "$store_path" "$ids_csv" <<'JSEOF' || true
const fs = require('fs');
const [,, storePath, idsCsv] = process.argv;
const ids = idsCsv.split(',').filter(Boolean);
try {
  const entries = JSON.parse(fs.readFileSync(storePath, 'utf8'));
  if (!Array.isArray(entries)) process.exit(0);
  const selected = new Set(ids);
  const now = new Date().toISOString();
  for (const entry of entries) {
    if (!entry || !selected.has(entry.id)) continue;
    entry.applied_count = Number.isInteger(entry.applied_count) ? entry.applied_count + 1 : 1;
    entry.last_applied = now;
  }
  const tmp = `${storePath}.tmp-${process.pid}`;
  fs.writeFileSync(tmp, JSON.stringify(entries, null, 2) + '\n');
  fs.renameSync(tmp, storePath);
} catch (_) {
  process.exit(0);
}
JSEOF
  _memory_v2_release_lock "$store_path"
}

memory_v2_mark_phase_success() {
  local phase="${1:?memory_v2_mark_phase_success: PHASE required}"
  local feat_id="${MONOZUKURI_FEATURE_ID:-}"
  [ -n "$feat_id" ] || return 0
  local trace_path
  trace_path=$(_memory_v2_feature_trace_path "$feat_id") || return 0
  [ -f "$trace_path" ] || return 0

  local ids_csv
  ids_csv=$(node - "$trace_path" "$phase" <<'JSEOF' || true
const fs = require('fs');
const [,, tracePath, phase] = process.argv;
try {
  const lines = fs.readFileSync(tracePath, 'utf8').split(/\n/).filter(Boolean);
  for (let i = lines.length - 1; i >= 0; i -= 1) {
    const entry = JSON.parse(lines[i]);
    if (entry.phase === phase && Array.isArray(entry.learnings)) {
      console.log(entry.learnings.join(','));
      process.exit(0);
    }
  }
} catch (_) {}
JSEOF
)
  memory_v2_increment_applied "$ids_csv"
}
