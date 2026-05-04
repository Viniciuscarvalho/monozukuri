#!/usr/bin/env bats
# test/conformance/agent_name.bats
# Verifies that every adapter's agent_name() returns a non-empty lowercase
# identifier matching ^[a-z][a-z0-9-]*$.

ADAPTERS=(claude-code codex gemini kiro aider)

setup() {
  REPO_ROOT="$(cd "$(dirname "$BATS_TEST_FILENAME")/../.." && pwd)"
  LIB_DIR="$REPO_ROOT/lib"
  export LIB_DIR REPO_ROOT
  source "$LIB_DIR/agent/contract.sh"
}

_assert_agent_name_valid() {
  local adapter="$1"
  source "$LIB_DIR/agent/adapter-${adapter}.sh"

  local name
  name=$(agent_name)

  [ -n "$name" ] || { echo "agent_name returned empty string for $adapter" >&2; return 1; }
  [[ "$name" =~ ^[a-z][a-z0-9-]*$ ]] || {
    echo "agent_name '$name' does not match ^[a-z][a-z0-9-]*$ for $adapter" >&2
    return 1
  }
}

@test "claude-code: agent_name returns valid identifier" {
  _assert_agent_name_valid "claude-code"
}

@test "codex: agent_name returns valid identifier" {
  _assert_agent_name_valid "codex"
}

@test "gemini: agent_name returns valid identifier" {
  _assert_agent_name_valid "gemini"
}

@test "kiro: agent_name returns valid identifier" {
  _assert_agent_name_valid "kiro"
}

@test "aider: agent_name returns valid identifier" {
  _assert_agent_name_valid "aider"
}
