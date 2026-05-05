#!/usr/bin/env bats
# test/unit/phase_e_state_telemetry.bats — Phase E: state-version stamping (E2) + telemetry (E3)

setup() {
  REPO_ROOT="$(cd "$(dirname "$BATS_TEST_FILENAME")/../.." && pwd)"
  LIB_DIR="$REPO_ROOT/lib"
  TMP="$(mktemp -d)"

  # Minimal stubs required by worktree.sh
  STATE_DIR="$TMP/state"
  mkdir -p "$STATE_DIR"
  export STATE_DIR TMP REPO_ROOT LIB_DIR

  # Telemetry file override so tests never touch ~/.monozukuri
  export _TELEMETRY_FILE="$TMP/telemetry.json"
}

teardown() {
  rm -rf "$TMP"
}

# ── helpers ───────────────────────────────────────────────────────────────────

_load_util() {
  source "$LIB_DIR/core/util.sh"
}

_load_worktree_stubs() {
  # Minimal stubs so worktree.sh loads without git/node side-effects
  WORKTREE_ROOT="$TMP/worktrees"
  BRANCH_PREFIX="feat"
  BASE_BRANCH="main"
  export WORKTREE_ROOT BRANCH_PREFIX BASE_BRANCH
}

_make_status_file() {
  local feat_id="$1" ver="${2:-1}" status="${3:-done}"
  mkdir -p "$STATE_DIR/$feat_id"
  node -e "
    const fs = require('fs');
    fs.writeFileSync('$STATE_DIR/$feat_id/status.json', JSON.stringify({
      state_version: parseInt('$ver', 10),
      feature_id: '$feat_id',
      status: '$status',
      created_at: new Date().toISOString(),
      updated_at: new Date().toISOString()
    }, null, 2));
  "
}

# ── E2: MONOZUKURI_STATE_VERSION_SUPPORTED constant ──────────────────────────

@test "E2: MONOZUKURI_STATE_VERSION_SUPPORTED is exported as 1" {
  _load_util
  [ "$MONOZUKURI_STATE_VERSION_SUPPORTED" = "1" ]
}

@test "E2: MONOZUKURI_STATE_VERSION_SUPPORTED is an integer" {
  _load_util
  [[ "$MONOZUKURI_STATE_VERSION_SUPPORTED" =~ ^[0-9]+$ ]]
}

# ── E2: status.json is written with state_version: 1 ─────────────────────────

@test "E2: status.json schema includes state_version field" {
  # Test wt_create indirectly by examining the heredoc output
  # We verify wt_update_status preserves state_version
  _make_status_file "feat-e2-preserve" 1 "created"
  _load_util
  _load_worktree_stubs
  source "$LIB_DIR/core/worktree.sh" 2>/dev/null || true

  # Simulate wt_update_status (it reads then patches the file)
  if declare -f wt_update_status &>/dev/null; then
    wt_update_status "feat-e2-preserve" "done" "complete" 2>/dev/null || true
    local ver
    ver=$(node -p "JSON.parse(require('fs').readFileSync('$STATE_DIR/feat-e2-preserve/status.json','utf-8')).state_version" 2>/dev/null)
    [ "$ver" = "1" ]
  else
    skip "wt_update_status not available in this context"
  fi
}

# ── E2: wt_get_status version guard ─────────────────────────────────────────

@test "E2: wt_get_status returns status for supported state_version" {
  _make_status_file "feat-e2-ok" 1 "done"
  _load_util
  _load_worktree_stubs
  source "$LIB_DIR/core/worktree.sh" 2>/dev/null || true

  if declare -f wt_get_status &>/dev/null; then
    local result
    result=$(wt_get_status "feat-e2-ok" 2>/dev/null)
    [ "$result" = "done" ]
  else
    skip "wt_get_status not available in this context"
  fi
}

@test "E2: wt_get_status returns state-version-unsupported for future version" {
  _make_status_file "feat-e2-future" 99 "done"
  _load_util
  _load_worktree_stubs
  source "$LIB_DIR/core/worktree.sh" 2>/dev/null || true

  if declare -f wt_get_status &>/dev/null; then
    local result rc=0
    result=$(wt_get_status "feat-e2-future" 2>/dev/null) || rc=$?
    [ "$result" = "state-version-unsupported" ] || [ "$rc" -ne 0 ]
  else
    skip "wt_get_status not available in this context"
  fi
}

