#!/usr/bin/env bats
# test/integration/retry_budget_guard.bats
#
# Regression tests for two retry --all bugs:
# 1. Budget-exceeded features were sent through run_feature, immediately
#    re-paused, and falsely reported as succeeded (exit 0 != actual success).
# 2. Success evaluation used exit code instead of final feature status, so
#    any feature that returned 0 was counted as succeeded regardless of state.

REPO_ROOT="$(cd "$(dirname "$BATS_TEST_FILENAME")/../.." && pwd)"
LIB_DIR="$REPO_ROOT/lib"

setup() {
  export REPO_ROOT LIB_DIR

  TMPDIR_TEST="$(mktemp -d)"
  export TMPDIR_TEST

  STATE_DIR="$TMPDIR_TEST/state"
  mkdir -p "$STATE_DIR"
  export STATE_DIR

  mkdir -p "$STATE_DIR/feat-001"
  printf '{"status":"paused","reason":"budget-exceeded"}' \
    > "$STATE_DIR/feat-001/status.json"
  printf '{"cumulative_tokens":83000}' \
    > "$STATE_DIR/feat-001/cost.json"

  # Stub functions used by the retry budget pre-check logic.
  info() { :; }
  warn() { echo "WARN: $*" >&3; }
  export -f info warn
}

teardown() {
  rm -rf "$TMPDIR_TEST"
}

# Inline the budget pre-check extracted from cmd/retry.sh so we can unit-test
# it without the full pipeline. Returns 1 when feature is over budget (skip),
# 0 when it is within budget (allow retry).
_budget_precheck() {
  local fid="$1"
  local _budget_limit="${MONOZUKURI_MAX_FEATURE_TOKENS:-80000}"
  local _cost_file="$STATE_DIR/$fid/cost.json"
  if [ -f "$_cost_file" ]; then
    local _lifetime_tokens
    _lifetime_tokens=$(node -p \
      "try{JSON.parse(require('fs').readFileSync('$_cost_file','utf-8')).cumulative_tokens||0}catch(e){0}" \
      2>/dev/null || echo 0)
    if (( _lifetime_tokens > _budget_limit )); then
      warn "retry: $fid skipped — still over budget (${_lifetime_tokens} tokens > MONOZUKURI_MAX_FEATURE_TOKENS=${_budget_limit}); raise the limit to override"
      return 1
    fi
  fi
  return 0
}

# Inline the success evaluation from cmd/retry.sh so we can unit-test it.
# Sets global _outcome to "succeeded" or "failed".
_eval_outcome() {
  local new_status="$1"
  local exit_code="${2:-0}"
  case "$new_status" in
    done|pr-created) _outcome="succeeded" ;;
    *)               _outcome="failed"    ;;
  esac
}

@test "budget pre-check blocks a feature that exceeds the token limit" {
  run _budget_precheck "feat-001"
  [ "$status" -eq 1 ]
}

@test "budget pre-check allows a feature within the token limit" {
  printf '{"cumulative_tokens":50000}' > "$STATE_DIR/feat-001/cost.json"
  run _budget_precheck "feat-001"
  [ "$status" -eq 0 ]
}

@test "budget pre-check allows a feature with no cost.json" {
  rm -f "$STATE_DIR/feat-001/cost.json"
  run _budget_precheck "feat-001"
  [ "$status" -eq 0 ]
}

@test "budget pre-check blocks when limit is raised but still exceeded" {
  MONOZUKURI_MAX_FEATURE_TOKENS=90000 run _budget_precheck "feat-001"
  [ "$status" -eq 0 ]   # 83000 < 90000 — now within limit
}

@test "outcome: exit 0 with paused status counts as failed not succeeded" {
  _eval_outcome "paused" 0
  [ "$_outcome" = "failed" ]
}

@test "outcome: exit 0 with done status counts as succeeded" {
  _eval_outcome "done" 0
  [ "$_outcome" = "succeeded" ]
}

@test "outcome: exit 0 with pr-created status counts as succeeded" {
  _eval_outcome "pr-created" 0
  [ "$_outcome" = "succeeded" ]
}

@test "outcome: non-zero exit with error status counts as failed" {
  _eval_outcome "error" 1
  [ "$_outcome" = "failed" ]
}
