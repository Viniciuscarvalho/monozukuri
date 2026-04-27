#!/usr/bin/env bats
# test/unit/setup_detect.bats — unit tests for lib/setup/detect.sh

setup() {
  REPO_ROOT="$(cd "$(dirname "$BATS_TEST_FILENAME")/../.." && pwd)"
  LIB_DIR="$REPO_ROOT/lib"
  export LIB_DIR

  source "$LIB_DIR/setup/detect.sh"

  TMPDIR_TEST="$(mktemp -d)"
  # Override HOME so detection doesn't touch the real ~/.claude etc.
  export HOME="$TMPDIR_TEST/home"
  mkdir -p "$HOME"
  # Change to a temp project dir
  ORIG_DIR="$(pwd)"
  cd "$TMPDIR_TEST"
}

teardown() {
  cd "$ORIG_DIR"
  rm -rf "$TMPDIR_TEST"
}

# ── setup_all_agents ──────────────────────────────────────────────────────────

@test "setup_all_agents: lists the four supported agents" {
  local agents
  agents="$(setup_all_agents)"
  [[ "$agents" == *"claude-code"* ]]
  [[ "$agents" == *"cursor"* ]]
  [[ "$agents" == *"gemini-cli"* ]]
  [[ "$agents" == *"codex"* ]]
}

@test "setup_all_agents: does not list aider" {
  [[ "$(setup_all_agents)" != *"aider"* ]]
}

# ── setup_agent_name ──────────────────────────────────────────────────────────

@test "setup_agent_name: returns display name for claude-code" {
  [ "$(setup_agent_name "claude-code")" = "Claude Code" ]
}

@test "setup_agent_name: returns display name for cursor" {
  [ "$(setup_agent_name "cursor")" = "Cursor" ]
}

@test "setup_agent_name: falls back to id for unknown agent" {
  [ "$(setup_agent_name "unknown-agent")" = "unknown-agent" ]
}

# ── setup_agent_type ──────────────────────────────────────────────────────────

@test "setup_agent_type: claude-code is specific" {
  [ "$(setup_agent_type "claude-code")" = "specific" ]
}

@test "setup_agent_type: cursor is universal" {
  [ "$(setup_agent_type "cursor")" = "universal" ]
}

@test "setup_agent_type: gemini-cli is universal" {
  [ "$(setup_agent_type "gemini-cli")" = "universal" ]
}

@test "setup_agent_type: codex is universal" {
  [ "$(setup_agent_type "codex")" = "universal" ]
}

# ── setup_agent_detected: no agents present ────────────────────────────────────

@test "setup_agent_detected: returns 1 when no agent dirs exist" {
  local rc=0
  setup_agent_detected "claude-code" || rc=$?
  [ "$rc" -eq 1 ]
}

@test "setup_agent_detected: returns 1 for gemini-cli when ~/.gemini absent" {
  local rc=0
  setup_agent_detected "gemini-cli" || rc=$?
  [ "$rc" -eq 1 ]
}

# ── setup_agent_detected: project-local dirs ──────────────────────────────────

@test "setup_agent_detected: finds claude-code via .claude/ in project" {
  mkdir -p ".claude"
  setup_agent_detected "claude-code"
}

@test "setup_agent_detected: finds cursor via .cursor/ in project" {
  mkdir -p ".cursor"
  setup_agent_detected "cursor"
}

# ── setup_agent_detected: home dirs ───────────────────────────────────────────

@test "setup_agent_detected: finds claude-code via ~/.claude" {
  mkdir -p "$HOME/.claude"
  setup_agent_detected "claude-code"
}

@test "setup_agent_detected: finds gemini-cli via ~/.gemini" {
  mkdir -p "$HOME/.gemini"
  setup_agent_detected "gemini-cli"
}

@test "setup_agent_detected: finds codex via ~/.codex" {
  mkdir -p "$HOME/.codex"
  setup_agent_detected "codex"
}

@test "setup_agent_detected: finds codex via CODEX_HOME env" {
  local custom_home="$TMPDIR_TEST/custom_codex"
  mkdir -p "$custom_home"
  CODEX_HOME="$custom_home" setup_agent_detected "codex"
}

# ── setup_detected_agents ─────────────────────────────────────────────────────

@test "setup_detected_agents: empty when no agents present" {
  [ -z "$(setup_detected_agents)" ]
}

@test "setup_detected_agents: lists claude-code when .claude exists" {
  mkdir -p "$HOME/.claude"
  local detected
  detected="$(setup_detected_agents)"
  [[ "$detected" == *"claude-code"* ]]
}

@test "setup_detected_agents: lists multiple agents when present" {
  mkdir -p "$HOME/.claude" "$HOME/.cursor"
  local detected
  detected="$(setup_detected_agents)"
  [[ "$detected" == *"claude-code"* ]]
  [[ "$detected" == *"cursor"* ]]
}

# ── setup_agent_project_path ──────────────────────────────────────────────────

@test "setup_agent_project_path: claude-code uses .claude/skills" {
  [ "$(setup_agent_project_path "claude-code")" = ".claude/skills" ]
}

@test "setup_agent_project_path: universal agents use .agents/skills" {
  [ "$(setup_agent_project_path "cursor")" = ".agents/skills" ]
  [ "$(setup_agent_project_path "gemini-cli")" = ".agents/skills" ]
  [ "$(setup_agent_project_path "codex")" = ".agents/skills" ]
}

# ── setup_agent_global_path ───────────────────────────────────────────────────

@test "setup_agent_global_path: claude-code uses CLAUDE_CONFIG_DIR when set" {
  local result
  result="$(CLAUDE_CONFIG_DIR="/custom/claude" setup_agent_global_path "claude-code")"
  [ "$result" = "/custom/claude/skills" ]
}

@test "setup_agent_global_path: claude-code defaults to ~/.claude/skills" {
  local result
  result="$(unset CLAUDE_CONFIG_DIR; setup_agent_global_path "claude-code")"
  [ "$result" = "$HOME/.claude/skills" ]
}

@test "setup_agent_global_path: gemini-cli uses ~/.gemini/skills" {
  [ "$(setup_agent_global_path "gemini-cli")" = "$HOME/.gemini/skills" ]
}

@test "setup_agent_global_path: codex uses CODEX_HOME when set" {
  local result
  result="$(CODEX_HOME="/custom/codex" setup_agent_global_path "codex")"
  [ "$result" = "/custom/codex/skills" ]
}
