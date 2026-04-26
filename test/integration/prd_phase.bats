#!/usr/bin/env bats
# test/integration/prd_phase.bats — End-to-end: context → render → adapter → artifact

setup() {
  REPO_ROOT="$(cd "$(dirname "$BATS_TEST_FILENAME")/../.." && pwd)"
  LIB_DIR="$REPO_ROOT/lib"
  MOCK_CLAUDE_DIR="$REPO_ROOT/test/fixtures/agents/mock-claude-code"
  FIXTURE_CTX="$REPO_ROOT/test/fixtures/contexts/simple.json"
  export REPO_ROOT LIB_DIR MOCK_CLAUDE_DIR FIXTURE_CTX

  source "$LIB_DIR/agent/contract.sh"
  source "$LIB_DIR/prompt/render.sh"
  source "$LIB_DIR/agent/adapter-claude-code.sh"

  # Stub platform_claude to run the mock claude binary
  platform_claude() {
    local _timeout="$1"; shift
    PATH="$MOCK_CLAUDE_DIR:$PATH" claude "$@"
  }
  export -f platform_claude

  WT=$(mktemp -d /tmp/prd-phase-test-XXXXX)
  LOG="$WT/run.log"
  export WT LOG
}

teardown() {
  rm -rf "$WT" 2>/dev/null || true
  unset MONOZUKURI_PHASE CONTEXT_JSON MONOZUKURI_FEATURE_ID \
        MONOZUKURI_WORKTREE MONOZUKURI_LOG_FILE 2>/dev/null || true
}

# ── prd phase end-to-end ─────────────────────────────────────────────────────

@test "prd phase: agent_run_phase with CONTEXT_JSON exits 0" {
  MONOZUKURI_FEATURE_ID="feat-001" \
  MONOZUKURI_WORKTREE="$WT" \
  MONOZUKURI_LOG_FILE="$LOG" \
  MONOZUKURI_PHASE="prd" \
  CONTEXT_JSON="$FIXTURE_CTX" \
    run agent_run_phase
  [ "$status" -eq 0 ]
}

@test "prd phase: artifact file created at tasks/prd-<id>/prd.md" {
  MONOZUKURI_FEATURE_ID="feat-001" \
  MONOZUKURI_WORKTREE="$WT" \
  MONOZUKURI_LOG_FILE="$LOG" \
  MONOZUKURI_PHASE="prd" \
  CONTEXT_JSON="$FIXTURE_CTX" \
    agent_run_phase

  [ -f "$WT/tasks/prd-feat-001/prd.md" ]
}

@test "prd phase: log file is written" {
  MONOZUKURI_FEATURE_ID="feat-001" \
  MONOZUKURI_WORKTREE="$WT" \
  MONOZUKURI_LOG_FILE="$LOG" \
  MONOZUKURI_PHASE="prd" \
  CONTEXT_JSON="$FIXTURE_CTX" \
    agent_run_phase

  [ -s "$LOG" ]
}

@test "prd phase: context tokens substituted in artifact" {
  MONOZUKURI_FEATURE_ID="feat-001" \
  MONOZUKURI_WORKTREE="$WT" \
  MONOZUKURI_LOG_FILE="$LOG" \
  MONOZUKURI_PHASE="prd" \
  CONTEXT_JSON="$FIXTURE_CTX" \
    agent_run_phase

  # The rendered prompt passed to mock-claude contains FEATURE_ID from fixture
  grep -q "feat-001" "$WT/tasks/prd-feat-001/prd.md"
}

# ── techspec phase end-to-end ────────────────────────────────────────────────

@test "techspec phase: artifact file created at tasks/prd-<id>/techspec.md" {
  MONOZUKURI_FEATURE_ID="feat-001" \
  MONOZUKURI_WORKTREE="$WT" \
  MONOZUKURI_LOG_FILE="$LOG" \
  MONOZUKURI_PHASE="techspec" \
  CONTEXT_JSON="$FIXTURE_CTX" \
    agent_run_phase

  [ -f "$WT/tasks/prd-feat-001/techspec.md" ]
}

# ── context-pack → render → adapter pipeline ─────────────────────────────────

@test "context-pack builds valid JSON consumed by render path" {
  source "$LIB_DIR/prompt/context-pack.sh"

  local ctx_file="$WT/ctx.json"
  FEATURE_TITLE="Context pack test" \
  FEATURE_DESCRIPTION="Test description" \
    context_pack_build "feat-cp-001" "$ctx_file"

  [ -f "$ctx_file" ]
  node -e "const d = JSON.parse(require('fs').readFileSync('$ctx_file','utf-8')); \
    if (!d.FEATURE_ID) throw new Error('missing FEATURE_ID'); \
    if (!Array.isArray(d.project_learnings)) throw new Error('missing project_learnings');"
}

@test "full pipeline: context-pack JSON feeds render, render feeds adapter" {
  source "$LIB_DIR/prompt/context-pack.sh"

  local ctx_file="$WT/ctx.json"
  FEATURE_TITLE="Full pipeline test" \
  FEATURE_DESCRIPTION="Full pipeline desc" \
    context_pack_build "feat-fp-001" "$ctx_file"

  MONOZUKURI_FEATURE_ID="feat-fp-001" \
  MONOZUKURI_WORKTREE="$WT" \
  MONOZUKURI_LOG_FILE="$LOG" \
  MONOZUKURI_PHASE="prd" \
  CONTEXT_JSON="$ctx_file" \
    agent_run_phase

  [ -f "$WT/tasks/prd-feat-fp-001/prd.md" ]
}