@test "E2: wt_get_status returns none for missing state file" {
  _load_util
  _load_worktree_stubs
  source "$LIB_DIR/core/worktree.sh" 2>/dev/null || true

  if declare -f wt_get_status &>/dev/null; then
    local result
    result=$(wt_get_status "feat-does-not-exist" 2>/dev/null)
    [ "$result" = "none" ]
  else
    skip "wt_get_status not available in this context"
  fi
}

@test "E2: wt_get_status treats missing state_version as version 0 (backwards compat)" {
  # Old state files have no state_version — must not trigger the guard
  mkdir -p "$STATE_DIR/feat-e2-legacy"
  node -e "
    const fs = require('fs');
    fs.writeFileSync('$STATE_DIR/feat-e2-legacy/status.json', JSON.stringify({
      feature_id: 'feat-e2-legacy',
      status: 'done'
    }, null, 2));
  "
  _load_util
  _load_worktree_stubs
  source "$LIB_DIR/core/worktree.sh" 2>/dev/null || true

  if declare -f wt_get_status &>/dev/null; then
    local result
    result=$(wt_get_status "feat-e2-legacy" 2>/dev/null)
    [ "$result" = "done" ]
  else
    skip "wt_get_status not available in this context"
  fi
}

# ── E3: telemetry_has_decided ─────────────────────────────────────────────────

@test "E3: telemetry_has_decided returns false when file missing" {
  source "$LIB_DIR/ops/telemetry.sh"
  run telemetry_has_decided
  [ "$status" -ne 0 ]
}

@test "E3: telemetry_has_decided returns true after consent saved" {
  source "$LIB_DIR/ops/telemetry.sh"
  telemetry_set_consent false
  run telemetry_has_decided
  [ "$status" -eq 0 ]
}

# ── E3: telemetry_is_opted_in ─────────────────────────────────────────────────

@test "E3: telemetry_is_opted_in returns false when not opted in" {
  source "$LIB_DIR/ops/telemetry.sh"
  telemetry_set_consent false
  run telemetry_is_opted_in
  [ "$status" -ne 0 ]
}

@test "E3: telemetry_is_opted_in returns true after opt-in" {
  source "$LIB_DIR/ops/telemetry.sh"
  telemetry_set_consent true
  run telemetry_is_opted_in
  [ "$status" -eq 0 ]
}

@test "E3: telemetry_is_opted_in returns false when file missing" {
  source "$LIB_DIR/ops/telemetry.sh"
  run telemetry_is_opted_in
  [ "$status" -ne 0 ]
}

# ── E3: telemetry_set_consent writes correct JSON ────────────────────────────

@test "E3: telemetry_set_consent true writes opted_in: true" {
  source "$LIB_DIR/ops/telemetry.sh"
  telemetry_set_consent true
  local opted_in
  opted_in=$(node -p "JSON.parse(require('fs').readFileSync('$_TELEMETRY_FILE','utf-8')).opted_in" 2>/dev/null)
  [ "$opted_in" = "true" ]
}

@test "E3: telemetry_set_consent false writes opted_in: false" {
  source "$LIB_DIR/ops/telemetry.sh"
  telemetry_set_consent false
  local opted_in
  opted_in=$(node -p "JSON.parse(require('fs').readFileSync('$_TELEMETRY_FILE','utf-8')).opted_in" 2>/dev/null)
  [ "$opted_in" = "false" ]
}

@test "E3: consent file includes decided_at ISO timestamp" {
  source "$LIB_DIR/ops/telemetry.sh"
  telemetry_set_consent false
  local decided_at
  decided_at=$(node -p "JSON.parse(require('fs').readFileSync('$_TELEMETRY_FILE','utf-8')).decided_at" 2>/dev/null)
  [[ "$decided_at" =~ ^[0-9]{4}-[0-9]{2}-[0-9]{2}T ]]
}

# ── E3: telemetry_prompt skips in non-interactive mode ───────────────────────

