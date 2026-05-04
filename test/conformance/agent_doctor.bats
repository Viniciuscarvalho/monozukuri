#!/usr/bin/env bats
# test/conformance/agent_doctor.bats
# Verifies agent_doctor() behavior for all adapters:
#   - exits 1 and prints a diagnostic to stderr when the CLI binary is absent.
#   - exits 0 when the binary is on PATH and auth prerequisites are satisfied.
#
# Auth prerequisites are stubbed via mock binaries in test/fixtures/agents/
# and env vars — no real CLI or credentials are required.
# Uses /bin/bash with explicit PATH to avoid bats PATH-override pitfalls.

setup() {
  REPO_ROOT="$(cd "$(dirname "$BATS_TEST_FILENAME")/../.." && pwd)"
  LIB_DIR="$REPO_ROOT/lib"
  export LIB_DIR REPO_ROOT

  # Empty stub dir — used as a PATH with no binaries to trigger "not found"
  STUB_DIR="$(mktemp -d)"
}

teardown() {
  rm -rf "$STUB_DIR"
}

# ── binary-missing checks ─────────────────────────────────────────────────────
# Run with STUB_DIR as the sole PATH entry so command -v <binary> fails.
# Stderr is redirected to stdout inside the subshell so bats captures it.

@test "claude-code: agent_doctor exits non-zero when claude binary is missing" {
  run /bin/bash -c "
    export PATH='$STUB_DIR'
    source '$LIB_DIR/agent/contract.sh'
    source '$LIB_DIR/agent/adapter-claude-code.sh'
    agent_doctor 2>&1
  "
  [ "$status" -ne 0 ]
  [[ "$output" == *"claude"* ]]
}

@test "codex: agent_doctor exits non-zero when codex binary is missing" {
  run /bin/bash -c "
    export PATH='$STUB_DIR'
    source '$LIB_DIR/agent/contract.sh'
    source '$LIB_DIR/agent/adapter-codex.sh'
    agent_doctor 2>&1
  "
  [ "$status" -ne 0 ]
  [[ "$output" == *"codex"* ]]
}

@test "gemini: agent_doctor exits non-zero when gemini binary is missing" {
  run /bin/bash -c "
    export PATH='$STUB_DIR'
    source '$LIB_DIR/agent/contract.sh'
    source '$LIB_DIR/agent/adapter-gemini.sh'
    agent_doctor 2>&1
  "
  [ "$status" -ne 0 ]
  [[ "$output" == *"gemini"* ]]
}

@test "kiro: agent_doctor exits non-zero when kiro binary is missing" {
  run /bin/bash -c "
    export PATH='$STUB_DIR'
    source '$LIB_DIR/agent/contract.sh'
    source '$LIB_DIR/agent/adapter-kiro.sh'
    agent_doctor 2>&1
  "
  [ "$status" -ne 0 ]
  [[ "$output" == *"kiro"* ]]
}

@test "aider: agent_doctor exits non-zero when aider binary is missing" {
  run /bin/bash -c "
    export PATH='$STUB_DIR'
    source '$LIB_DIR/agent/contract.sh'
    source '$LIB_DIR/agent/adapter-aider.sh'
    agent_doctor 2>&1
  "
  [ "$status" -ne 0 ]
  [[ "$output" == *"aider"* ]]
}

# ── binary-present + auth-satisfied checks ────────────────────────────────────
# Mock binaries from test/fixtures/agents/ are prepended to PATH.
# Auth env vars are exported inside the subshell.

@test "claude-code: agent_doctor exits 0 with mock binary and auth" {
  local mock_dir="$REPO_ROOT/test/fixtures/agents/mock-claude-code"
  run /bin/bash -c "
    export PATH='$mock_dir:$STUB_DIR:/usr/bin:/bin'
    source '$LIB_DIR/agent/contract.sh'
    source '$LIB_DIR/agent/adapter-claude-code.sh'
    agent_doctor 2>&1
  "
  [ "$status" -eq 0 ]
}

