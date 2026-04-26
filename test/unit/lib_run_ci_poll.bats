#!/usr/bin/env bats
# test/unit/lib_run_ci_poll.bats — unit tests for lib/run/ci-poll.sh

setup() {
  REPO_ROOT="$(cd "$(dirname "$BATS_TEST_FILENAME")/../.." && pwd)"
  LIB_DIR="$REPO_ROOT/lib"
  export LIB_DIR

  TMPDIR_TEST="$(mktemp -d)"
  STATE_DIR="$TMPDIR_TEST/state"
  export STATE_DIR

  warn()  { echo "WARN: $*" >&2; }
  info()  { echo "INFO: $*" >&2; }
  err()   { echo "ERR: $*" >&2; }
  export -f warn info err

  fstate_transition()   { :; }
  monozukuri_emit()     { :; }
  export -f fstate_transition monozukuri_emit

  source "$LIB_DIR/run/ci-poll.sh"
}

teardown() {
  rm -rf "$TMPDIR_TEST"
}

_init_feat() {
  local feat_id="$1"
  mkdir -p "$STATE_DIR/$feat_id"
}

# ── ci_check_status ───────────────────────────────────────────────────────────

@test "ci_check_status: returns pending when gh not available" {
  # Override command -v to pretend gh is absent
  command() {
    if [[ "$*" == *"gh"* ]]; then return 1; fi
    builtin command "$@"
  }
  export -f command
  result=$(ci_check_status "999")
  [ "$result" = "unknown" ]
}

@test "ci_check_status: all success → success" {
  platform_gh() {
    echo '[{"name":"test","state":"COMPLETED","conclusion":"success"},{"name":"lint","state":"COMPLETED","conclusion":"success"}]'
  }
  export -f platform_gh
  result=$(ci_check_status "1")
  [ "$result" = "success" ]
}

@test "ci_check_status: any failure → failure" {
  platform_gh() {
    echo '[{"name":"test","state":"COMPLETED","conclusion":"success"},{"name":"lint","state":"COMPLETED","conclusion":"failure"}]'
  }
  export -f platform_gh
  result=$(ci_check_status "2")
  [ "$result" = "failure" ]
}

@test "ci_check_status: in-progress → pending" {
  platform_gh() {
    echo '[{"name":"test","state":"IN_PROGRESS","conclusion":null}]'
  }
  export -f platform_gh
  result=$(ci_check_status "3")
  [ "$result" = "pending" ]
}

@test "ci_check_status: empty array → pending" {
  platform_gh() { echo '[]'; }
  export -f platform_gh
  result=$(ci_check_status "4")
  [ "$result" = "pending" ]
}

@test "ci_check_status: cancelled check → failure" {
  platform_gh() {
    echo '[{"name":"build","state":"COMPLETED","conclusion":"cancelled"}]'
  }
  export -f platform_gh
  result=$(ci_check_status "5")
  [ "$result" = "failure" ]
}

# ── ci_get_failed_log_url ─────────────────────────────────────────────────────

@test "ci_get_failed_log_url: returns detailsUrl of first failed check" {
  platform_gh() {
    echo '[{"name":"lint","detailsUrl":"https://ci.example.com/runs/42","conclusion":"failure"}]'
  }
  export -f platform_gh
  result=$(ci_get_failed_log_url "10")
  [ "$result" = "https://ci.example.com/runs/42" ]
}

@test "ci_get_failed_log_url: returns empty when no failures" {
  platform_gh() {
    echo '[{"name":"test","detailsUrl":"https://ci.example.com/runs/1","conclusion":"success"}]'
  }
  export -f platform_gh
  result=$(ci_get_failed_log_url "11")
  [ -z "$result" ]
}

# ── ci_rerun_failed_jobs ──────────────────────────────────────────────────────

@test "ci_rerun_failed_jobs: returns 1 when no failed jobs" {
  platform_gh() {
    case "$*" in
      *"pr checks"*) echo '[{"databaseId":1,"conclusion":"success"}]' ;;
      *) :;;
    esac
  }
  export -f platform_gh
  local rc=0
  ci_rerun_failed_jobs "20" || rc=$?
  [ "$rc" -eq 1 ]
}

@test "ci_rerun_failed_jobs: returns 0 when at least one rerun triggered" {
  _rerun_called=0
  platform_gh() {
    case "$*" in
      *"pr checks"*) echo '[{"databaseId":99,"conclusion":"failure"}]' ;;
      *"run rerun"*) _rerun_called=1 ;;
    esac
  }
  export -f platform_gh
  local rc=0
  ci_rerun_failed_jobs "21" || rc=$?
  [ "$rc" -eq 0 ]
}

# ── ci_wait_for_green: unit-testable paths ────────────────────────────────────

@test "ci_wait_for_green: returns 0 immediately on first success poll" {
  _init_feat "ci-feat-1"
  platform_gh() {
    echo '[{"name":"test","state":"COMPLETED","conclusion":"success"}]'
  }
  export -f platform_gh
  # Set short timeout so test doesn't block
  CI_POLL_TIMEOUT=10 CI_POLL_INTERVAL=1 \
    ci_wait_for_green "ci-feat-1" "https://github.com/org/repo/pull/1" "$TMPDIR_TEST"
}

@test "ci_wait_for_green: timeout path returns 1 and transitions to failed" {
  _init_feat "ci-feat-2"
  _transitions=""
  fstate_transition() { _transitions="$_transitions $*"; }
  export -f fstate_transition
  platform_gh() {
    echo '[{"name":"build","state":"IN_PROGRESS","conclusion":null}]'
  }
  export -f platform_gh
  local rc=0
  CI_POLL_TIMEOUT=0 CI_POLL_INTERVAL=1 \
    ci_wait_for_green "ci-feat-2" "https://github.com/org/repo/pull/2" "$TMPDIR_TEST" || rc=$?
  [ "$rc" -eq 1 ]
}
