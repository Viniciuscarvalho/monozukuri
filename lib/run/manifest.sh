#!/bin/bash
# lib/run/manifest.sh — Run manifest and idempotent resumption (ADR-013)
#
# Tracks the full run at $CONFIG_DIR/runs/<run-id>/manifest.json.
# All writes are atomic (temp file + rename) to survive mid-run crashes.
#
# On `monozukuri run --resume`, manifest_reconcile detects drift between
# the manifest and disk state (e.g. worktrees deleted while run was paused).
# The pipeline's existing status.json checks skip already-done features.
#
# Public interface:
#   manifest_init [run_id]                              → creates manifest, prints run_id
#   manifest_update <run_id> <feat_id> <status> [phase] [wt_path]
#   manifest_finalize <run_id> [final_status]
#   manifest_reconcile <run_id>                         → 0=clean, 1=drift; sets MANIFEST_MISSING_WORKTREES
#   manifest_list_incomplete <run_id>                   → prints feat_ids not yet done
#   manifest_find_latest                                → prints most-recent run_id or ""
#   manifest_get_run_id                                 → prints $MANIFEST_RUN_ID

MANIFEST_RUN_ID=""
MANIFEST_MISSING_WORKTREES=""

manifest_init() {
  local run_id="${1:-$(date +%Y%m%d-%H%M%S)-$$}"
  MANIFEST_RUN_ID="$run_id"
  export MANIFEST_RUN_ID

  local run_dir="$CONFIG_DIR/runs/$run_id"
  mkdir -p "$run_dir"

  local manifest_file="$run_dir/manifest.json"
  local tmp_file
  tmp_file=$(mktemp "$run_dir/manifest.XXXXXX")

  node - "$run_id" "$tmp_file" <<'JSEOF' 2>/dev/null
const [,, run_id, tmp_file] = process.argv;
const fs = require('fs');
fs.writeFileSync(tmp_file, JSON.stringify({
  run_id,
  started_at: new Date().toISOString(),
  updated_at: new Date().toISOString(),
  status: 'running',
  features: []
}, null, 2));
JSEOF

  mv "$tmp_file" "$manifest_file"
  info "Manifest: initialized run $run_id"
  echo "$run_id"
}

manifest_get_run_id() {
  echo "${MANIFEST_RUN_ID:-}"
}

# manifest_update <run_id> <feat_id> <status> [phase] [wt_path]
manifest_update() {
  local run_id="$1"
  local feat_id="$2"
  local status="$3"
  local phase="${4:-}"
  local wt_path="${5:-}"

  [ -z "$run_id" ] && return 0

  local manifest_file="$CONFIG_DIR/runs/$run_id/manifest.json"
  [ -f "$manifest_file" ] || return 0

  local tmp_file
  tmp_file=$(mktemp "$(dirname "$manifest_file")/manifest.XXXXXX")

  node - "$manifest_file" "$feat_id" "$status" "$phase" "$wt_path" "$tmp_file" <<'JSEOF' 2>/dev/null
const [,, mf, feat_id, status, phase, wt_path, tmp_file] = process.argv;
const fs = require('fs');
const m = JSON.parse(fs.readFileSync(mf, 'utf-8'));
const idx = m.features.findIndex(f => f.feat_id === feat_id);
const prev = m.features[idx] || {};
const entry = {
  feat_id,
  worktree_path: wt_path || prev.worktree_path || '',
  status,
  phase: phase || prev.phase || '',
  updated_at: new Date().toISOString()
};
if (idx >= 0) m.features[idx] = entry;
else m.features.push(entry);
m.updated_at = new Date().toISOString();
fs.writeFileSync(tmp_file, JSON.stringify(m, null, 2));
JSEOF

  mv "$tmp_file" "$manifest_file"
}

# manifest_finalize <run_id> [final_status]
manifest_finalize() {
  local run_id="$1"
  local final_status="${2:-completed}"

  [ -z "$run_id" ] && return 0

  local manifest_file="$CONFIG_DIR/runs/$run_id/manifest.json"
  [ -f "$manifest_file" ] || return 0

  local tmp_file
  tmp_file=$(mktemp "$(dirname "$manifest_file")/manifest.XXXXXX")

  node - "$manifest_file" "$final_status" "$tmp_file" <<'JSEOF' 2>/dev/null
const [,, mf, final_status, tmp_file] = process.argv;
const fs = require('fs');
const m = JSON.parse(fs.readFileSync(mf, 'utf-8'));
m.status = final_status;
m.completed_at = new Date().toISOString();
m.updated_at = new Date().toISOString();
fs.writeFileSync(tmp_file, JSON.stringify(m, null, 2));
JSEOF

  mv "$tmp_file" "$manifest_file"
  info "Manifest: run $run_id finalized as $final_status"
}

# manifest_reconcile <run_id>
# Checks manifest vs disk. Returns 0 if clean; 1 if drift detected.
# Sets MANIFEST_MISSING_WORKTREES to a space-separated list of affected feat_ids.
manifest_reconcile() {
  local run_id="$1"
  local manifest_file="$CONFIG_DIR/runs/$run_id/manifest.json"

  MANIFEST_MISSING_WORKTREES=""

  if [ ! -f "$manifest_file" ]; then
    info "Manifest: no manifest found for run $run_id"
    return 0
  fi

  local drift=0
  local feat_id wt_path status

  while IFS="|" read -r feat_id wt_path status; do
    [ -z "$feat_id" ] && continue
    [ "$status" = "done" ] || [ "$status" = "pr-created" ] && continue
    if [ -n "$wt_path" ] && [ ! -d "$wt_path" ]; then
      warn "Manifest: worktree missing for $feat_id: $wt_path"
      MANIFEST_MISSING_WORKTREES="${MANIFEST_MISSING_WORKTREES} $feat_id"
      drift=1
    fi
  done < <(node -e "
    const fs = require('fs');
    const m = JSON.parse(fs.readFileSync('$manifest_file', 'utf-8'));
    (m.features || []).forEach(f =>
      console.log(f.feat_id + '|' + (f.worktree_path||'') + '|' + (f.status||''))
    );
  " 2>/dev/null || true)

  MANIFEST_MISSING_WORKTREES="${MANIFEST_MISSING_WORKTREES# }"
  return $drift
}

# manifest_list_incomplete <run_id>
# Prints feat_ids of features not yet done or pr-created.
manifest_list_incomplete() {
  local run_id="$1"
  local manifest_file="$CONFIG_DIR/runs/$run_id/manifest.json"
  [ -f "$manifest_file" ] || return 0

  node -e "
    const fs = require('fs');
    const m = JSON.parse(fs.readFileSync('$manifest_file', 'utf-8'));
    (m.features || [])
      .filter(f => f.status !== 'done' && f.status !== 'pr-created')
      .forEach(f => console.log(f.feat_id));
  " 2>/dev/null || true
}

# manifest_find_latest
# Prints the most recent run_id directory name, or empty string.
manifest_find_latest() {
  local runs_dir="$CONFIG_DIR/runs"
  [ -d "$runs_dir" ] || { echo ""; return 0; }
  ls -1t "$runs_dir" 2>/dev/null | head -1 || echo ""
}
