#!/usr/bin/env bats
# test/unit/lib_feature_state.bats — unit tests for lib/core/feature-state.sh

setup() {
  REPO_ROOT="$(cd "$(dirname "$BATS_TEST_FILENAME")/../.." && pwd)"
  LIB_DIR="$REPO_ROOT/lib"
  TMPDIR_TEST="$(mktemp -d)"
  STATE_DIR="$TMPDIR_TEST/state"
  ROOT_DIR="$TMPDIR_TEST"
  export STATE_DIR ROOT_DIR
  source "$LIB_DIR/core/util.sh"
  source "$LIB_DIR/core/json-io.sh"
  source "$LIB_DIR/core/worktree.sh"
  source "$LIB_DIR/core/feature-state.sh"
}

teardown() {
  rm -rf "$TMPDIR_TEST"
}

_init_status() {
  local feat_id="$1"
  mkdir -p "$STATE_DIR/$feat_id/logs"
  cat > "$STATE_DIR/$feat_id/status.json" <<JSON
{"feature_id":"$feat_id","status":"created","phase":"pending",
 "created_at":"2026-01-01T00:00:00Z","updated_at":"2026-01-01T00:00:00Z"}
JSON
}

@test "feature-state.sh sources without error" {
  run bash -c "
    STATE_DIR=/tmp ROOT_DIR=/tmp
    source '$LIB_DIR/core/util.sh'
    source '$LIB_DIR/core/json-io.sh'
    source '$LIB_DIR/core/worktree.sh'
    source '$LIB_DIR/core/feature-state.sh'
    echo ok
  "
  [ "$status" -eq 0 ]
  [[ "$output" == *"ok"* ]]
}

@test "fstate_get_status returns 'none' for uninitialised feature" {
  result=$(fstate_get_status "nonexistent-feat")
  [ "$result" = "none" ]
}

@test "fstate_transition updates status.json" {
  _init_status "test-feat-1"
  fstate_transition "test-feat-1" "in-progress" "implementation"
  result=$(fstate_get_status "test-feat-1")
  [ "$result" = "in-progress" ]
}

@test "fstate_record_pause writes pause.json" {
  mkdir -p "$STATE_DIR/test-feat-2"
  fstate_record_pause "test-feat-2" "human" "size-gate"
  [ -f "$STATE_DIR/test-feat-2/pause.json" ]
  kind=$(fstate_get_pause "test-feat-2" "pause_kind")
  [ "$kind" = "human" ]
}

@test "fstate_get_pause returns reason field" {
  mkdir -p "$STATE_DIR/test-feat-3"
  fstate_record_pause "test-feat-3" "transient" "build-broken"
  reason=$(fstate_get_pause "test-feat-3" "reason")
  [ "$reason" = "build-broken" ]
}

@test "fstate_record_result writes results.json with pipeline shape" {
  mkdir -p "$STATE_DIR/test-feat-4"
  fstate_record_result "test-feat-4" "0" "Add login" "42"
  [ -f "$STATE_DIR/test-feat-4/results.json" ]
  has_pipeline=$(node -p "
    try{
      const d=JSON.parse(require('fs').readFileSync('$STATE_DIR/test-feat-4/results.json','utf-8'));
      d.pipeline?'yes':'no';
    }catch(e){'no'}
  " 2>/dev/null)
  [ "$has_pipeline" = "yes" ]
}

@test "fstate_check_breaking returns false when no breaking changes" {
  mkdir -p "$STATE_DIR/test-feat-5"
  fstate_record_result "test-feat-5" "0" "Add login" "10"
  result=$(fstate_check_breaking "test-feat-5")
  [ "$result" = "false" ]
}

@test "fstate_get_file_count returns 0 for fresh result" {
  mkdir -p "$STATE_DIR/test-feat-6"
  fstate_record_result "test-feat-6" "0" "Add login" "10"
  count=$(fstate_get_file_count "test-feat-6")
  [ "$count" = "0" ]
}

@test "fstate_set_pr_url and fstate_get_pr_url round-trip" {
  mkdir -p "$STATE_DIR/test-feat-7"
  fstate_record_result "test-feat-7" "0" "Add login" "10"
  fstate_set_pr_url "test-feat-7" "https://github.com/org/repo/pull/42"
  url=$(fstate_get_pr_url "test-feat-7")
  [ "$url" = "https://github.com/org/repo/pull/42" ]
}
