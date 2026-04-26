#!/usr/bin/env bats
# test/unit/lib_agent_codex.bats — unit tests for lib/agent/adapter-codex.sh

setup() {
  REPO_ROOT="$(cd "$(dirname "$BATS_TEST_FILENAME")/../.." && pwd)"
  LIB_DIR="$REPO_ROOT/lib"
  export LIB_DIR
  source "$LIB_DIR/agent/contract.sh"
  source "$LIB_DIR/agent/adapter-codex.sh"
}

# ── agent_name ───────────────────────────────────────────────────────────────

@test "codex agent_name returns 'codex'" {
  run agent_name
  [ "$status" -eq 0 ]
  [ "$output" = "codex" ]
}

# ── agent_capabilities ────────────────────────────────────────────────────────

@test "codex agent_capabilities outputs valid JSON" {
  run bash -c "source '$LIB_DIR/agent/adapter-codex.sh' && agent_capabilities | jq empty"
  [ "$status" -eq 0 ]
}

@test "codex agent_capabilities agent field is 'codex'" {
  local cap agent_field
  cap=$(agent_capabilities)
  agent_field=$(echo "$cap" | jq -r '.agent')
  [ "$agent_field" = "codex" ]
}

@test "codex agent_capabilities has approval_modes with 'suggest'" {
  local cap
  cap=$(agent_capabilities)
  echo "$cap" | jq -e '.supports.approval_modes | index("suggest")' >/dev/null
}

@test "codex agent_capabilities has approval_modes with 'auto-edit'" {
  local cap
  cap=$(agent_capabilities)
  echo "$cap" | jq -e '.supports.approval_modes | index("auto-edit")' >/dev/null
}

# ── agent_doctor ─────────────────────────────────────────────────────────────

@test "codex agent_doctor: fails when codex binary not in PATH" {
  run bash -c "
    source '$LIB_DIR/agent/adapter-codex.sh'
    PATH=/dev/null agent_doctor
  "
  [ "$status" -ne 0 ]
}

@test "codex agent_doctor: fails when OPENAI_API_KEY missing (codex found but no key)" {
  local mock_dir
  mock_dir="$(mktemp -d)"
  printf '#!/bin/bash\necho "codex 1.0"\nexit 0\n' > "$mock_dir/codex"
  chmod +x "$mock_dir/codex"
  run bash -c "
    source '$LIB_DIR/agent/adapter-codex.sh'
    unset OPENAI_API_KEY
    PATH='$mock_dir' agent_doctor 2>&1
  "
  rm -rf "$mock_dir"
  [ "$status" -ne 0 ]
  [[ "$output" == *"OPENAI_API_KEY"* ]]
}

@test "codex agent_doctor: succeeds when codex found and OPENAI_API_KEY set" {
  local mock_dir
  mock_dir="$(mktemp -d)"
  printf '#!/bin/bash\nexit 0\n' > "$mock_dir/codex"
  chmod +x "$mock_dir/codex"
  run bash -c "
    source '$LIB_DIR/agent/adapter-codex.sh'
    OPENAI_API_KEY='test-key' PATH='$mock_dir' agent_doctor
  "
  rm -rf "$mock_dir"
  [ "$status" -eq 0 ]
}

# ── autonomy → approval_mode mapping ─────────────────────────────────────────

@test "codex agent_run_phase uses 'auto-edit' for full_auto autonomy" {
  local mock_dir tmp_script
  mock_dir="$(mktemp -d)"
  tmp_script="$(mktemp /tmp/mz_codex_XXXXXX.sh)"
  printf '#!/bin/bash\necho "codex_args: $*"\nexit 0\n' > "$mock_dir/codex"
  chmod +x "$mock_dir/codex"
  cat > "$tmp_script" <<SCRIPT
#!/bin/bash
export PATH="$mock_dir:\$PATH"
source "$LIB_DIR/agent/adapter-codex.sh"
MONOZUKURI_FEATURE_ID="feat-001"
MONOZUKURI_WORKTREE="$mock_dir"
MONOZUKURI_AUTONOMY="full_auto"
MONOZUKURI_LOG_FILE="/tmp/mz-codex-test-\$\$.log"
agent_run_phase 2>&1
SCRIPT
  chmod +x "$tmp_script"
  run bash "$tmp_script"
  rm -rf "$mock_dir" "$tmp_script"
  [[ "$output" == *"auto-edit"* ]]
}

@test "codex agent_run_phase uses 'suggest' for checkpoint autonomy" {
  local mock_dir tmp_script
  mock_dir="$(mktemp -d)"
  tmp_script="$(mktemp /tmp/mz_codex_XXXXXX.sh)"
  printf '#!/bin/bash\necho "codex_args: $*"\nexit 0\n' > "$mock_dir/codex"
  chmod +x "$mock_dir/codex"
  cat > "$tmp_script" <<SCRIPT
#!/bin/bash
export PATH="$mock_dir:\$PATH"
source "$LIB_DIR/agent/adapter-codex.sh"
MONOZUKURI_FEATURE_ID="feat-001"
MONOZUKURI_WORKTREE="$mock_dir"
MONOZUKURI_AUTONOMY="checkpoint"
MONOZUKURI_LOG_FILE="/tmp/mz-codex-test-\$\$.log"
agent_run_phase 2>&1
SCRIPT
  chmod +x "$tmp_script"
  run bash "$tmp_script"
  rm -rf "$mock_dir" "$tmp_script"
  [[ "$output" == *"suggest"* ]]
}

# ── agent_estimate_tokens ─────────────────────────────────────────────────────

@test "codex agent_estimate_tokens returns positive integer" {
  local tokens
  tokens=$(printf 'Hello codex prompt' | agent_estimate_tokens)
  [ "$tokens" -gt 0 ]
}

# ── agent_report_cost ────────────────────────────────────────────────────────

@test "codex agent_report_cost returns numeric value" {
  unset -f cost_report 2>/dev/null || true
  local cost
  cost=$(agent_report_cost)
  [[ "$cost" =~ ^[0-9]+(\.[0-9]+)?$ ]]
}
