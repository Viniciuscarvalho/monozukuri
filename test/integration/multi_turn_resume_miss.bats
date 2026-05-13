#!/usr/bin/env bats
# test/integration/multi_turn_resume_miss.bats — ADR-017: session jsonl miss → cold fallback

setup() {
  REPO_ROOT="$(cd "$(dirname "$BATS_TEST_FILENAME")/../.." && pwd)"
  LIB_DIR="$REPO_ROOT/lib"
  FIXTURE_CTX="$REPO_ROOT/test/fixtures/contexts/simple.json"
  export LIB_DIR REPO_ROOT FIXTURE_CTX

  _MTRM_DIR=$(mktemp -d /tmp/mt-resume-miss-test-XXXXX)
  export _MTRM_DIR

  export STATE_DIR="$_MTRM_DIR/state"
  mkdir -p "$STATE_DIR"
  export EMIT_LOG="$_MTRM_DIR/emit.log"

  # Stub claude binary that logs argv
  local stub_dir="$_MTRM_DIR/bin"
  mkdir -p "$stub_dir"
  cat > "$stub_dir/claude" << 'EOSTUB'
#!/usr/bin/env bash
echo "$@" >> "${ARGV_LOG_FILE}"
echo "stub-claude: ok"
exit 0
EOSTUB
  chmod +x "$stub_dir/claude"
  export STUB_BIN="$stub_dir"
  export ARGV_LOG_FILE="$_MTRM_DIR/argv.log"

  source "$LIB_DIR/agent/contract.sh"
  source "$LIB_DIR/prompt/render.sh"
  source "$LIB_DIR/agent/adapter-claude-code.sh"

  platform_claude() {
    local _timeout="$1"; shift
    PATH="$STUB_BIN:$PATH" claude "$@"
  }
  export -f platform_claude

  # Override monozukuri_emit to capture events
  monozukuri_emit() {
    printf '%s\n' "$*" >> "$EMIT_LOG"
  }
  export -f monozukuri_emit
}

teardown() {
  unset MONOZUKURI_PHASE CONTEXT_JSON MONOZUKURI_FEATURE_ID MONOZUKURI_WORKTREE \
        MONOZUKURI_LOG_FILE MONOZUKURI_MULTI_TURN_ACTIVE STATE_DIR \
        ARGV_LOG_FILE EMIT_LOG 2>/dev/null || true
  rm -rf "${_MTRM_DIR:-}" 2>/dev/null || true
}

@test "resume miss: emits session.resume_missed event when jsonl absent" {
  local wt; wt=$(mktemp -d "$_MTRM_DIR/XXXXX")
  mkdir -p "$wt"

  # Pre-create session.json with a non-existent UUID (no corresponding jsonl)
  local fake_uuid="00000000-dead-beef-dead-000000000001"
  mkdir -p "$STATE_DIR/feat-rm-001"
  printf '{"session_id":"%s","cwd":"%s","created_at":"2026-05-13T00:00:00Z","last_completed_turn":"prd","agent":"claude-code"}\n' \
    "$fake_uuid" "$wt" > "$STATE_DIR/feat-rm-001/session.json"

  MONOZUKURI_FEATURE_ID="feat-rm-001" \
  MONOZUKURI_WORKTREE="$wt" \
  MONOZUKURI_LOG_FILE="$wt/run.log" \
  MONOZUKURI_PHASE="techspec" \
  MONOZUKURI_MULTI_TURN_ACTIVE="1" \
  CONTEXT_JSON="$FIXTURE_CTX" \
    agent_run_phase

  grep -q "session.resume_missed" "$EMIT_LOG"
}

@test "resume miss: adapter uses --session-id (not --resume) for fallback run" {
  local wt; wt=$(mktemp -d "$_MTRM_DIR/XXXXX")
  mkdir -p "$wt"

  local fake_uuid="00000000-dead-beef-dead-000000000002"
  mkdir -p "$STATE_DIR/feat-rm-002"
  printf '{"session_id":"%s","cwd":"%s","created_at":"2026-05-13T00:00:00Z","last_completed_turn":"prd","agent":"claude-code"}\n' \
    "$fake_uuid" "$wt" > "$STATE_DIR/feat-rm-002/session.json"

  MONOZUKURI_FEATURE_ID="feat-rm-002" \
  MONOZUKURI_WORKTREE="$wt" \
  MONOZUKURI_LOG_FILE="$wt/run.log" \
  MONOZUKURI_PHASE="techspec" \
  MONOZUKURI_MULTI_TURN_ACTIVE="1" \
  CONTEXT_JSON="$FIXTURE_CTX" \
    agent_run_phase

  # Must NOT use --resume (the stale UUID is missing its jsonl)
  ! grep -q -- "--resume ${fake_uuid}" "$ARGV_LOG_FILE"
  # Must use --session-id for the fallback new session
  grep -q -- "--session-id" "$ARGV_LOG_FILE"
}

@test "resume miss: feature phase still completes (exit 0) after fallback" {
  local wt; wt=$(mktemp -d "$_MTRM_DIR/XXXXX")
  mkdir -p "$wt"

  local fake_uuid="00000000-dead-beef-dead-000000000003"
  mkdir -p "$STATE_DIR/feat-rm-003"
  printf '{"session_id":"%s","cwd":"%s","created_at":"2026-05-13T00:00:00Z","last_completed_turn":"prd","agent":"claude-code"}\n' \
    "$fake_uuid" "$wt" > "$STATE_DIR/feat-rm-003/session.json"

  local rc=0
  MONOZUKURI_FEATURE_ID="feat-rm-003" \
  MONOZUKURI_WORKTREE="$wt" \
  MONOZUKURI_LOG_FILE="$wt/run.log" \
  MONOZUKURI_PHASE="techspec" \
  MONOZUKURI_MULTI_TURN_ACTIVE="1" \
  CONTEXT_JSON="$FIXTURE_CTX" \
    agent_run_phase || rc=$?

  [ "$rc" -eq 0 ]
}
