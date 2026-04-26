#!/bin/bash
# lib/core/feature-state.sh — Single seam for feature state persistence
#
# Owns all reads and writes to .monozukuri/state/<feat-id>/:
#   status.json  — lifecycle phase transitions
#   pause.json   — pause taxonomy record
#   results.json — final output shape (PR URL, pipeline, breaking changes)
#
# Interface: fstate_* verbs. File paths, JSON schemas, and inline Python/Node
# are implementation details hidden behind this seam.
#
# Requires: lib/core/worktree.sh (wt_update_status, wt_get_status)
#           lib/core/json-io.sh  (json_write_results, json_stringify)

# ── fstate_transition ────────────────────────────────────────────────────────
# Usage: fstate_transition <feat_id> <status> [phase]
# Transitions the feature to a new lifecycle status.
fstate_transition() {
  wt_update_status "$1" "$2" "${3:-}"
}

# ── fstate_get_status ────────────────────────────────────────────────────────
# Usage: fstate_get_status <feat_id>
# Returns current status string, or "none" if the feature has not been initialised.
fstate_get_status() {
  wt_get_status "$1"
}

# ── fstate_record_pause ──────────────────────────────────────────────────────
# Usage: fstate_record_pause <feat_id> <pause_kind: human|transient> <reason>
# Writes the canonical pause taxonomy record to pause.json.
# Values are passed to Node via argv to avoid shell injection.
fstate_record_pause() {
  local feat_id="$1" pause_kind="$2" reason="$3"
  local pause_file="$STATE_DIR/$feat_id/pause.json"
  mkdir -p "$STATE_DIR/$feat_id"
  node - "$feat_id" "$pause_kind" "$reason" "$pause_file" <<'JSEOF' 2>/dev/null || true
const [,, feat_id, pause_kind, reason, pause_file] = process.argv;
const fs = require('fs');
fs.writeFileSync(pause_file, JSON.stringify(
  { feat_id, pause_kind, reason, paused_at: new Date().toISOString() },
  null, 2
));
JSEOF
}

# ── fstate_get_pause ─────────────────────────────────────────────────────────
# Usage: fstate_get_pause <feat_id> <field: pause_kind|reason>
# Returns the field value from pause.json, or empty string.
fstate_get_pause() {
  local feat_id="$1" field="$2"
  local pause_file="$STATE_DIR/$feat_id/pause.json"
  [ -f "$pause_file" ] || { echo ""; return; }
  node -p "try{JSON.parse(require('fs').readFileSync('$pause_file','utf-8'))['$field']||''}catch(e){''}" \
    2>/dev/null || echo ""
}

# ── fstate_record_result ─────────────────────────────────────────────────────
# Usage: fstate_record_result <feat_id> <exit_code> <title> <duration_s>
# Writes the canonical results.json shape. Idempotent — merges on top of any
# existing content. Replaces the inline Python block in run_feature.
fstate_record_result() {
  local feat_id="$1" exit_code="$2" title="$3" duration="$4"
  local results_file="$STATE_DIR/$feat_id/results.json"

  local title_json
  title_json=$(printf '%s' "$title" | json_stringify 2>/dev/null || printf '""')

  json_write_results "$results_file" \
    feature_id       "$feat_id" \
    status_ok        "$exit_code" \
    title            "$title" \
    duration_seconds "$duration" \
    2>/dev/null || true

  # Ensure the full pipeline shape is present when json_write_results produced a minimal file
  node - "$results_file" "$feat_id" "$exit_code" "$title_json" "$duration" <<'JSEOF' 2>/dev/null || true
const [,, f, feat_id, ec, title_json, dur] = process.argv;
const fs = require('fs');
let existing = {};
try { existing = JSON.parse(fs.readFileSync(f, 'utf-8')); } catch (_) {}
if (!existing.pipeline) {
  const code = parseInt(ec, 10);
  const status = code === 0 ? 'completed' : (code === 2 || code === 10 ? 'paused' : 'failed');
  Object.assign(existing, {
    feature_id: feat_id,
    status,
    title: JSON.parse(title_json),
    pipeline: {
      prd:            { status: 'completed' },
      techspec:       { status: 'pending' },
      tasks:          { status: 'pending' },
      implementation: { status: 'pending' },
      tests:          { status: 'pending' },
      review:         { status: 'pending' }
    },
    context_generated: {
      files_created: [], files_modified: [], schema_changes: [],
      new_dependencies: [], breaking_changes: []
    },
    pr_url: null,
    duration_seconds: parseInt(dur, 10),
    errors: [],
    tasks: []
  });
  fs.writeFileSync(f, JSON.stringify(existing, null, 2));
}
JSEOF
}

# ── fstate_set_pr_url ────────────────────────────────────────────────────────
# Usage: fstate_set_pr_url <feat_id> <pr_url>
# Patches pr_url and pipeline.review into results.json.
fstate_set_pr_url() {
  local feat_id="$1" pr_url="$2"
  local results_file="$STATE_DIR/$feat_id/results.json"
  [ -f "$results_file" ] || return 0
  node - "$results_file" "$pr_url" <<'JSEOF' 2>/dev/null || true
const [,, f, pr_url] = process.argv;
const fs = require('fs');
const r = JSON.parse(fs.readFileSync(f, 'utf-8'));
r.pr_url = pr_url;
if (!r.pipeline) r.pipeline = {};
r.pipeline.review = { status: 'completed', pr_url };
fs.writeFileSync(f, JSON.stringify(r, null, 2));
JSEOF
}

# ── fstate_get_pr_url ────────────────────────────────────────────────────────
# Usage: fstate_get_pr_url <feat_id>
# Returns the PR URL from results.json, or empty string.
fstate_get_pr_url() {
  local feat_id="$1"
  local results_file="$STATE_DIR/$feat_id/results.json"
  [ -f "$results_file" ] || { echo ""; return; }
  node -p "try{JSON.parse(require('fs').readFileSync('$results_file','utf-8')).pr_url||''}catch(e){''}" \
    2>/dev/null || echo ""
}

# ── fstate_check_breaking ────────────────────────────────────────────────────
# Usage: fstate_check_breaking <feat_id>
# Prints "true" if results.json contains breaking_changes entries, "false" otherwise.
fstate_check_breaking() {
  local feat_id="$1"
  local results_file="$STATE_DIR/$feat_id/results.json"
  [ -f "$results_file" ] || { echo "false"; return; }
  node -p "
    try {
      const d = JSON.parse(require('fs').readFileSync('$results_file','utf-8'));
      (d.context_generated && d.context_generated.breaking_changes &&
       d.context_generated.breaking_changes.length > 0) ? 'true' : 'false';
    } catch(e) { 'false'; }
  " 2>/dev/null || echo "false"
}

# ── fstate_get_file_count ────────────────────────────────────────────────────
# Usage: fstate_get_file_count <feat_id>
# Returns total files_created + files_modified from results.json, or 0.
fstate_get_file_count() {
  local feat_id="$1"
  local results_file="$STATE_DIR/$feat_id/results.json"
  [ -f "$results_file" ] || { echo "0"; return; }
  node -p "
    try {
      const r = JSON.parse(require('fs').readFileSync('$results_file','utf-8'));
      const cg = r.context_generated || {};
      (cg.files_created || []).length + (cg.files_modified || []).length;
    } catch(e) { 0; }
  " 2>/dev/null || echo "0"
}