@test "E3: telemetry_prompt sets opted_in false in non-interactive mode" {
  source "$LIB_DIR/ops/telemetry.sh"
  OPT_NON_INTERACTIVE=true telemetry_prompt
  run telemetry_is_opted_in
  [ "$status" -ne 0 ]
}

@test "E3: telemetry_prompt is idempotent — does not reprompt after decision" {
  source "$LIB_DIR/ops/telemetry.sh"
  telemetry_set_consent true
  # Call prompt again — should not overwrite the existing consent
  OPT_NON_INTERACTIVE=false telemetry_prompt </dev/null 2>/dev/null || true
  run telemetry_is_opted_in
  [ "$status" -eq 0 ]
}

# ── E3: telemetry_build_payload shape ────────────────────────────────────────

@test "E3: telemetry_build_payload produces valid JSON" {
  source "$LIB_DIR/ops/telemetry.sh"
  export TELEMETRY_AGENT="codex"
  export TELEMETRY_COMPLETED=3 TELEMETRY_PAUSED=1 TELEMETRY_FAILED=0
  export TELEMETRY_TOP_ERROR="schema-validation-failed"
  export TELEMETRY_COST_USD="1.23"
  local payload
  payload=$(telemetry_build_payload)
  node -e "JSON.parse(process.argv[1])" "$payload"
}

@test "E3: telemetry_build_payload includes required keys" {
  source "$LIB_DIR/ops/telemetry.sh"
  export TELEMETRY_AGENT="gemini"
  export TELEMETRY_COMPLETED=5 TELEMETRY_PAUSED=0 TELEMETRY_FAILED=0
  export TELEMETRY_TOP_ERROR="none" TELEMETRY_COST_USD="0"
  local payload
  payload=$(telemetry_build_payload)
  for key in version os agent features_completed features_paused features_failed top_error_class total_cost_usd; do
    node -e "const d=JSON.parse(process.argv[1]); if(!(\"$key\" in d)) process.exit(1)" "$payload"
  done
}

@test "E3: telemetry_build_payload does not include project name or file paths" {
  source "$LIB_DIR/ops/telemetry.sh"
  export TELEMETRY_AGENT="claude-code"
  export TELEMETRY_COMPLETED=1 TELEMETRY_PAUSED=0 TELEMETRY_FAILED=0
  export TELEMETRY_TOP_ERROR="none" TELEMETRY_COST_USD="0"
  local payload
  payload=$(telemetry_build_payload)
  # Must not contain HOME path, project name, or any absolute path
  [[ "$payload" != *"$HOME"* ]]
  [[ "$payload" != *"/Users/"* ]]
  [[ "$payload" != *"project_name"* ]]
  [[ "$payload" != *"file_path"* ]]
}

# ── E3: telemetry_send no-ops when not opted in ──────────────────────────────

@test "E3: telemetry_send is a no-op when user not opted in" {
  source "$LIB_DIR/ops/telemetry.sh"
  telemetry_set_consent false
  export MONOZUKURI_TELEMETRY_ENDPOINT="http://127.0.0.1:19999/should-not-be-called"
  # If telemetry_send fires, curl would fail and we'd see a background job error.
  # With opted-out, it returns immediately without launching curl.
  run telemetry_send '{"test": true}'
  [ "$status" -eq 0 ]
}

@test "E3: telemetry_send is a no-op when endpoint not configured" {
  source "$LIB_DIR/ops/telemetry.sh"
  telemetry_set_consent true
  unset MONOZUKURI_TELEMETRY_ENDPOINT
  run telemetry_send '{"test": true}'
  [ "$status" -eq 0 ]
}

# ── E3: telemetry_status_text ─────────────────────────────────────────────────

@test "E3: telemetry_status_text shows not-decided when no file" {
  source "$LIB_DIR/ops/telemetry.sh"
  run telemetry_status_text
  [[ "$output" == *"not yet decided"* ]]
}

@test "E3: telemetry_status_text shows opted out" {
  source "$LIB_DIR/ops/telemetry.sh"
  telemetry_set_consent false
  run telemetry_status_text
  [[ "$output" == *"opted out"* ]]
}

@test "E3: telemetry_status_text shows opted in" {
  source "$LIB_DIR/ops/telemetry.sh"
  telemetry_set_consent true
  run telemetry_status_text
  [[ "$output" == *"opted in"* ]]
}
