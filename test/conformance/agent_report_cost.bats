#!/usr/bin/env bats
# test/conformance/agent_report_cost.bats
# Verifies that every adapter's agent_report_cost() returns a numeric USD
# value (float or integer string, >= 0).

setup() {
  REPO_ROOT="$(cd "$(dirname "$BATS_TEST_FILENAME")/../.." && pwd)"
  LIB_DIR="$REPO_ROOT/lib"
  export LIB_DIR REPO_ROOT
  source "$LIB_DIR/agent/contract.sh"
}

_assert_report_cost_valid() {
  local adapter="$1"
  source "$LIB_DIR/agent/adapter-${adapter}.sh"

  local result
  result=$(agent_report_cost)

  [[ "$result" =~ ^[0-9]+(\.[0-9]+)?$ ]] || {
    echo "agent_report_cost returned non-numeric '$result' for $adapter" >&2
    return 1
  }
}

@test "claude-code: agent_report_cost returns numeric USD value" {
  _assert_report_cost_valid "claude-code"
}

@test "codex: agent_report_cost returns numeric USD value" {
  _assert_report_cost_valid "codex"
}

@test "gemini: agent_report_cost returns numeric USD value" {
  _assert_report_cost_valid "gemini"
}

@test "kiro: agent_report_cost returns numeric USD value" {
  _assert_report_cost_valid "kiro"
}

@test "aider: agent_report_cost returns numeric USD value" {
  _assert_report_cost_valid "aider"
}