@test "codex: agent_doctor exits 0 with mock binary and OPENAI_API_KEY" {
  local mock_dir="$REPO_ROOT/test/fixtures/agents/mock-codex"
  run /bin/bash -c "
    export PATH='$mock_dir:$STUB_DIR:/usr/bin:/bin'
    export OPENAI_API_KEY='mock-key'
    source '$LIB_DIR/agent/contract.sh'
    source '$LIB_DIR/agent/adapter-codex.sh'
    agent_doctor 2>&1
  "
  [ "$status" -eq 0 ]
}

@test "gemini: agent_doctor exits 0 with mock binary and GEMINI_API_KEY" {
  local mock_dir="$REPO_ROOT/test/fixtures/agents/mock-gemini"
  run /bin/bash -c "
    export PATH='$mock_dir:$STUB_DIR:/usr/bin:/bin'
    export GEMINI_API_KEY='mock-key'
    source '$LIB_DIR/agent/contract.sh'
    source '$LIB_DIR/agent/adapter-gemini.sh'
    agent_doctor 2>&1
  "
  [ "$status" -eq 0 ]
}

@test "kiro: agent_doctor exits 0 with mock kiro binary and stub aws" {
  local mock_dir="$REPO_ROOT/test/fixtures/agents/mock-kiro"
  printf '#!/bin/bash\nexit 0\n' > "$STUB_DIR/aws"
  chmod +x "$STUB_DIR/aws"
  run /bin/bash -c "
    export PATH='$mock_dir:$STUB_DIR:/usr/bin:/bin'
    source '$LIB_DIR/agent/contract.sh'
    source '$LIB_DIR/agent/adapter-kiro.sh'
    agent_doctor 2>&1
  "
  [ "$status" -eq 0 ]
}

@test "aider: agent_doctor exits 0 with mock binary and ANTHROPIC_API_KEY" {
  local mock_dir="$REPO_ROOT/test/fixtures/agents/mock-aider"
  run /bin/bash -c "
    export PATH='$mock_dir:$STUB_DIR:/usr/bin:/bin'
    export ANTHROPIC_API_KEY='mock-key'
    source '$LIB_DIR/agent/contract.sh'
    source '$LIB_DIR/agent/adapter-aider.sh'
    agent_doctor 2>&1
  "
  [ "$status" -eq 0 ]
}

# ── auth-missing checks (binary present, no credentials) ──────────────────────

@test "codex: agent_doctor exits non-zero when OPENAI_API_KEY is unset" {
  local mock_dir="$REPO_ROOT/test/fixtures/agents/mock-codex"
  run /bin/bash -c "
    export PATH='$mock_dir:$STUB_DIR:/usr/bin:/bin'
    unset OPENAI_API_KEY
    source '$LIB_DIR/agent/contract.sh'
    source '$LIB_DIR/agent/adapter-codex.sh'
    agent_doctor 2>&1
  "
  [ "$status" -ne 0 ]
  [[ "$output" == *"OPENAI_API_KEY"* ]]
}

@test "gemini: agent_doctor exits non-zero when no auth method is available" {
  local mock_dir="$REPO_ROOT/test/fixtures/agents/mock-gemini"
  local no_adc_home
  no_adc_home="$(mktemp -d)"
  run /bin/bash -c "
    export PATH='$mock_dir:$STUB_DIR:/usr/bin:/bin'
    export HOME='$no_adc_home'
    unset GEMINI_API_KEY
    source '$LIB_DIR/agent/contract.sh'
    source '$LIB_DIR/agent/adapter-gemini.sh'
    agent_doctor 2>&1
  "
  [ "$status" -ne 0 ]
  rm -rf "$no_adc_home"
}

@test "aider: agent_doctor exits non-zero when no API key is set" {
  local mock_dir="$REPO_ROOT/test/fixtures/agents/mock-aider"
  run /bin/bash -c "
    export PATH='$mock_dir:$STUB_DIR:/usr/bin:/bin'
    unset ANTHROPIC_API_KEY OPENAI_API_KEY
    source '$LIB_DIR/agent/contract.sh'
    source '$LIB_DIR/agent/adapter-aider.sh'
    agent_doctor 2>&1
  "
  [ "$status" -ne 0 ]
}
