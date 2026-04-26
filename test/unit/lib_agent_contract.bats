#!/usr/bin/env bats
# test/unit/lib_agent_contract.bats — unit tests for lib/agent/contract.sh

setup() {
  REPO_ROOT="$(cd "$(dirname "$BATS_TEST_FILENAME")/../.." && pwd)"
  LIB_DIR="$REPO_ROOT/lib"
  export LIB_DIR
  source "$LIB_DIR/agent/contract.sh"
  # Unset any previously sourced adapter functions so tests start clean
  unset -f agent_name agent_capabilities agent_doctor \
            agent_estimate_tokens agent_run_phase agent_report_cost 2>/dev/null || true
}

# ── contract.sh loads ────────────────────────────────────────────────────────

@test "contract.sh sources without error" {
  run bash -c "source '$LIB_DIR/agent/contract.sh' && echo ok"
  [ "$status" -eq 0 ]
  [[ "$output" == *"ok"* ]]
}

@test "agent_load: returns 1 for unknown adapter" {
  run agent_load "no-such-agent"
  [ "$status" -eq 1 ]
}

@test "agent_load: sources claude-code adapter" {
  run bash -c "
    source '$LIB_DIR/agent/contract.sh'
    agent_load claude-code && declare -f agent_name >/dev/null && echo ok
  "
  [ "$status" -eq 0 ]
  [[ "$output" == *"ok"* ]]
}

# ── agent_verify ─────────────────────────────────────────────────────────────

@test "agent_verify: passes after agent_load claude-code" {
  source "$LIB_DIR/agent/adapter-claude-code.sh"
  run agent_verify
  [ "$status" -eq 0 ]
}

@test "agent_verify: fails when functions are missing" {
  # source contract again to get a clean state (no adapter loaded)
  source "$LIB_DIR/agent/contract.sh"
  unset -f agent_name agent_capabilities agent_doctor \
            agent_estimate_tokens agent_run_phase agent_report_cost 2>/dev/null || true
  run agent_verify
  [ "$status" -ne 0 ]
}

# ── agent_list ───────────────────────────────────────────────────────────────

@test "agent_list: includes claude-code" {
  run agent_list
  [ "$status" -eq 0 ]
  [[ "$output" == *"claude-code"* ]]
}

@test "agent_list: each adapter-*.sh has a corresponding entry" {
  local count_files count_list
  count_files=$(ls "$LIB_DIR/agent/adapter-"*.sh 2>/dev/null | wc -l | tr -d ' ')
  count_list=$(agent_list | wc -l | tr -d ' ')
  [ "$count_files" -eq "$count_list" ]
}

# ── monozukuri_default_agent ─────────────────────────────────────────────────

@test "monozukuri_default_agent: returns claude-code by default" {
  unset MONOZUKURI_AGENT
  run monozukuri_default_agent
  [ "$status" -eq 0 ]
  [ "$output" = "claude-code" ]
}

@test "monozukuri_default_agent: respects MONOZUKURI_AGENT env var" {
  MONOZUKURI_AGENT="codex" run monozukuri_default_agent
  [ "$status" -eq 0 ]
  [ "$output" = "codex" ]
}

# ── all adapters implement the full contract ──────────────────────────────────

@test "every adapter-*.sh exposes all six contract functions" {
  local adapter failures=0
  for adapter in "$LIB_DIR/agent/adapter-"*.sh; do
    [[ -f "$adapter" ]] || continue
    local name
    name="$(basename "$adapter" .sh)"
    name="${name#adapter-}"
    local result
    result=$(bash -c "
      source '$LIB_DIR/agent/contract.sh'
      source '$adapter'
      agent_verify 2>&1
      echo \"exit:\$?\"
    ")
    if ! echo "$result" | grep -q "exit:0"; then
      printf 'FAIL: adapter %s missing functions:\n%s\n' "$name" "$result" >&2
      failures=$((failures + 1))
    fi
  done
  [ "$failures" -eq 0 ]
}
