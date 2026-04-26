#!/usr/bin/env bats
# test/unit/adapter_claude_code.bats — Phase-aware rendering contract for adapter-claude-code.sh

setup() {
  REPO_ROOT="$(cd "$(dirname "$BATS_TEST_FILENAME")/../.." && pwd)"
  LIB_DIR="$REPO_ROOT/lib"
  FIXTURE_CTX="$REPO_ROOT/test/fixtures/contexts/simple.json"
  MOCK_CLAUDE_DIR="$REPO_ROOT/test/fixtures/agents/mock-claude-code"
  export LIB_DIR FIXTURE_CTX MOCK_CLAUDE_DIR REPO_ROOT

  source "$LIB_DIR/agent/contract.sh"
  source "$LIB_DIR/prompt/render.sh"
  source "$LIB_DIR/agent/adapter-claude-code.sh"

  # Stub platform_claude: run the mock claude binary via PATH
  platform_claude() {
    local _timeout="$1"; shift
    PATH="$MOCK_CLAUDE_DIR:$PATH" claude "$@"
  }
  export -f platform_claude
}

teardown() {
  unset MONOZUKURI_PHASE CONTEXT_JSON MONOZUKURI_FEATURE_ID \
        MONOZUKURI_WORKTREE MONOZUKURI_LOG_FILE MONOZUKURI_ERROR_FILE 2>/dev/null || true
  rm -rf /tmp/cc-adapter-test-* 2>/dev/null || true
}

# ── phase-aware routing ───────────────────────────────────────────────────────

@test "agent_run_phase: with MONOZUKURI_PHASE=prd and CONTEXT_JSON, uses render path" {
  local wt; wt=$(mktemp -d /tmp/cc-adapter-test-XXXXX)
  local log_file="$wt/run.log"

  MONOZUKURI_FEATURE_ID="feat-001" \
  MONOZUKURI_WORKTREE="$wt" \
  MONOZUKURI_LOG_FILE="$log_file" \
  MONOZUKURI_PHASE="prd" \
  CONTEXT_JSON="$FIXTURE_CTX" \
    agent_run_phase

  # Render path creates an artifact file
  [ -f "$wt/tasks/prd-feat-001/prd.md" ]
}

@test "agent_run_phase: with MONOZUKURI_PHASE=techspec and CONTEXT_JSON, creates artifact" {
  local wt; wt=$(mktemp -d /tmp/cc-adapter-test-XXXXX)

  MONOZUKURI_FEATURE_ID="feat-001" \
  MONOZUKURI_WORKTREE="$wt" \
  MONOZUKURI_LOG_FILE="$wt/run.log" \
  MONOZUKURI_PHASE="techspec" \
  CONTEXT_JSON="$FIXTURE_CTX" \
    agent_run_phase

  [ -f "$wt/tasks/prd-feat-001/techspec.md" ]
}

@test "agent_run_phase: without MONOZUKURI_PHASE, uses legacy feature-marker path" {
  local wt; wt=$(mktemp -d /tmp/cc-adapter-test-XXXXX)
  local log_file="$wt/run.log"

  # Stub to detect which path was taken
  platform_claude() {
    printf '%s\n' "$@" > "$wt/invocation-args"
  }
  export -f platform_claude

  MONOZUKURI_FEATURE_ID="feat-001" \
  MONOZUKURI_WORKTREE="$wt" \
  MONOZUKURI_LOG_FILE="$log_file" \
    agent_run_phase || true

  # Legacy path passes --agent flag
  grep -q -- "--agent" "$wt/invocation-args" || \
    grep -q "feature-marker" "$wt/invocation-args"
}

@test "agent_run_phase: CONTEXT_JSON missing file falls back to legacy path" {
  local wt; wt=$(mktemp -d /tmp/cc-adapter-test-XXXXX)

  platform_claude() {
    printf '%s\n' "$@" > "$wt/invocation-args"
  }
  export -f platform_claude

  MONOZUKURI_FEATURE_ID="feat-001" \
  MONOZUKURI_WORKTREE="$wt" \
  MONOZUKURI_LOG_FILE="$wt/run.log" \
  MONOZUKURI_PHASE="prd" \
  CONTEXT_JSON="/nonexistent.json" \
    agent_run_phase || true

  grep -q -- "--agent" "$wt/invocation-args" || \
    grep -q "feature-marker" "$wt/invocation-args"
}

# ── _cc_run_phase_render internals ───────────────────────────────────────────

@test "_cc_run_phase_render: renders context tokens into the call" {
  local wt; wt=$(mktemp -d /tmp/cc-adapter-test-XXXXX)
  local log_file="$wt/run.log"

  # Stub to capture the rendered prompt
  platform_claude() {
    # Last argument after flags is -p <prompt>; write it to a capture file
    printf '%s\n' "$@" > "$wt/platform-args"
  }
  export -f platform_claude

  CONTEXT_JSON="$FIXTURE_CTX" \
    _cc_run_phase_render "prd" "feat-001" "$wt" "$log_file" || true

  # Rendered prompt passed to platform_claude contains the feature title
  grep -q "Add login" "$wt/platform-args" || \
    grep -q "feat-001" "$wt/platform-args"
}

@test "_cc_run_phase_render: artifact created on success" {
  local wt; wt=$(mktemp -d /tmp/cc-adapter-test-XXXXX)
  local log_file="$wt/run.log"

  CONTEXT_JSON="$FIXTURE_CTX" \
    _cc_run_phase_render "prd" "feat-001" "$wt" "$log_file"

  [ -f "$wt/tasks/prd-feat-001/prd.md" ]
}

@test "_cc_run_phase_render: returns non-zero when platform_claude fails" {
  local wt; wt=$(mktemp -d /tmp/cc-adapter-test-XXXXX)

  platform_claude() { return 1; }
  export -f platform_claude

  CONTEXT_JSON="$FIXTURE_CTX" \
    run _cc_run_phase_render "prd" "feat-001" "$wt" "$wt/run.log"
  [ "$status" -ne 0 ]
}
