#!/usr/bin/env bats
# test/conformance/agent_capabilities.bats
# Verifies that every adapter's agent_capabilities() returns a JSON object
# with the required top-level keys: agent, supports, models, auth.
# supports.phases must be a non-empty array of strings.

setup() {
  REPO_ROOT="$(cd "$(dirname "$BATS_TEST_FILENAME")/../.." && pwd)"
  LIB_DIR="$REPO_ROOT/lib"
  export LIB_DIR REPO_ROOT
  source "$LIB_DIR/agent/contract.sh"
}

_assert_capabilities_valid() {
  local adapter="$1"
  source "$LIB_DIR/agent/adapter-${adapter}.sh"

  local caps
  caps=$(agent_capabilities)

  # Must be valid JSON object
  node -e "
    const c = JSON.parse(process.argv[1]);

    // Required top-level keys
    ['agent', 'supports', 'models', 'auth'].forEach(k => {
      if (!(k in c)) throw new Error('missing key: ' + k);
    });

    // supports.phases must be non-empty string array
    if (!Array.isArray(c.supports.phases) || c.supports.phases.length === 0)
      throw new Error('supports.phases must be a non-empty array');
    c.supports.phases.forEach(p => {
      if (typeof p !== 'string' || p.length === 0)
        throw new Error('phase entry must be a non-empty string, got: ' + JSON.stringify(p));
    });

    // models.default must be a non-empty string
    if (typeof c.models.default !== 'string' || c.models.default.length === 0)
      throw new Error('models.default must be a non-empty string');
  " "$caps" || {
    echo "agent_capabilities JSON validation failed for $adapter" >&2
    return 1
  }
}

@test "claude-code: agent_capabilities returns valid capability JSON" {
  _assert_capabilities_valid "claude-code"
}

@test "codex: agent_capabilities returns valid capability JSON" {
  _assert_capabilities_valid "codex"
}

@test "gemini: agent_capabilities returns valid capability JSON" {
  _assert_capabilities_valid "gemini"
}

@test "kiro: agent_capabilities returns valid capability JSON" {
  _assert_capabilities_valid "kiro"
}

@test "aider: agent_capabilities returns valid capability JSON" {
  _assert_capabilities_valid "aider"
}
