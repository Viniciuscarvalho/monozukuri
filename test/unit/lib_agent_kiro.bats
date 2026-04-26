#!/usr/bin/env bats
# test/unit/lib_agent_kiro.bats — unit tests for lib/agent/adapter-kiro.sh

setup() {
  REPO_ROOT="$(cd "$(dirname "$BATS_TEST_FILENAME")/../.." && pwd)"
  LIB_DIR="$REPO_ROOT/lib"
  export LIB_DIR
  source "$LIB_DIR/agent/contract.sh"
  source "$LIB_DIR/agent/adapter-kiro.sh"
}

# ── agent_name ───────────────────────────────────────────────────────────────

@test "kiro agent_name returns 'kiro'" {
  run agent_name
  [ "$status" -eq 0 ]
  [ "$output" = "kiro" ]
}

# ── agent_capabilities ────────────────────────────────────────────────────────

@test "kiro agent_capabilities outputs valid JSON" {
  run bash -c "source '$LIB_DIR/agent/adapter-kiro.sh' && agent_capabilities | jq empty"
  [ "$status" -eq 0 ]
}

@test "kiro agent_capabilities agent field is 'kiro'" {
  local cap agent_field
  cap=$(agent_capabilities)
  agent_field=$(echo "$cap" | jq -r '.agent')
  [ "$agent_field" = "kiro" ]
}

@test "kiro agent_capabilities has 'autonomous' approval mode" {
  local cap
  cap=$(agent_capabilities)
  echo "$cap" | jq -e '.supports.approval_modes | index("autonomous")' >/dev/null
}

# ── agent_doctor ─────────────────────────────────────────────────────────────

@test "kiro agent_doctor: fails when kiro binary not in PATH" {
  run bash -c "
    source '$LIB_DIR/agent/adapter-kiro.sh'
    PATH=/dev/null agent_doctor
  "
  [ "$status" -ne 0 ]
}

@test "kiro agent_doctor: fails when AWS credentials not configured" {
  local mock_dir
  mock_dir="$(mktemp -d)"
  printf '#!/bin/bash\nexit 0\n' > "$mock_dir/kiro"
  # aws returns failure
  printf '#!/bin/bash\nexit 1\n' > "$mock_dir/aws"
  chmod +x "$mock_dir/kiro" "$mock_dir/aws"
  run bash -c "
    source '$LIB_DIR/agent/adapter-kiro.sh'
    PATH='$mock_dir' agent_doctor 2>&1
  "
  rm -rf "$mock_dir"
  [ "$status" -ne 0 ]
  [[ "$output" == *"AWS"* ]] || [[ "$output" == *"credentials"* ]]
}

@test "kiro agent_doctor: succeeds when kiro found and AWS credentials valid" {
  local mock_dir
  mock_dir="$(mktemp -d)"
  printf '#!/bin/bash\nexit 0\n' > "$mock_dir/kiro"
  printf '#!/bin/bash\necho '"'"'{"UserId":"AIDA...","Account":"123","Arn":"arn:aws..."}'"'"'\nexit 0\n' > "$mock_dir/aws"
  chmod +x "$mock_dir/kiro" "$mock_dir/aws"
  run bash -c "
    source '$LIB_DIR/agent/adapter-kiro.sh'
    PATH='$mock_dir' agent_doctor
  "
  rm -rf "$mock_dir"
  [ "$status" -eq 0 ]
}

# ── phase switch: native specs vs agent run ───────────────────────────────────

_kiro_run_phase_test() {
  local phase="$1" native_specs="$2" expected="$3"
  local mock_dir tmp_script
  mock_dir="$(mktemp -d)"
  tmp_script="$(mktemp /tmp/mz_kiro_XXXXXX.sh)"
  printf '#!/bin/bash\necho "kiro_args: $*"\nexit 0\n' > "$mock_dir/kiro"
  chmod +x "$mock_dir/kiro"
  cat > "$tmp_script" <<SCRIPT
#!/bin/bash
export PATH="$mock_dir:\$PATH"
source "$LIB_DIR/agent/adapter-kiro.sh"
MONOZUKURI_FEATURE_ID="feat-001"
MONOZUKURI_WORKTREE="$mock_dir"
MONOZUKURI_AUTONOMY="checkpoint"
MONOZUKURI_PHASE="$phase"
KIRO_USE_NATIVE_SPECS="$native_specs"
MONOZUKURI_LOG_FILE="/tmp/mz-kiro-test-\$\$.log"
agent_run_phase 2>&1
SCRIPT
  chmod +x "$tmp_script"
  run bash "$tmp_script"
  rm -rf "$mock_dir" "$tmp_script"
  [[ "$output" == *"$expected"* ]]
}

@test "kiro agent_run_phase uses 'spec create' for prd when use_native_specs=true" {
  _kiro_run_phase_test "prd" "true" "spec create"
}

@test "kiro agent_run_phase uses 'spec create' for techspec when use_native_specs=true" {
  _kiro_run_phase_test "techspec" "true" "spec create"
}

@test "kiro agent_run_phase uses 'agent run' for code phase" {
  _kiro_run_phase_test "code" "true" "agent run"
}

@test "kiro agent_run_phase uses 'agent run' when use_native_specs=false" {
  _kiro_run_phase_test "prd" "false" "agent run"
}

# ── agent_estimate_tokens / agent_report_cost ────────────────────────────────

@test "kiro agent_estimate_tokens returns positive integer" {
  local tokens
  tokens=$(printf 'Hello kiro prompt' | agent_estimate_tokens)
  [ "$tokens" -gt 0 ]
}

@test "kiro agent_report_cost returns numeric value" {
  unset -f cost_report 2>/dev/null || true
  local cost
  cost=$(agent_report_cost)
  [[ "$cost" =~ ^[0-9]+(\.[0-9]+)?$ ]]
}
