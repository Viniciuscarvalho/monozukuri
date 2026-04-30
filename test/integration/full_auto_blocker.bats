#!/usr/bin/env bats
# test/integration/full_auto_blocker.bats
#
# Verifies that a full_auto batch does not hang when an agent emits an
# interactive-blocking pattern. The blocked feature must be marked
# failed/blocked and the remaining features must complete normally.

REPO_ROOT="$(cd "$(dirname "$BATS_TEST_FILENAME")/../.." && pwd)"
LIB_DIR="$REPO_ROOT/lib"

setup() {
  export REPO_ROOT LIB_DIR

  TMPDIR_TEST="$(mktemp -d)"
  export TMPDIR_TEST

  source "$LIB_DIR/agent/contract.sh"
  source "$LIB_DIR/agent/error.sh"

  # Stub helpers that pipeline internals call and that are irrelevant here
  monozukuri_emit() { :; }
  export -f monozukuri_emit

  info()  { :; }
  warn()  { :; }
  err()   { :; }
  export -f info warn err

  # Two feature worktrees
  WT1="$TMPDIR_TEST/wt1"
  WT2="$TMPDIR_TEST/wt2"
  mkdir -p "$WT1" "$WT2"

  LOG1="$WT1/run.log"
  LOG2="$WT2/run.log"
  ERR1="$TMPDIR_TEST/err1.json"
  ERR2="$TMPDIR_TEST/err2.json"

  export WT1 WT2 LOG1 LOG2 ERR1 ERR2
}

teardown() {
  rm -rf "$TMPDIR_TEST"
}

# _run_feature_stub simulates the blocker-detection portion of agent_run_phase
# without spinning up the full pipeline. It writes a canned log, then calls
# agent_scan_for_blocker exactly as the real adapter does.
#
# Returns 21 (EXIT_AGENT_BLOCKED) when the log contains a blocker pattern,
# 0 otherwise.
_run_feature_stub() {
  local log_file="$1"
  local err_file="$2"
  local emit_blocker="${3:-0}"

  if [ "$emit_blocker" = "1" ]; then
    printf 'Starting feature implementation\n' >> "$log_file"
    printf 'Blocker — Need Your Input: target branch is ambiguous\n' >> "$log_file"
    printf 'Waiting for human response...\n' >> "$log_file"
  else
    printf 'Starting feature implementation\n' >> "$log_file"
    printf 'Implementing feature...\n' >> "$log_file"
    printf 'Done.\n' >> "$log_file"
  fi

  local exit_code=0
  agent_scan_for_blocker "$log_file" "$err_file" || exit_code=21
  return "$exit_code"
}

# ── test 1: blocked feature yields EXIT_AGENT_BLOCKED ─────────────────────────

@test "full_auto: blocked feature exits with code 21 (EXIT_AGENT_BLOCKED)" {
  export MONOZUKURI_INTERACTIVE=0
  export MONOZUKURI_AUTONOMY=full_auto

  run _run_feature_stub "$LOG1" "$ERR1" 1
  [ "$status" -eq 21 ]
}

# ── test 2: blocked feature writes class:"human" envelope ────────────────────

@test "full_auto: blocked feature writes class:human error envelope" {
  export MONOZUKURI_INTERACTIVE=0
  export MONOZUKURI_AUTONOMY=full_auto

  _run_feature_stub "$LOG1" "$ERR1" 1 || true

  [ -f "$ERR1" ]
  node -e "
    const d = JSON.parse(require('fs').readFileSync('$ERR1', 'utf-8'));
    if (d.class !== 'human') process.exit(1);
    if (d.code !== 'agent-blocker') process.exit(1);
  "
}

# ── test 3: non-blocking feature exits 0 ──────────────────────────────────────

@test "full_auto: non-blocking feature exits 0 (batch continues)" {
  export MONOZUKURI_INTERACTIVE=0
  export MONOZUKURI_AUTONOMY=full_auto

  run _run_feature_stub "$LOG2" "$ERR2" 0
  [ "$status" -eq 0 ]
}

# ── test 4: 2-feature batch — offender blocked, second completes ──────────────

@test "full_auto: 2-feature batch — feat-1 blocked, feat-2 completes" {
  export MONOZUKURI_INTERACTIVE=0
  export MONOZUKURI_AUTONOMY=full_auto

  local feat1_exit=0
  local feat2_exit=0

  _run_feature_stub "$LOG1" "$ERR1" 1 || feat1_exit=$?
  _run_feature_stub "$LOG2" "$ERR2" 0 || feat2_exit=$?

  [ "$feat1_exit" -eq 21 ]
  [ "$feat2_exit" -eq 0 ]
}

# ── test 5: blocked feature does not propagate to subsequent feature ───────────

@test "full_auto: error envelope for feat-1 does not affect feat-2 run" {
  export MONOZUKURI_INTERACTIVE=0
  export MONOZUKURI_AUTONOMY=full_auto

  _run_feature_stub "$LOG1" "$ERR1" 1 || true
  run _run_feature_stub "$LOG2" "$ERR2" 0
  [ "$status" -eq 0 ]
  [ ! -f "$ERR2" ]
}

# ── test 6: batch completes within timeout (does not hang) ────────────────────

@test "full_auto: 2-feature batch completes without hanging" {
  export MONOZUKURI_INTERACTIVE=0
  export MONOZUKURI_AUTONOMY=full_auto

  local start end elapsed
  start=$(date +%s)

  _run_feature_stub "$LOG1" "$ERR1" 1 || true
  _run_feature_stub "$LOG2" "$ERR2" 0 || true

  end=$(date +%s)
  elapsed=$(( end - start ))

  # Both stubs are synchronous — batch must complete well under 5 seconds
  [ "$elapsed" -lt 5 ]
}
