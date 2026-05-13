#!/usr/bin/env bats
# test/unit/multi_turn_session_helper.bats — ADR-017: _cc_session_id_for_feature helper

setup() {
  REPO_ROOT="$(cd "$(dirname "$BATS_TEST_FILENAME")/../.." && pwd)"
  LIB_DIR="$REPO_ROOT/lib"
  export LIB_DIR REPO_ROOT

  _MT_TEST_DIR=$(mktemp -d /tmp/mt-session-test-XXXXX)
  export _MT_TEST_DIR STATE_DIR="$_MT_TEST_DIR/state"
  mkdir -p "$STATE_DIR"

  source "$LIB_DIR/agent/adapter-claude-code.sh"
}

teardown() {
  rm -rf "${_MT_TEST_DIR:-}" 2>/dev/null || true
  unset STATE_DIR MONOZUKURI_RUN_DIR 2>/dev/null || true
}

@test "_cc_session_id_for_feature: first call creates session.json and returns a UUID" {
  local sid
  sid=$(_cc_session_id_for_feature "feat-mt-001")

  [ -n "$sid" ]
  local sf="$STATE_DIR/feat-mt-001/session.json"
  [ -f "$sf" ]
  [ "$(jq -r '.session_id' "$sf")" = "$sid" ]
  [ "$(jq -r '.agent' "$sf")" = "claude-code" ]
}

@test "_cc_session_id_for_feature: second call returns the same UUID" {
  local sid1 sid2
  sid1=$(_cc_session_id_for_feature "feat-mt-002")
  sid2=$(_cc_session_id_for_feature "feat-mt-002")

  [ "$sid1" = "$sid2" ]
}

@test "_cc_session_id_for_feature: session.json has last_completed_turn as empty string" {
  _cc_session_id_for_feature "feat-mt-003" >/dev/null
  local sf="$STATE_DIR/feat-mt-003/session.json"
  local lct
  lct=$(jq -r '.last_completed_turn // empty' "$sf")
  [ -z "$lct" ]
}

@test "_cc_session_id_for_feature: uses MONOZUKURI_RUN_DIR fallback when STATE_DIR unset" {
  local old_state="$STATE_DIR"
  unset STATE_DIR
  export MONOZUKURI_RUN_DIR="$_MT_TEST_DIR/runs"
  mkdir -p "$MONOZUKURI_RUN_DIR"

  local sid
  sid=$(_cc_session_id_for_feature "feat-mt-004")

  [ -n "$sid" ]
  [ -f "$MONOZUKURI_RUN_DIR/feat-mt-004/session.json" ]
  STATE_DIR="$old_state"
}

@test "_cc_session_jsonl_exists: returns false when jsonl is absent" {
  _cc_session_jsonl_exists "nonexistent-uuid" "/tmp" && return 1 || return 0
}

@test "_cc_session_jsonl_exists: returns true when jsonl file exists" {
  local fake_uuid="aaaabbbb-cccc-dddd-eeee-ffffffffffff"
  local wt_path="$_MT_TEST_DIR/wt"
  local cwd_slug
  cwd_slug=$(printf '%s' "$wt_path" | tr '/' '-')
  mkdir -p "${HOME}/.claude/projects/${cwd_slug}"
  touch "${HOME}/.claude/projects/${cwd_slug}/${fake_uuid}.jsonl"

  _cc_session_jsonl_exists "$fake_uuid" "$wt_path"
  local rc=$?

  rm -f "${HOME}/.claude/projects/${cwd_slug}/${fake_uuid}.jsonl"
  [ "$rc" -eq 0 ]
}
