#!/usr/bin/env bats
# test/unit/cmd_agent.bats — unit tests for cmd/agent.sh

setup() {
  REPO_ROOT="$(cd "$(dirname "$BATS_TEST_FILENAME")/../.." && pwd)"
  LIB_DIR="$REPO_ROOT/lib"
  CMD_DIR="$REPO_ROOT/cmd"
  ORCHESTRATE="$REPO_ROOT/orchestrate.sh"
  MOCK_CLAUDE="$REPO_ROOT/test/fixtures/agents/mock-claude-code"
  export LIB_DIR CMD_DIR ORCHESTRATE

  TMP_DIR="$(mktemp -d)"
  export TMP_DIR

  # source contract so agent_list is available
  source "$LIB_DIR/agent/contract.sh"
}

teardown() {
  rm -rf "$TMP_DIR"
}

# ── agent list ────────────────────────────────────────────────────────────────

@test "agent list shows claude-code" {
  run bash "$ORCHESTRATE" agent list 2>/dev/null || true
  [[ "$output" == *"claude-code"* ]]
}

@test "agent list shows codex" {
  run bash "$ORCHESTRATE" agent list 2>/dev/null || true
  [[ "$output" == *"codex"* ]]
}

@test "agent list shows gemini" {
  run bash "$ORCHESTRATE" agent list 2>/dev/null || true
  [[ "$output" == *"gemini"* ]]
}

@test "agent list shows kiro" {
  run bash "$ORCHESTRATE" agent list 2>/dev/null || true
  [[ "$output" == *"kiro"* ]]
}

@test "agent list marks active agent with *" {
  MONOZUKURI_AGENT="claude-code" run bash "$ORCHESTRATE" agent list 2>/dev/null || true
  [[ "$output" == *"*"* ]]
}

@test "agent list shows 'installed' when mock-claude is in PATH" {
  PATH="$MOCK_CLAUDE:$PATH" MONOZUKURI_AGENT="claude-code" \
    run bash "$ORCHESTRATE" agent list 2>/dev/null || true
  [[ "$output" == *"installed"* ]]
}

# ── agent doctor ─────────────────────────────────────────────────────────────

@test "agent doctor exits non-zero when claude not in PATH" {
  # Create a mock dir without a 'claude' binary to isolate the test
  local no_claude_dir
  no_claude_dir="$(mktemp -d)"
  # Run with PATH that excludes real claude (only has mock dir + system tools)
  run env PATH="$no_claude_dir:/usr/bin:/bin:/usr/sbin:/sbin" \
    bash "$ORCHESTRATE" agent doctor claude-code 2>&1
  rm -rf "$no_claude_dir"
  # Doctor must report FAILED (or return non-zero)
  [ "$status" -ne 0 ] || [[ "$output" == *"FAILED"* ]]
}

@test "agent doctor succeeds for claude-code when mock is in PATH" {
  PATH="$MOCK_CLAUDE:$PATH" run bash "$ORCHESTRATE" agent doctor claude-code
  [ "$status" -eq 0 ]
  [[ "$output" == *"ok"* ]]
}

# ── agent enable ──────────────────────────────────────────────────────────────

@test "agent enable writes agent: to config.yaml" {
  local cfg="$TMP_DIR/.monozukuri/config.yaml"
  mkdir -p "$TMP_DIR/.monozukuri"
  cat > "$cfg" << 'EOCFG'
source:
  adapter: markdown
autonomy: checkpoint
agent: claude-code
EOCFG
  run bash "$ORCHESTRATE" agent enable codex --config "$cfg"
  [ "$status" -eq 0 ]
  grep -q "^agent: codex" "$cfg"
}

@test "agent enable appends agent: when not present" {
  local cfg="$TMP_DIR/.monozukuri/config.yaml"
  mkdir -p "$TMP_DIR/.monozukuri"
  cat > "$cfg" << 'EOCFG'
source:
  adapter: markdown
autonomy: checkpoint
EOCFG
  run bash "$ORCHESTRATE" agent enable gemini --config "$cfg"
  [ "$status" -eq 0 ]
  grep -q "agent: gemini" "$cfg"
}

@test "agent enable fails for unknown agent name" {
  local cfg="$TMP_DIR/.monozukuri/config.yaml"
  mkdir -p "$TMP_DIR/.monozukuri"
  echo "autonomy: checkpoint" > "$cfg"
  run bash "$ORCHESTRATE" agent enable no-such-agent --config "$cfg"
  [ "$status" -ne 0 ]
}
