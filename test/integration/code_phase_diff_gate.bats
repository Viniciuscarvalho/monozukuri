#!/usr/bin/env bats
# test/integration/code_phase_diff_gate.bats
#
# Verifies that _pipe_verify_code_diff (the worktree-diff gate) correctly
# detects no-op code phases and returns EXIT_AGENT_BLOCKED (21).

REPO_ROOT="$(cd "$(dirname "$BATS_TEST_FILENAME")/../.." && pwd)"

setup() {
  export REPO_ROOT
  export BASE_BRANCH="main"

  # Stub output helpers pipeline.sh depends on
  warn() { echo "WARN: $*" >&2; }
  info() { :; }
  export -f warn info

  # Source only the portion of pipeline.sh we're testing.
  # pipeline.sh has no top-level code, so sourcing it only defines functions.
  # shellcheck source=../../lib/run/pipeline.sh
  source "$REPO_ROOT/lib/run/pipeline.sh"

  # Scratch git worktree for each test
  TMPWT="$(mktemp -d)"
  git -C "$TMPWT" init -q
  git -C "$TMPWT" config user.email "test@example.com"
  git -C "$TMPWT" config user.name "Test"

  # Create an initial commit so merge-base has something to reference
  touch "$TMPWT/.keep"
  git -C "$TMPWT" add .keep
  git -C "$TMPWT" commit -q -m "init"
  git -C "$TMPWT" branch -M main
  export TMPWT
}

teardown() {
  rm -rf "$TMPWT"
}

# ── 1. Clean worktree returns 21 ──────────────────────────────────────────────

@test "diff-gate: clean worktree returns EXIT_AGENT_BLOCKED (21)" {
  run _pipe_verify_code_diff "feat-001" "$TMPWT"
  [ "$status" -eq 21 ]
}

@test "diff-gate: clean worktree sets MONOZUKURI_BLOCKER_REASON=no-artifact-produced" {
  _pipe_verify_code_diff "feat-001" "$TMPWT" || true
  [ "${MONOZUKURI_BLOCKER_REASON:-}" = "no-artifact-produced" ]
}

@test "diff-gate: clean worktree emits a warning" {
  run _pipe_verify_code_diff "feat-001" "$TMPWT"
  [[ "$output" =~ "worktree is unchanged" ]]
}

# ── 2. Dirty worktree (committed change on feature branch) returns 0 ──────────

@test "diff-gate: committed file change on feature branch returns 0" {
  # Simulate a real worktree: feature branch diverges from main, adds a commit.
  # merge-base HEAD main → initial commit; diff --name-only shows src.sh.
  git -C "$TMPWT" checkout -q -b "feat/001"
  echo "impl" > "$TMPWT/src.sh"
  git -C "$TMPWT" add src.sh
  git -C "$TMPWT" commit -q -m "feat: add src"

  run _pipe_verify_code_diff "feat-001" "$TMPWT"
  [ "$status" -eq 0 ]
}

# ── 3. Untracked file (new file not yet committed) returns 0 ──────────────────

@test "diff-gate: untracked new file returns 0" {
  echo "impl" > "$TMPWT/newfile.sh"

  run _pipe_verify_code_diff "feat-001" "$TMPWT"
  [ "$status" -eq 0 ]
}

# ── 4. .monozukuri/ internal state does NOT count as work ────────────────────

@test "diff-gate: untracked .monozukuri/ file alone returns 21" {
  mkdir -p "$TMPWT/.monozukuri"
  echo "state" > "$TMPWT/.monozukuri/state.json"

  run _pipe_verify_code_diff "feat-001" "$TMPWT"
  [ "$status" -eq 21 ]
}
