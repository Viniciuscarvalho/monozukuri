#!/usr/bin/env bats
# test/unit/lib_run_policy.bats — unit tests for lib/run/policy.sh

setup() {
  REPO_ROOT="$(cd "$(dirname "$BATS_TEST_FILENAME")/../.." && pwd)"
  LIB_DIR="$REPO_ROOT/lib"
  export LIB_DIR

  TMPDIR_TEST="$(mktemp -d)"
  STATE_DIR="$TMPDIR_TEST/state"
  ROOT_DIR="$TMPDIR_TEST"
  export STATE_DIR ROOT_DIR

  warn()  { echo "WARN: $*" >&2; }
  info()  { echo "INFO: $*" >&2; }
  err()   { echo "ERR: $*" >&2; }
  export -f warn info err

  # Stub seam functions used by policy.sh
  fstate_transition()   { echo "fstate_transition: $*" >&2; }
  fstate_record_pause() { echo "fstate_record_pause: $*" >&2; }
  monozukuri_emit()     { :; }
  mem_record_error()    { :; }
  platform_claude()     { :; }
  export -f fstate_transition fstate_record_pause monozukuri_emit mem_record_error platform_claude

  source "$LIB_DIR/agent/error.sh"
  source "$LIB_DIR/run/policy.sh"
}

teardown() {
  rm -rf "$TMPDIR_TEST"
}

_make_envelope() {
  local class="$1" code="$2" msg="${3:-test}" retryable="${4:-0}"
  if [ "$retryable" -gt 0 ]; then
    printf '{"class":"%s","code":"%s","message":"%s","retryable_after":%d}' \
      "$class" "$code" "$msg" "$retryable"
  else
    printf '{"class":"%s","code":"%s","message":"%s"}' "$class" "$code" "$msg"
  fi
}

_init_feat() {
  local feat_id="$1"
  mkdir -p "$STATE_DIR/$feat_id"
}

# ── policy_handle_rate_limit ──────────────────────────────────────────────────

@test "policy_handle_rate_limit: ≤600s returns 0 after sleep (stubbed)" {
  # Override sleep to avoid actual delay
  sleep() { :; }
  export -f sleep
  _init_feat "rl-feat-1"
  local rc=0
  policy_handle_rate_limit "rl-feat-1" 30 || rc=$?
  [ "$rc" -eq 0 ]
}

@test "policy_handle_rate_limit: 601-3600s returns 2 (defer)" {
  _init_feat "rl-feat-2"
  local rc=0
  policy_handle_rate_limit "rl-feat-2" 900 || rc=$?
  [ "$rc" -eq 2 ]
}

@test "policy_handle_rate_limit: >3600s returns 3 (pause-clean)" {
  _init_feat "rl-feat-3"
  local rc=0
  policy_handle_rate_limit "rl-feat-3" 7200 || rc=$?
  [ "$rc" -eq 3 ]
}

# ── policy_handle_cross_run_retry ─────────────────────────────────────────────

@test "policy_handle_cross_run_retry: first retry returns 2 and writes retry-count" {
  _init_feat "retry-feat-1"
  local rc=0
  policy_handle_cross_run_retry "retry-feat-1" || rc=$?
  [ "$rc" -eq 2 ]
  count=$(cat "$STATE_DIR/retry-feat-1/retry-count")
  [ "$count" = "1" ]
}

@test "policy_handle_cross_run_retry: exhausted retries returns 1" {
  _init_feat "retry-feat-2"
  echo "3" > "$STATE_DIR/retry-feat-2/retry-count"
  local rc=0
  MAX_RETRIES=3 policy_handle_cross_run_retry "retry-feat-2" || rc=$?
  [ "$rc" -eq 1 ]
}

# ── policy_handle_phase_reprompt ──────────────────────────────────────────────

@test "policy_handle_phase_reprompt: first call returns 0 and writes sentinel" {
  _init_feat "reprompt-feat-1"
  local wt="$TMPDIR_TEST/wt1"
  mkdir -p "$wt"
  local rc=0
  policy_handle_phase_reprompt "reprompt-feat-1" "$wt" "" || rc=$?
  [ "$rc" -eq 0 ]
  [ -f "$STATE_DIR/reprompt-feat-1/policy-reprompt-done" ]
}

@test "policy_handle_phase_reprompt: second call returns 1 (exhausted)" {
  _init_feat "reprompt-feat-2"
  local wt="$TMPDIR_TEST/wt2"
  mkdir -p "$wt"
  # Pre-write sentinel
  touch "$STATE_DIR/reprompt-feat-2/policy-reprompt-done"
  local rc=0
  policy_handle_phase_reprompt "reprompt-feat-2" "$wt" "" || rc=$?
  [ "$rc" -eq 1 ]
}

# ── policy_apply dispatch ─────────────────────────────────────────────────────

@test "policy_apply: transient/rate-limit ≤600s → return 0" {
  sleep() { :; }
  export -f sleep
  _init_feat "dispatch-feat-1"
  local wt="$TMPDIR_TEST/wt-d1"
  mkdir -p "$wt"
  local env; env=$(_make_envelope "transient" "rate-limit" "rl" 30)
  local rc=0
  policy_apply "dispatch-feat-1" "$env" "$wt" "" || rc=$?
  [ "$rc" -eq 0 ]
}

@test "policy_apply: transient/rate-limit >3600s → return 3" {
  _init_feat "dispatch-feat-2"
  local wt="$TMPDIR_TEST/wt-d2"
  mkdir -p "$wt"
  local env; env=$(_make_envelope "transient" "rate-limit" "rl" 7200)
  local rc=0
  policy_apply "dispatch-feat-2" "$env" "$wt" "" || rc=$?
  [ "$rc" -eq 3 ]
}

@test "policy_apply: fatal → return 1" {
  _init_feat "dispatch-feat-3"
  local wt="$TMPDIR_TEST/wt-d3"
  mkdir -p "$wt"
  local env; env=$(_make_envelope "fatal" "auth-failure")
  local rc=0
  policy_apply "dispatch-feat-3" "$env" "$wt" "" || rc=$?
  [ "$rc" -eq 1 ]
}

@test "policy_apply: phase → return 0 on first reprompt" {
  _init_feat "dispatch-feat-4"
  local wt="$TMPDIR_TEST/wt-d4"
  mkdir -p "$wt"
  local env; env=$(_make_envelope "phase" "phase-error")
  local rc=0
  policy_apply "dispatch-feat-4" "$env" "$wt" "" || rc=$?
  [ "$rc" -eq 0 ]
}

@test "policy_apply: unknown class treated as phase" {
  _init_feat "dispatch-feat-5"
  local wt="$TMPDIR_TEST/wt-d5"
  mkdir -p "$wt"
  local env; env=$(_make_envelope "unknown" "exit-99")
  local rc=0
  policy_apply "dispatch-feat-5" "$env" "$wt" "" || rc=$?
  [ "$rc" -eq 0 ]
}
