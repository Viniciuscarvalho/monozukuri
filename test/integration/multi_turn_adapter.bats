#!/usr/bin/env bats
# test/integration/multi_turn_adapter.bats — ADR-017: session-id/resume flag dispatch

setup() {
  REPO_ROOT="$(cd "$(dirname "$BATS_TEST_FILENAME")/../.." && pwd)"
  LIB_DIR="$REPO_ROOT/lib"
  FIXTURE_CTX="$REPO_ROOT/test/fixtures/contexts/simple.json"
  export LIB_DIR REPO_ROOT FIXTURE_CTX

  _MTA_DIR=$(mktemp -d /tmp/mt-adapter-test-XXXXX)
  export _MTA_DIR

  export STATE_DIR="$_MTA_DIR/state"
  mkdir -p "$STATE_DIR"

  # Stub claude binary that logs its argv to a file per invocation
  local stub_dir="$_MTA_DIR/bin"
  mkdir -p "$stub_dir"
  cat > "$stub_dir/claude" << 'EOSTUB'
#!/usr/bin/env bash
echo "$@" >> "${ARGV_LOG_FILE}"
echo "stub-claude: ok"
exit 0
EOSTUB
  chmod +x "$stub_dir/claude"
  export STUB_BIN="$stub_dir"
  export ARGV_LOG_FILE="$_MTA_DIR/argv.log"

  source "$LIB_DIR/agent/contract.sh"
  source "$LIB_DIR/prompt/render.sh"
  source "$LIB_DIR/agent/adapter-claude-code.sh"

  platform_claude() {
    local _timeout="$1"; shift
    PATH="$STUB_BIN:$PATH" claude "$@"
  }
  export -f platform_claude
}

teardown() {
  unset MONOZUKURI_PHASE CONTEXT_JSON MONOZUKURI_FEATURE_ID MONOZUKURI_WORKTREE \
        MONOZUKURI_LOG_FILE MONOZUKURI_MULTI_TURN_ACTIVE MONOZUKURI_MULTI_TURN \
        MONOZUKURI_SESSION_ID STATE_DIR ARGV_LOG_FILE 2>/dev/null || true
  rm -rf "${_MTA_DIR:-}" 2>/dev/null || true
}

@test "multi-turn turn 1 (prd): adapter uses --session-id flag" {
  local wt; wt=$(mktemp -d "$_MTA_DIR/XXXXX")
  mkdir -p "$wt"

  MONOZUKURI_FEATURE_ID="feat-mt-100" \
  MONOZUKURI_WORKTREE="$wt" \
  MONOZUKURI_LOG_FILE="$wt/run.log" \
  MONOZUKURI_PHASE="prd" \
  MONOZUKURI_MULTI_TURN_ACTIVE="1" \
  CONTEXT_JSON="$FIXTURE_CTX" \
    agent_run_phase

  grep -q -- "--session-id" "$ARGV_LOG_FILE"
}

@test "multi-turn turn 2 (techspec): adapter uses --resume with same UUID as turn 1" {
  local wt; wt=$(mktemp -d "$_MTA_DIR/XXXXX")
  mkdir -p "$wt"

  # Turn 1: PRD
  MONOZUKURI_FEATURE_ID="feat-mt-101" \
  MONOZUKURI_WORKTREE="$wt" \
  MONOZUKURI_LOG_FILE="$wt/run.log" \
  MONOZUKURI_PHASE="prd" \
  MONOZUKURI_MULTI_TURN_ACTIVE="1" \
  CONTEXT_JSON="$FIXTURE_CTX" \
    agent_run_phase

  local sid
  sid=$(jq -r '.session_id' "$STATE_DIR/feat-mt-101/session.json")

  # Simulate pipeline writing last_completed_turn after phase success
  jq --arg p "prd" '.last_completed_turn = $p' \
    "$STATE_DIR/feat-mt-101/session.json" > "$STATE_DIR/feat-mt-101/session.json.tmp"
  mv "$STATE_DIR/feat-mt-101/session.json.tmp" "$STATE_DIR/feat-mt-101/session.json"

  # Create fake session jsonl so resume path is triggered
  local cwd_slug
  cwd_slug=$(printf '%s' "$wt" | tr '/' '-')
  mkdir -p "${HOME}/.claude/projects/${cwd_slug}"
  touch "${HOME}/.claude/projects/${cwd_slug}/${sid}.jsonl"

  rm -f "$ARGV_LOG_FILE"

  # Turn 2: TechSpec
  MONOZUKURI_FEATURE_ID="feat-mt-101" \
  MONOZUKURI_WORKTREE="$wt" \
  MONOZUKURI_LOG_FILE="$wt/run.log" \
  MONOZUKURI_PHASE="techspec" \
  MONOZUKURI_MULTI_TURN_ACTIVE="1" \
  CONTEXT_JSON="$FIXTURE_CTX" \
    agent_run_phase

  # Cleanup fake jsonl
  rm -f "${HOME}/.claude/projects/${cwd_slug}/${sid}.jsonl"

  grep -q -- "--resume ${sid}" "$ARGV_LOG_FILE"
}

@test "multi-turn: session.json is created with correct fields after turn 1" {
  local wt; wt=$(mktemp -d "$_MTA_DIR/XXXXX")
  mkdir -p "$wt"

  MONOZUKURI_FEATURE_ID="feat-mt-102" \
  MONOZUKURI_WORKTREE="$wt" \
  MONOZUKURI_LOG_FILE="$wt/run.log" \
  MONOZUKURI_PHASE="prd" \
  MONOZUKURI_MULTI_TURN_ACTIVE="1" \
  CONTEXT_JSON="$FIXTURE_CTX" \
    agent_run_phase

  local sf="$STATE_DIR/feat-mt-102/session.json"
  [ -f "$sf" ]
  [ "$(jq -r '.agent' "$sf")" = "claude-code" ]
  [ -n "$(jq -r '.session_id' "$sf")" ]
  [ "$(jq -r '.cwd' "$sf")" = "$wt" ]
}
