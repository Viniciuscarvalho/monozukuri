#!/usr/bin/env bats
# test/conformance/agent_run_phase_fix_retry.bats
#
# Conformance suite for the fix-retry phase (Part B: Phase 3 Ralph Loop
# adapter parity). Verifies that every adapter handles MONOZUKURI_PHASE=fix-retry
# and writes an error envelope when it fails, without calling platform_claude
# or any real agent binary.
#
# Each test stubs the adapter's CLI binary to either exit 0 (success) or
# exit 1 (failure) and asserts the adapter's response.

setup() {
  REPO_ROOT="$(cd "$(dirname "$BATS_TEST_FILENAME")/../.." && pwd)"
  LIB_DIR="$REPO_ROOT/lib"
  export LIB_DIR REPO_ROOT

  STUB_DIR="$(mktemp -d)"
  WORKTREE="$(mktemp -d)"
  ERR_FILE="$(mktemp)"
  LOG_FILE="$(mktemp)"

  export MONOZUKURI_FEATURE_ID="conf-fix-retry"
  export MONOZUKURI_WORKTREE="$WORKTREE"
  export MONOZUKURI_PHASE="fix-retry"
  export MONOZUKURI_FIX_CONTEXT="Fix the failing assertion on line 42."
  export MONOZUKURI_AUTONOMY="full_auto"
  export MONOZUKURI_LOG_FILE="$LOG_FILE"
  export MONOZUKURI_ERROR_FILE="$ERR_FILE"
  export SKILL_TIMEOUT_SECONDS="30"
}

teardown() {
  rm -rf "$STUB_DIR" "$WORKTREE" "$ERR_FILE" "$LOG_FILE"
}

# ── helpers ───────────────────────────────────────────────────────────────────

# Creates a stub binary at STUB_DIR/<name> that exits with the given code.
_stub_binary() {
  local name="$1" exit_code="$2"
  printf '#!/bin/bash\necho "mock-%s running"\nexit %d\n' "$name" "$exit_code" \
    > "$STUB_DIR/$name"
  chmod +x "$STUB_DIR/$name"
}

# ── claude-code ───────────────────────────────────────────────────────────────

@test "claude-code: fix-retry succeeds when platform_claude exits 0" {
  source "$LIB_DIR/agent/contract.sh"
  source "$LIB_DIR/agent/adapter-claude-code.sh"

  platform_claude() { shift; cat; return 0; }
  export -f platform_claude
  op_timeout() { shift; "$@"; }
  export -f op_timeout

  run agent_run_phase
  [ "$status" -eq 0 ]
}

@test "claude-code: fix-retry exits non-zero and writes error envelope when platform_claude fails" {
  source "$LIB_DIR/agent/contract.sh"
  source "$LIB_DIR/agent/adapter-claude-code.sh"

  platform_claude() { shift; return 1; }
  export -f platform_claude
  op_timeout() { shift; "$@"; }
  export -f op_timeout

  run agent_run_phase
  [ "$status" -ne 0 ]
  [ -s "$ERR_FILE" ]
  node -e "
    const d = JSON.parse(require('fs').readFileSync('$ERR_FILE','utf-8'));
    if (!d.class) throw new Error('missing class field');
  "
}

# ── codex ─────────────────────────────────────────────────────────────────────

@test "codex: fix-retry succeeds with stub codex binary" {
  _stub_binary "codex" 0
  PATH="$STUB_DIR:/usr/bin:/bin" run /bin/bash -c "
    source '$LIB_DIR/agent/contract.sh'
    source '$LIB_DIR/agent/adapter-codex.sh'
    export MONOZUKURI_FEATURE_ID='$MONOZUKURI_FEATURE_ID'
    export MONOZUKURI_WORKTREE='$WORKTREE'
    export MONOZUKURI_PHASE='fix-retry'
    export MONOZUKURI_FIX_CONTEXT='Fix the failing test.'
    export MONOZUKURI_AUTONOMY='full_auto'
    export MONOZUKURI_LOG_FILE='$LOG_FILE'
    agent_run_phase 2>&1
  "
  [ "$status" -eq 0 ]
}

@test "codex: fix-retry exits non-zero when codex fails" {
  _stub_binary "codex" 1
  PATH="$STUB_DIR:/usr/bin:/bin" run /bin/bash -c "
    source '$LIB_DIR/agent/contract.sh'
    source '$LIB_DIR/agent/adapter-codex.sh'
    export MONOZUKURI_FEATURE_ID='$MONOZUKURI_FEATURE_ID'
    export MONOZUKURI_WORKTREE='$WORKTREE'
    export MONOZUKURI_PHASE='fix-retry'
    export MONOZUKURI_FIX_CONTEXT='Fix the failing test.'
    export MONOZUKURI_AUTONOMY='full_auto'
    export MONOZUKURI_LOG_FILE='$LOG_FILE'
    agent_run_phase 2>&1
  "
  [ "$status" -ne 0 ]
}

