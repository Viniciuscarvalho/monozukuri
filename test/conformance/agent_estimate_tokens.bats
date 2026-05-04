#!/usr/bin/env bats
# test/conformance/agent_estimate_tokens.bats
# Verifies that every adapter's agent_estimate_tokens() reads stdin and
# returns a positive integer (token count estimate).

setup() {
  REPO_ROOT="$(cd "$(dirname "$BATS_TEST_FILENAME")/../.." && pwd)"
  LIB_DIR="$REPO_ROOT/lib"
  export LIB_DIR REPO_ROOT
  source "$LIB_DIR/agent/contract.sh"
}

_assert_estimate_tokens_valid() {
  local adapter="$1"
  source "$LIB_DIR/agent/adapter-${adapter}.sh"

  local result
  result=$(printf 'hello world this is a test prompt' | agent_estimate_tokens)

  [[ "$result" =~ ^[0-9]+$ ]] || {
    echo "agent_estimate_tokens returned non-integer '$result' for $adapter" >&2
    return 1
  }
  [ "$result" -gt 0 ] || {
    echo "agent_estimate_tokens returned zero for non-empty input for $adapter" >&2
    return 1
  }
}

@test "claude-code: agent_estimate_tokens returns positive integer" {
  _assert_estimate_tokens_valid "claude-code"
}

@test "codex: agent_estimate_tokens returns positive integer" {
  _assert_estimate_tokens_valid "codex"
}

@test "gemini: agent_estimate_tokens returns positive integer" {
  _assert_estimate_tokens_valid "gemini"
}

@test "kiro: agent_estimate_tokens returns positive integer" {
  _assert_estimate_tokens_valid "kiro"
}

@test "aider: agent_estimate_tokens returns positive integer" {
  _assert_estimate_tokens_valid "aider"
}

@test "estimate_tokens: empty input returns 0 or a non-negative integer" {
  source "$LIB_DIR/agent/adapter-claude-code.sh"
  local result
  result=$(printf '' | agent_estimate_tokens)
  [[ "$result" =~ ^[0-9]+$ ]] || {
    echo "agent_estimate_tokens returned non-integer '$result' for empty input" >&2
    return 1
  }
}
