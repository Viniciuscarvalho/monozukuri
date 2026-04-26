#!/usr/bin/env bats
# test/conformance/agent_native_context.bats
# Verifies that every adapter implementing agent_native_context_files returns
# a valid JSON array. Adapters that don't implement it are skipped (it's optional).

setup() {
  REPO_ROOT="$(cd "$(dirname "$BATS_TEST_FILENAME")/../.." && pwd)"
  LIB_DIR="$REPO_ROOT/lib"
  export LIB_DIR REPO_ROOT
  source "$LIB_DIR/agent/contract.sh"
}

_assert_native_context_valid() {
  local adapter="$1"
  source "$LIB_DIR/agent/adapter-${adapter}.sh"

  if ! declare -f agent_native_context_files &>/dev/null; then
    skip "adapter $adapter does not implement agent_native_context_files (optional)"
  fi

  result=$(agent_native_context_files)
  # Must be a valid JSON array
  jq -e 'type == "array"' <<<"$result"
  # Every element must be a non-empty string
  jq -e 'all(.[]?; type == "string" and length > 0)' <<<"$result"
}

@test "claude-code: agent_native_context_files returns valid JSON array" {
  _assert_native_context_valid "claude-code"
}

@test "codex: agent_native_context_files returns valid JSON array" {
  _assert_native_context_valid "codex"
}

@test "gemini: agent_native_context_files returns valid JSON array" {
  _assert_native_context_valid "gemini"
}

@test "aider: agent_native_context_files returns valid JSON array" {
  _assert_native_context_valid "aider"
}

@test "kiro: agent_native_context_files returns valid JSON array" {
  _assert_native_context_valid "kiro"
}
