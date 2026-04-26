#!/usr/bin/env bats
# test/unit/lib_agent_gemini.bats — unit tests for lib/agent/adapter-gemini.sh

setup() {
  REPO_ROOT="$(cd "$(dirname "$BATS_TEST_FILENAME")/../.." && pwd)"
  LIB_DIR="$REPO_ROOT/lib"
  export LIB_DIR
  source "$LIB_DIR/agent/contract.sh"
  source "$LIB_DIR/agent/adapter-gemini.sh"
}

# ── agent_name ───────────────────────────────────────────────────────────────

@test "gemini agent_name returns 'gemini'" {
  run agent_name
  [ "$status" -eq 0 ]
  [ "$output" = "gemini" ]
}

# ── agent_capabilities ────────────────────────────────────────────────────────

@test "gemini agent_capabilities outputs valid JSON" {
  run bash -c "source '$LIB_DIR/agent/adapter-gemini.sh' && agent_capabilities | jq empty"
  [ "$status" -eq 0 ]
}

@test "gemini agent_capabilities agent field is 'gemini'" {
  local cap agent_field
  cap=$(agent_capabilities)
  agent_field=$(echo "$cap" | jq -r '.agent')
  [ "$agent_field" = "gemini" ]
}

@test "gemini agent_capabilities has 'yolo' approval mode" {
  local cap
  cap=$(agent_capabilities)
  echo "$cap" | jq -e '.supports.approval_modes | index("yolo")' >/dev/null
}

# ── agent_doctor ─────────────────────────────────────────────────────────────

@test "gemini agent_doctor: fails when gemini binary not in PATH" {
  run bash -c "
    source '$LIB_DIR/agent/adapter-gemini.sh'
    PATH=/dev/null agent_doctor
  "
  [ "$status" -ne 0 ]
}

@test "gemini agent_doctor: fails when no auth (no key, no ADC file)" {
  local mock_dir
  mock_dir="$(mktemp -d)"
  printf '#!/bin/bash\nexit 0\n' > "$mock_dir/gemini"
  chmod +x "$mock_dir/gemini"
  run bash -c "
    source '$LIB_DIR/agent/adapter-gemini.sh'
    unset GEMINI_API_KEY
    HOME='$mock_dir'
    PATH='$mock_dir' agent_doctor 2>&1
  "
  rm -rf "$mock_dir"
  [ "$status" -ne 0 ]
  [[ "$output" == *"GEMINI_API_KEY"* ]] || [[ "$output" == *"auth"* ]]
}

@test "gemini agent_doctor: succeeds with GEMINI_API_KEY set" {
  local mock_dir
  mock_dir="$(mktemp -d)"
  printf '#!/bin/bash\nexit 0\n' > "$mock_dir/gemini"
  chmod +x "$mock_dir/gemini"
  run bash -c "
    source '$LIB_DIR/agent/adapter-gemini.sh'
    GEMINI_API_KEY='test-key' PATH='$mock_dir' agent_doctor
  "
  rm -rf "$mock_dir"
  [ "$status" -eq 0 ]
}

@test "gemini agent_doctor: succeeds with ADC credentials file" {
  local mock_dir home_dir
  mock_dir="$(mktemp -d)"
  home_dir="$(mktemp -d)"
  mkdir -p "$home_dir/.config/gcloud"
  echo '{"type":"authorized_user"}' > "$home_dir/.config/gcloud/application_default_credentials.json"
  printf '#!/bin/bash\nexit 0\n' > "$mock_dir/gemini"
  chmod +x "$mock_dir/gemini"
  run bash -c "
    source '$LIB_DIR/agent/adapter-gemini.sh'
    unset GEMINI_API_KEY
    HOME='$home_dir' PATH='$mock_dir' agent_doctor
  "
  rm -rf "$mock_dir" "$home_dir"
  [ "$status" -eq 0 ]
}

# ── autonomy → --yolo mapping ─────────────────────────────────────────────────

@test "gemini agent_run_phase uses '--yolo true' for full_auto" {
  local mock_dir tmp_script
  mock_dir="$(mktemp -d)"
  tmp_script="$(mktemp /tmp/mz_gemini_XXXXXX.sh)"
  printf '#!/bin/bash\necho "gemini_args: $*"\nexit 0\n' > "$mock_dir/gemini"
  chmod +x "$mock_dir/gemini"
  cat > "$tmp_script" <<SCRIPT
#!/bin/bash
export PATH="$mock_dir:\$PATH"
source "$LIB_DIR/agent/adapter-gemini.sh"
MONOZUKURI_FEATURE_ID="feat-001"
MONOZUKURI_WORKTREE="$mock_dir"
MONOZUKURI_AUTONOMY="full_auto"
MONOZUKURI_LOG_FILE="/tmp/mz-gemini-test-\$\$.log"
agent_run_phase 2>&1
SCRIPT
  chmod +x "$tmp_script"
  run bash "$tmp_script"
  rm -rf "$mock_dir" "$tmp_script"
  [[ "$output" == *"--yolo true"* ]]
}

@test "gemini agent_run_phase uses '--yolo false' for checkpoint" {
  local mock_dir tmp_script
  mock_dir="$(mktemp -d)"
  tmp_script="$(mktemp /tmp/mz_gemini_XXXXXX.sh)"
  printf '#!/bin/bash\necho "gemini_args: $*"\nexit 0\n' > "$mock_dir/gemini"
  chmod +x "$mock_dir/gemini"
  cat > "$tmp_script" <<SCRIPT
#!/bin/bash
export PATH="$mock_dir:\$PATH"
source "$LIB_DIR/agent/adapter-gemini.sh"
MONOZUKURI_FEATURE_ID="feat-001"
MONOZUKURI_WORKTREE="$mock_dir"
MONOZUKURI_AUTONOMY="checkpoint"
MONOZUKURI_LOG_FILE="/tmp/mz-gemini-test-\$\$.log"
agent_run_phase 2>&1
SCRIPT
  chmod +x "$tmp_script"
  run bash "$tmp_script"
  rm -rf "$mock_dir" "$tmp_script"
  [[ "$output" == *"--yolo false"* ]]
}

# ── agent_estimate_tokens / agent_report_cost ────────────────────────────────

@test "gemini agent_estimate_tokens returns positive integer" {
  local tokens
  tokens=$(printf 'Hello gemini prompt' | agent_estimate_tokens)
  [ "$tokens" -gt 0 ]
}

@test "gemini agent_report_cost returns numeric value" {
  unset -f cost_report 2>/dev/null || true
  local cost
  cost=$(agent_report_cost)
  [[ "$cost" =~ ^[0-9]+(\.[0-9]+)?$ ]]
}
