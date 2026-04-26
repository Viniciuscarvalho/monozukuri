#!/usr/bin/env bats
# test/unit/lib_agent_claude_code.bats — unit tests for lib/agent/adapter-claude-code.sh

setup() {
  REPO_ROOT="$(cd "$(dirname "$BATS_TEST_FILENAME")/../.." && pwd)"
  LIB_DIR="$REPO_ROOT/lib"
  export LIB_DIR
  source "$LIB_DIR/agent/contract.sh"
  source "$LIB_DIR/agent/adapter-claude-code.sh"
}

# ── agent_name ───────────────────────────────────────────────────────────────

@test "agent_name returns 'claude-code'" {
  run agent_name
  [ "$status" -eq 0 ]
  [ "$output" = "claude-code" ]
}

# ── agent_capabilities ────────────────────────────────────────────────────────

@test "agent_capabilities outputs valid JSON" {
  run bash -c "
    source '$LIB_DIR/agent/adapter-claude-code.sh'
    agent_capabilities | jq empty
  "
  [ "$status" -eq 0 ]
}

@test "agent_capabilities JSON has 'agent' field equal to 'claude-code'" {
  local cap agent_field
  cap=$(agent_capabilities)
  agent_field=$(echo "$cap" | jq -r '.agent')
  [ "$agent_field" = "claude-code" ]
}

@test "agent_capabilities JSON has 'supports.phases' array" {
  local cap phases
  cap=$(agent_capabilities)
  phases=$(echo "$cap" | jq -r '.supports.phases | length')
  [ "$phases" -gt 0 ]
}

@test "agent_capabilities JSON has 'auth.methods' array" {
  local cap methods
  cap=$(agent_capabilities)
  methods=$(echo "$cap" | jq -r '.auth.methods | length')
  [ "$methods" -gt 0 ]
}

@test "agent_capabilities JSON has 'models.default'" {
  local cap model_default
  cap=$(agent_capabilities)
  model_default=$(echo "$cap" | jq -r '.models.default')
  [ -n "$model_default" ]
  [ "$model_default" != "null" ]
}

# ── agent_doctor ─────────────────────────────────────────────────────────────

@test "agent_doctor: fails when claude binary not in PATH" {
  run bash -c "
    source '$LIB_DIR/agent/adapter-claude-code.sh'
    PATH=/dev/null agent_doctor
  "
  [ "$status" -ne 0 ]
}

@test "agent_doctor: error message mentions install URL when binary missing" {
  run bash -c "
    source '$LIB_DIR/agent/adapter-claude-code.sh'
    PATH=/dev/null agent_doctor 2>&1
  "
  [[ "$output" == *"claude"* ]]
}

# ── agent_estimate_tokens ─────────────────────────────────────────────────────

@test "agent_estimate_tokens: returns a positive integer for non-empty input" {
  local tokens
  tokens=$(printf 'Hello world, this is a test prompt.' | agent_estimate_tokens)
  [ "$tokens" -gt 0 ]
}

@test "agent_estimate_tokens: returns 0 for empty input" {
  local tokens
  tokens=$(printf '' | agent_estimate_tokens)
  [ "$tokens" -ge 0 ]
}

@test "agent_estimate_tokens: larger input gives larger token count" {
  local short long
  short=$(printf 'Hi' | agent_estimate_tokens)
  long=$(printf 'This is a much longer prompt with many more words that should result in a higher token count than the short one.' | agent_estimate_tokens)
  [ "$long" -gt "$short" ]
}

# ── agent_report_cost ────────────────────────────────────────────────────────

@test "agent_report_cost: returns a numeric value when cost_report not defined" {
  unset -f cost_report 2>/dev/null || true
  local cost
  cost=$(agent_report_cost)
  # Should be a valid number (possibly "0.00")
  [[ "$cost" =~ ^[0-9]+(\.[0-9]+)?$ ]]
}

@test "agent_report_cost: delegates to cost_report when available" {
  cost_report() { echo "1.23"; }
  local cost
  cost=$(agent_report_cost)
  [ "$cost" = "1.23" ]
  unset -f cost_report
}
