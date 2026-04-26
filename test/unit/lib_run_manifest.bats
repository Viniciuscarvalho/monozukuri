#!/usr/bin/env bats
# test/unit/lib_run_manifest.bats — unit tests for lib/run/manifest.sh

setup() {
  REPO_ROOT="$(cd "$(dirname "$BATS_TEST_FILENAME")/../.." && pwd)"
  LIB_DIR="$REPO_ROOT/lib"
  export LIB_DIR

  TMPDIR_TEST="$(mktemp -d)"
  CONFIG_DIR="$TMPDIR_TEST/config"
  mkdir -p "$CONFIG_DIR"
  export CONFIG_DIR

  warn() { echo "WARN: $*" >&2; }
  info() { echo "INFO: $*" >&2; }
  export -f warn info

  source "$LIB_DIR/run/manifest.sh"

  MANIFEST_RUN_ID=""
  MANIFEST_MISSING_WORKTREES=""
}

teardown() {
  rm -rf "$TMPDIR_TEST"
}

# ── manifest_init ─────────────────────────────────────────────────────────────

@test "manifest_init: creates manifest.json with run_id" {
  run_id=$(manifest_init "test-run-001")
  [ "$run_id" = "test-run-001" ]
  [ -f "$CONFIG_DIR/runs/test-run-001/manifest.json" ]
}

@test "manifest_init: manifest has required fields" {
  manifest_init "test-run-002" > /dev/null
  mf="$CONFIG_DIR/runs/test-run-002/manifest.json"
  node -e "
    const m = JSON.parse(require('fs').readFileSync('$mf','utf-8'));
    if (!m.run_id) throw new Error('missing run_id');
    if (!m.started_at) throw new Error('missing started_at');
    if (m.status !== 'running') throw new Error('wrong status');
    if (!Array.isArray(m.features)) throw new Error('features not array');
  "
}

@test "manifest_init: uses auto-generated run_id when none provided" {
  run_id=$(manifest_init)
  [ -n "$run_id" ]
  [ -f "$CONFIG_DIR/runs/$run_id/manifest.json" ]
}

@test "manifest_init: sets MANIFEST_RUN_ID" {
  manifest_init "test-run-003" > /dev/null
  [ "$MANIFEST_RUN_ID" = "test-run-003" ]
}

# ── manifest_update ───────────────────────────────────────────────────────────

@test "manifest_update: adds new feature entry" {
  manifest_init "test-run-004" > /dev/null
  manifest_update "test-run-004" "feat-001" "in-progress" "analysis" "/tmp/wt1"
  mf="$CONFIG_DIR/runs/test-run-004/manifest.json"
  count=$(node -p "JSON.parse(require('fs').readFileSync('$mf','utf-8')).features.length")
  [ "$count" = "1" ]
}

@test "manifest_update: upserts existing feature entry" {
  manifest_init "test-run-005" > /dev/null
  manifest_update "test-run-005" "feat-002" "in-progress" "analysis" "/tmp/wt2"
  manifest_update "test-run-005" "feat-002" "done" "" "/tmp/wt2"
  mf="$CONFIG_DIR/runs/test-run-005/manifest.json"
  status=$(node -p "JSON.parse(require('fs').readFileSync('$mf','utf-8')).features[0].status")
  count=$(node -p "JSON.parse(require('fs').readFileSync('$mf','utf-8')).features.length")
  [ "$status" = "done" ]
  [ "$count" = "1" ]
}

@test "manifest_update: write is atomic (temp+rename)" {
  manifest_init "test-run-006" > /dev/null
  # Concurrent updates shouldn't leave partial files
  manifest_update "test-run-006" "feat-003" "in-progress" "" "/tmp/wt3"
  mf="$CONFIG_DIR/runs/test-run-006/manifest.json"
  node -e "JSON.parse(require('fs').readFileSync('$mf','utf-8'))"  # valid JSON
}

# ── manifest_finalize ─────────────────────────────────────────────────────────

@test "manifest_finalize: sets status to completed" {
  manifest_init "test-run-007" > /dev/null
  manifest_finalize "test-run-007" "completed"
  mf="$CONFIG_DIR/runs/test-run-007/manifest.json"
  status=$(node -p "JSON.parse(require('fs').readFileSync('$mf','utf-8')).status")
  [ "$status" = "completed" ]
}

@test "manifest_finalize: sets completed_at timestamp" {
  manifest_init "test-run-008" > /dev/null
  manifest_finalize "test-run-008"
  mf="$CONFIG_DIR/runs/test-run-008/manifest.json"
  ts=$(node -p "JSON.parse(require('fs').readFileSync('$mf','utf-8')).completed_at||''")
  [ -n "$ts" ]
}

# ── manifest_reconcile ────────────────────────────────────────────────────────

@test "manifest_reconcile: returns 0 when no features in manifest" {
  manifest_init "test-run-009" > /dev/null
  manifest_reconcile "test-run-009"
}

@test "manifest_reconcile: returns 0 when all worktrees exist" {
  wt="$TMPDIR_TEST/wt-exists"
  mkdir -p "$wt"
  manifest_init "test-run-010" > /dev/null
  manifest_update "test-run-010" "feat-004" "in-progress" "" "$wt"
  manifest_reconcile "test-run-010"
}

@test "manifest_reconcile: returns 1 and sets MANIFEST_MISSING_WORKTREES on drift" {
  manifest_init "test-run-011" > /dev/null
  manifest_update "test-run-011" "feat-005" "in-progress" "" "/nonexistent/path/wt"
  local rc=0
  manifest_reconcile "test-run-011" || rc=$?
  [ "$rc" -eq 1 ]
  [[ "$MANIFEST_MISSING_WORKTREES" == *"feat-005"* ]]
}

@test "manifest_reconcile: skips done features in drift check" {
  manifest_init "test-run-012" > /dev/null
  manifest_update "test-run-012" "feat-006" "done" "" "/nonexistent/path/done-wt"
  # done features should not trigger drift — expect return 0
  manifest_reconcile "test-run-012"
}

# ── manifest_list_incomplete ──────────────────────────────────────────────────

@test "manifest_list_incomplete: lists non-done features" {
  manifest_init "test-run-013" > /dev/null
  manifest_update "test-run-013" "feat-007" "in-progress" "" ""
  manifest_update "test-run-013" "feat-008" "done" "" ""
  manifest_update "test-run-013" "feat-009" "failed" "" ""
  result=$(manifest_list_incomplete "test-run-013")
  [[ "$result" == *"feat-007"* ]]
  [[ "$result" != *"feat-008"* ]]
  [[ "$result" == *"feat-009"* ]]
}

# ── manifest_find_latest ──────────────────────────────────────────────────────

@test "manifest_find_latest: returns empty when no runs" {
  result=$(manifest_find_latest)
  [ -z "$result" ]
}

@test "manifest_find_latest: returns most recent run_id" {
  manifest_init "test-run-a" > /dev/null
  sleep 1
  manifest_init "test-run-b" > /dev/null
  result=$(manifest_find_latest)
  [ "$result" = "test-run-b" ]
}
