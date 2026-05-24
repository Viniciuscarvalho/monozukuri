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

_memory_v2_feature_trace_path() {
  local feat_id="${1:-${MONOZUKURI_FEATURE_ID:-}}"
  [ -n "$feat_id" ] || return 1
  local run_dir="${MONOZUKURI_RUN_DIR:-$(_memory_v2_config_dir)/runs}"
  printf '%s/%s/memory-injections.jsonl\n' "$run_dir" "$feat_id"
}

memory_v2_context_entries() {
  local feat_id="${1:?memory_v2_context_entries: FEAT_ID required}"
  local store_path
  store_path=$(_memory_v2_store_path)
  [ -f "$store_path" ] || { printf '[]\n'; return 0; }

  node - "$store_path" "$feat_id" "${MONOZUKURI_AGENT:-${ADAPTER:-}}" <<'JSEOF'
const fs = require('fs');
const [,, storePath, featureId, agent] = process.argv;

function marker(entry) {
  return `<!-- learning: ${entry.id} --> ${entry.insight}`;
}

try {
  const entries = JSON.parse(fs.readFileSync(storePath, 'utf8'));
  if (!Array.isArray(entries)) {
    console.log('[]');
    process.exit(0);
  }
  const filtered = entries.filter((entry) => {
    if (!entry || typeof entry !== 'object') return false;
    if (!entry.id || !entry.insight) return false;
    if (entry.agent_specific && entry.agent_specific !== agent) return false;
    if (entry.scope === 'feature') {
      return entry.source && entry.source.feature_id === featureId;
    }
    return entry.scope === 'project' || entry.scope === 'global';
  }).map((entry) => ({
    id: entry.id,
    summary: marker(entry)
  }));
  console.log(JSON.stringify(filtered));
} catch (_) {
  console.log('[]');
}
JSEOF
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