# ── gemini ────────────────────────────────────────────────────────────────────

@test "gemini: fix-retry succeeds with stub gemini binary" {
  _stub_binary "gemini" 0
  PATH="$STUB_DIR:/usr/bin:/bin" run /bin/bash -c "
    source '$LIB_DIR/agent/contract.sh'
    source '$LIB_DIR/agent/adapter-gemini.sh'
    export MONOZUKURI_FEATURE_ID='$MONOZUKURI_FEATURE_ID'
    export MONOZUKURI_WORKTREE='$WORKTREE'
    export MONOZUKURI_PHASE='fix-retry'
    export MONOZUKURI_FIX_CONTEXT='Fix the failing test.'
    export MONOZUKURI_AUTONOMY='full_auto'
    export MONOZUKURI_LOG_FILE='$LOG_FILE'
    agent_run_phase 2>&1
  "
  [ "$status" -eq 0 ]
}

@test "gemini: fix-retry exits non-zero when gemini fails" {
  _stub_binary "gemini" 1
  PATH="$STUB_DIR:/usr/bin:/bin" run /bin/bash -c "
    source '$LIB_DIR/agent/contract.sh'
    source '$LIB_DIR/agent/adapter-gemini.sh'
    export MONOZUKURI_FEATURE_ID='$MONOZUKURI_FEATURE_ID'
    export MONOZUKURI_WORKTREE='$WORKTREE'
    export MONOZUKURI_PHASE='fix-retry'
    export MONOZUKURI_FIX_CONTEXT='Fix the failing test.'
    export MONOZUKURI_AUTONOMY='full_auto'
    export MONOZUKURI_LOG_FILE='$LOG_FILE'
    agent_run_phase 2>&1
  "
  [ "$status" -ne 0 ]
}

# ── kiro ──────────────────────────────────────────────────────────────────────

@test "kiro: fix-retry succeeds with stub kiro binary" {
  _stub_binary "kiro" 0
  PATH="$STUB_DIR:/usr/bin:/bin" run /bin/bash -c "
    source '$LIB_DIR/agent/contract.sh'
    source '$LIB_DIR/agent/adapter-kiro.sh'
    export MONOZUKURI_FEATURE_ID='$MONOZUKURI_FEATURE_ID'
    export MONOZUKURI_WORKTREE='$WORKTREE'
    export MONOZUKURI_PHASE='fix-retry'
    export MONOZUKURI_FIX_CONTEXT='Fix the failing test.'
    export MONOZUKURI_AUTONOMY='full_auto'
    export MONOZUKURI_LOG_FILE='$LOG_FILE'
    agent_run_phase 2>&1
  "
  [ "$status" -eq 0 ]
}

@test "kiro: fix-retry exits non-zero when kiro fails" {
  _stub_binary "kiro" 1
  PATH="$STUB_DIR:/usr/bin:/bin" run /bin/bash -c "
    source '$LIB_DIR/agent/contract.sh'
    source '$LIB_DIR/agent/adapter-kiro.sh'
    export MONOZUKURI_FEATURE_ID='$MONOZUKURI_FEATURE_ID'
    export MONOZUKURI_WORKTREE='$WORKTREE'
    export MONOZUKURI_PHASE='fix-retry'
    export MONOZUKURI_FIX_CONTEXT='Fix the failing test.'
    export MONOZUKURI_AUTONOMY='full_auto'
    export MONOZUKURI_LOG_FILE='$LOG_FILE'
    agent_run_phase 2>&1
  "
  [ "$status" -ne 0 ]
}

# ── aider ─────────────────────────────────────────────────────────────────────

@test "aider: fix-retry succeeds when op_timeout exits 0" {
  source "$LIB_DIR/agent/contract.sh"
  source "$LIB_DIR/agent/adapter-aider.sh"

  op_timeout() { shift; echo "mock aider ok"; return 0; }
  export -f op_timeout

  run agent_run_phase
  [ "$status" -eq 0 ]
}

@test "aider: fix-retry exits non-zero and writes error envelope when op_timeout fails" {
  source "$LIB_DIR/agent/contract.sh"
  source "$LIB_DIR/agent/adapter-aider.sh"

  op_timeout() { shift; return 1; }
  export -f op_timeout

  run agent_run_phase
  [ "$status" -ne 0 ]
  [ -s "$ERR_FILE" ]
  node -e "
    const d = JSON.parse(require('fs').readFileSync('$ERR_FILE','utf-8'));
    if (!d.class) throw new Error('missing class field');
  "
}
