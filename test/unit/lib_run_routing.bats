#!/usr/bin/env bats
# test/unit/lib_run_routing.bats — unit tests for lib/run/routing.sh

setup() {
  REPO_ROOT="$(cd "$(dirname "$BATS_TEST_FILENAME")/../.." && pwd)"
  LIB_DIR="$REPO_ROOT/lib"
  export LIB_DIR

  TMPDIR_TEST="$(mktemp -d)"
  STATE_DIR="$TMPDIR_TEST/state"
  ROOT_DIR="$TMPDIR_TEST"
  ROUTING_DATA_DIR="$STATE_DIR/routing-data"
  export STATE_DIR ROOT_DIR ROUTING_DATA_DIR

  mkdir -p "$STATE_DIR"
  mkdir -p "$TMPDIR_TEST/.monozukuri"

  # Unset any phase adapter vars left from previous tests
  unset $(compgen -v | grep '^PHASE_ADAPTER_') 2>/dev/null || true
  unset ROUTING_FAILOVER MONOZUKURI_AGENT 2>/dev/null || true

  source "$LIB_DIR/run/routing.sh"
}

teardown() {
  rm -rf "$TMPDIR_TEST"
  unset $(compgen -v | grep '^PHASE_ADAPTER_') 2>/dev/null || true
  unset ROUTING_FAILOVER 2>/dev/null || true
}

# ── routing_load ──────────────────────────────────────────────────────────────

@test "routing_load: no routing.yaml — exports nothing, returns 0" {
  routing_load "$TMPDIR_TEST"
  run bash -c 'compgen -v | grep PHASE_ADAPTER'
  [ "$status" -ne 0 ]
}

@test "routing_load: project-level routing.yaml — exports PHASE_ADAPTER_* vars" {
  cat > "$TMPDIR_TEST/.monozukuri/routing.yaml" <<'EOF'
phases:
  prd: claude-code
  code: aider
failover: false
EOF
  routing_load "$TMPDIR_TEST"
  [ "${PHASE_ADAPTER_PRD:-}" = "claude-code" ]
  [ "${PHASE_ADAPTER_CODE:-}" = "aider" ]
  [ "${ROUTING_FAILOVER:-}" = "false" ]
}

@test "routing_load: project overrides user-level routing.yaml" {
  local user_cfg_dir="$TMPDIR_TEST/user-config/monozukuri"
  mkdir -p "$user_cfg_dir"
  cat > "$user_cfg_dir/routing.yaml" <<'EOF'
phases:
  code: claude-code
EOF
  cat > "$TMPDIR_TEST/.monozukuri/routing.yaml" <<'EOF'
phases:
  code: aider
EOF
  XDG_CONFIG_HOME="$TMPDIR_TEST/user-config" routing_load "$TMPDIR_TEST"
  [ "${PHASE_ADAPTER_CODE:-}" = "aider" ]
}

@test "routing_load: user-level only — sets vars without project file" {
  local user_cfg_dir="$TMPDIR_TEST/user-config/monozukuri"
  mkdir -p "$user_cfg_dir"
  cat > "$user_cfg_dir/routing.yaml" <<'EOF'
phases:
  prd: gemini
EOF
  XDG_CONFIG_HOME="$TMPDIR_TEST/user-config" routing_load "$TMPDIR_TEST"
  [ "${PHASE_ADAPTER_PRD:-}" = "gemini" ]
}

@test "routing_load: inline comments are stripped" {
  cat > "$TMPDIR_TEST/.monozukuri/routing.yaml" <<'EOF'
phases:
  code: aider # override for this project
failover: false # cross-agent failover
EOF
  routing_load "$TMPDIR_TEST"
  [ "${PHASE_ADAPTER_CODE:-}" = "aider" ]
  [ "${ROUTING_FAILOVER:-}" = "false" ]
}

@test "routing_load: failover: true is parsed correctly" {
  cat > "$TMPDIR_TEST/.monozukuri/routing.yaml" <<'EOF'
phases:
  prd: claude-code
failover: true
EOF
  routing_load "$TMPDIR_TEST"
  [ "${ROUTING_FAILOVER:-}" = "true" ]
}

# ── routing_adapter_for_phase ─────────────────────────────────────────────────

@test "routing_adapter_for_phase: returns PHASE_ADAPTER_<PHASE> when set" {
  export PHASE_ADAPTER_CODE="aider"
  result="$(routing_adapter_for_phase "code")"
  [ "$result" = "aider" ]
}

@test "routing_adapter_for_phase: falls back to MONOZUKURI_AGENT when not set" {
  unset PHASE_ADAPTER_CODE 2>/dev/null || true
  MONOZUKURI_AGENT="gemini" result="$(routing_adapter_for_phase "code")"
  [ "$result" = "gemini" ]
}

@test "routing_adapter_for_phase: default fallback is claude-code" {
  unset PHASE_ADAPTER_PRD MONOZUKURI_AGENT 2>/dev/null || true
  result="$(routing_adapter_for_phase "prd")"
  [ "$result" = "claude-code" ]
}

@test "routing_adapter_for_phase: phase name is case-insensitive to env var" {
  export PHASE_ADAPTER_TECHSPEC="aider"
  result="$(routing_adapter_for_phase "techspec")"
  [ "$result" = "aider" ]
}

# ── routing_record_run ────────────────────────────────────────────────────────

@test "routing_record_run: creates JSONL file with correct fields" {
  routing_record_run "claude-code" "code" 1 "0.05"
  local jsonl="$ROUTING_DATA_DIR/claude-code/code.jsonl"
  [ -f "$jsonl" ]
  grep -q '"adapter":"claude-code"' "$jsonl"
  grep -q '"phase":"code"' "$jsonl"
  grep -q '"ci_pass":1' "$jsonl"
  grep -q '"cost_usd":0.05' "$jsonl"
}

@test "routing_record_run: appends multiple records" {
  routing_record_run "aider" "code" 1 "0.10"
  routing_record_run "aider" "code" 0 "0.08"
  local jsonl="$ROUTING_DATA_DIR/aider/code.jsonl"
  local count
  count="$(grep -c '' "$jsonl")"
  [ "$count" -eq 2 ]
}

@test "routing_record_run: creates separate files per adapter and phase" {
  routing_record_run "claude-code" "prd"  1 "0.02"
  routing_record_run "aider"       "code" 1 "0.07"
  [ -f "$ROUTING_DATA_DIR/claude-code/prd.jsonl" ]
  [ -f "$ROUTING_DATA_DIR/aider/code.jsonl" ]
}

@test "routing_record_run: cost_usd defaults to 0 when omitted" {
  routing_record_run "claude-code" "tests" 1
  local jsonl="$ROUTING_DATA_DIR/claude-code/tests.jsonl"
  grep -q '"cost_usd":0' "$jsonl"
}
