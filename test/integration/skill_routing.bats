#!/usr/bin/env bats
# test/integration/skill_routing.bats — Integration tests for skill detection logic
#
# Sources lib/agent/skill-detect.sh and lib/setup/detect.sh directly.
# No actual agent CLI is invoked — all install paths are faked.

REPO_ROOT="$(cd "$(dirname "$BATS_TEST_FILENAME")/../.." && pwd)"
LIB_DIR="$REPO_ROOT/lib"

setup() {
  export REPO_ROOT LIB_DIR
  TMPDIR_TEST="$(mktemp -d)"
  export HOME="$TMPDIR_TEST/home"
  mkdir -p "$HOME"

  ORIG_DIR="$(pwd)"
  FAKE_WT="$TMPDIR_TEST/worktree"
  mkdir -p "$FAKE_WT"

  source "$LIB_DIR/agent/skill-detect.sh"
  source "$LIB_DIR/setup/detect.sh"
}

teardown() {
  cd "$ORIG_DIR"
  rm -rf "$TMPDIR_TEST"
}

# ── phase_to_skill mapping ────────────────────────────────────────────────────

@test "phase_to_skill: prd maps to mz-create-prd" {
  [ "$(phase_to_skill prd)" = "mz-create-prd" ]
}

@test "phase_to_skill: techspec maps to mz-create-techspec" {
  [ "$(phase_to_skill techspec)" = "mz-create-techspec" ]
}

@test "phase_to_skill: tasks maps to mz-create-tasks" {
  [ "$(phase_to_skill tasks)" = "mz-create-tasks" ]
}

@test "phase_to_skill: code maps to mz-execute-task" {
  [ "$(phase_to_skill code)" = "mz-execute-task" ]
}

@test "phase_to_skill: tests maps to mz-run-tests" {
  [ "$(phase_to_skill tests)" = "mz-run-tests" ]
}

@test "phase_to_skill: pr maps to mz-open-pr" {
  [ "$(phase_to_skill pr)" = "mz-open-pr" ]
}

@test "phase_to_skill: unknown returns empty string" {
  [ -z "$(phase_to_skill unknown)" ]
}

# ── skill_installed: not present ──────────────────────────────────────────────

@test "skill_installed: returns false when no install present" {
  local rc=0
  skill_installed "claude-code" "mz-create-prd" "$FAKE_WT" || rc=$?
  [ "$rc" -eq 1 ]
}

@test "skill_installed: returns false for missing global install" {
  local rc=0
  skill_installed "claude-code" "mz-create-prd" "$FAKE_WT" || rc=$?
  [ "$rc" -eq 1 ]
}

# ── skill_installed: with fake project-local install ─────────────────────────

@test "skill_installed: returns true with fake SKILL.md in project path" {
  mkdir -p "$FAKE_WT/.claude/skills/mz-create-prd"
  printf -- "---\nname: mz-create-prd\n---\n" \
    > "$FAKE_WT/.claude/skills/mz-create-prd/SKILL.md"
  skill_installed "claude-code" "mz-create-prd" "$FAKE_WT"
}

@test "skill_installed: returns false when SKILL.md is missing from install dir" {
  mkdir -p "$FAKE_WT/.claude/skills/mz-create-prd"
  # Directory exists but no SKILL.md
  local rc=0
  skill_installed "claude-code" "mz-create-prd" "$FAKE_WT" || rc=$?
  [ "$rc" -eq 1 ]
}

# ── skill_installed: with fake global install ─────────────────────────────────

@test "skill_installed: finds global install under HOME/.claude/skills" {
  mkdir -p "$HOME/.claude/skills/mz-create-prd"
  printf -- "---\nname: mz-create-prd\n---\n" \
    > "$HOME/.claude/skills/mz-create-prd/SKILL.md"
  skill_installed "claude-code" "mz-create-prd" "$FAKE_WT"
}

@test "skill_installed: project-local takes precedence over absent global" {
  mkdir -p "$FAKE_WT/.claude/skills/mz-create-prd"
  printf -- "---\nname: mz-create-prd\n---\n" \
    > "$FAKE_WT/.claude/skills/mz-create-prd/SKILL.md"
  # Global not present — project-local should satisfy
  skill_installed "claude-code" "mz-create-prd" "$FAKE_WT"
}

# ── universal agent routing ───────────────────────────────────────────────────

@test "skill_installed: finds cursor skill in .agents/skills" {
  mkdir -p "$FAKE_WT/.agents/skills/mz-create-prd"
  printf -- "---\nname: mz-create-prd\n---\n" \
    > "$FAKE_WT/.agents/skills/mz-create-prd/SKILL.md"
  skill_installed "cursor" "mz-create-prd" "$FAKE_WT"
}

@test "skill_installed: returns false for cursor when no install" {
  local rc=0
  skill_installed "cursor" "mz-create-prd" "$FAKE_WT" || rc=$?
  [ "$rc" -eq 1 ]
}
