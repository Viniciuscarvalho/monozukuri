#!/usr/bin/env bats
# test/unit/adapter_skill_detect.bats — unit tests for lib/agent/skill-detect.sh

setup() {
  REPO_ROOT="$(cd "$(dirname "$BATS_TEST_FILENAME")/../.." && pwd)"
  LIB_DIR="$REPO_ROOT/lib"
  export LIB_DIR REPO_ROOT

  source "$LIB_DIR/agent/skill-detect.sh"

  TMPDIR_TEST="$(mktemp -d)"
  export HOME="$TMPDIR_TEST/home"
  mkdir -p "$HOME"

  ORIG_DIR="$(pwd)"
  mkdir -p "$TMPDIR_TEST/project"
  cd "$TMPDIR_TEST/project"
}

teardown() {
  cd "$ORIG_DIR"
  rm -rf "$TMPDIR_TEST"
}

# ── phase_to_skill ────────────────────────────────────────────────────────────

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

@test "phase_to_skill: unknown phase returns empty string" {
  [ -z "$(phase_to_skill unknown-phase)" ]
}

@test "phase_to_skill: empty phase returns empty string" {
  [ -z "$(phase_to_skill "")" ]
}

# ── skill_installed: not present ──────────────────────────────────────────────

@test "skill_installed: returns 1 when skill not installed" {
  local rc=0
  skill_installed "claude-code" "mz-create-prd" "$TMPDIR_TEST/project" || rc=$?
  [ "$rc" -eq 1 ]
}

@test "skill_installed: returns 1 for unknown agent" {
  local rc=0
  skill_installed "unknown-agent" "mz-create-prd" "$TMPDIR_TEST/project" || rc=$?
  [ "$rc" -eq 1 ]
}

# ── skill_installed: claude-code project-local ────────────────────────────────

@test "skill_installed: finds claude-code skill in project .claude/skills" {
  mkdir -p "$TMPDIR_TEST/project/.claude/skills/mz-create-prd"
  printf -- "---\nname: mz-create-prd\n---\n" \
    > "$TMPDIR_TEST/project/.claude/skills/mz-create-prd/SKILL.md"
  skill_installed "claude-code" "mz-create-prd" "$TMPDIR_TEST/project"
}

@test "skill_installed: returns 1 when dir exists but SKILL.md missing" {
  mkdir -p "$TMPDIR_TEST/project/.claude/skills/mz-create-prd"
  local rc=0
  skill_installed "claude-code" "mz-create-prd" "$TMPDIR_TEST/project" || rc=$?
  [ "$rc" -eq 1 ]
}

# ── skill_installed: claude-code global ──────────────────────────────────────

@test "skill_installed: finds claude-code skill in ~/.claude/skills" {
  mkdir -p "$HOME/.claude/skills/mz-create-prd"
  printf -- "---\nname: mz-create-prd\n---\n" \
    > "$HOME/.claude/skills/mz-create-prd/SKILL.md"
  skill_installed "claude-code" "mz-create-prd" "$TMPDIR_TEST/project"
}

@test "skill_installed: respects CLAUDE_CONFIG_DIR for global path" {
  local custom="$TMPDIR_TEST/custom-claude"
  mkdir -p "$custom/skills/mz-create-prd"
  printf -- "---\nname: mz-create-prd\n---\n" \
    > "$custom/skills/mz-create-prd/SKILL.md"
  CLAUDE_CONFIG_DIR="$custom" skill_installed "claude-code" "mz-create-prd" "$TMPDIR_TEST/project"
}

@test "skill_installed: project-local takes priority over missing global" {
  mkdir -p "$TMPDIR_TEST/project/.claude/skills/mz-create-prd"
  printf -- "---\nname: mz-create-prd\n---\n" \
    > "$TMPDIR_TEST/project/.claude/skills/mz-create-prd/SKILL.md"
  skill_installed "claude-code" "mz-create-prd" "$TMPDIR_TEST/project"
}

# ── skill_installed: universal agents ────────────────────────────────────────

@test "skill_installed: finds cursor skill in project .agents/skills" {
  mkdir -p "$TMPDIR_TEST/project/.agents/skills/mz-create-prd"
  printf -- "---\nname: mz-create-prd\n---\n" \
    > "$TMPDIR_TEST/project/.agents/skills/mz-create-prd/SKILL.md"
  skill_installed "cursor" "mz-create-prd" "$TMPDIR_TEST/project"
}

@test "skill_installed: finds gemini-cli skill in .agents/skills" {
  mkdir -p "$TMPDIR_TEST/project/.agents/skills/mz-execute-task"
  printf -- "---\nname: mz-execute-task\n---\n" \
    > "$TMPDIR_TEST/project/.agents/skills/mz-execute-task/SKILL.md"
  skill_installed "gemini-cli" "mz-execute-task" "$TMPDIR_TEST/project"
}

@test "skill_installed: finds codex skill in global ~/.agents/skills" {
  mkdir -p "$HOME/.agents/skills/mz-create-prd"
  printf -- "---\nname: mz-create-prd\n---\n" \
    > "$HOME/.agents/skills/mz-create-prd/SKILL.md"
  skill_installed "codex" "mz-create-prd" "$TMPDIR_TEST/project"
}
