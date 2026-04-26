#!/usr/bin/env bats
# test/unit/cmd_routing.bats — unit tests for cmd/routing.sh routing suggest

setup() {
  REPO_ROOT="$(cd "$(dirname "$BATS_TEST_FILENAME")/../.." && pwd)"
  LIB_DIR="$REPO_ROOT/lib"
  CMD_DIR="$REPO_ROOT/cmd"
  export LIB_DIR CMD_DIR

  TMPDIR_TEST="$(mktemp -d)"
  STATE_DIR="$TMPDIR_TEST/state"
  CONFIG_DIR="$TMPDIR_TEST/.monozukuri"
  ROOT_DIR="$TMPDIR_TEST"
  export STATE_DIR CONFIG_DIR ROOT_DIR

  mkdir -p "$STATE_DIR"

  # Minimal stubs for module system
  source "$LIB_DIR/core/modules.sh"
  modules_init "$LIB_DIR"
  module_require core/util
  module_require cli/output

  # Source cmd/routing.sh directly (bypassing sub_routing's module re-load)
  source "$CMD_DIR/routing.sh"
}

teardown() {
  rm -rf "$TMPDIR_TEST"
}

_seed_runs() {
  local adapter="$1" phase="$2" count="${3:-4}" ci_pass="${4:-1}" cost="${5:-0.05}"
  local data_dir="$STATE_DIR/routing-data/$adapter"
  mkdir -p "$data_dir"
  local i
  for (( i=0; i<count; i++ )); do
    printf '{"adapter":"%s","phase":"%s","ci_pass":%s,"cost_usd":%s,"ts":"2026-04-26T00:00:00Z"}\n' \
      "$adapter" "$phase" "$ci_pass" "$cost" >> "$data_dir/${phase}.jsonl"
  done
}

# ── no data ───────────────────────────────────────────────────────────────────

@test "routing suggest: no data root — prints no-data message" {
  run _routing_sub_suggest "" "$STATE_DIR/routing-data"
  [ "$status" -eq 0 ]
  [[ "$output" == *"no routing data"* ]]
}

@test "routing suggest: empty data root — prints no-data message" {
  mkdir -p "$STATE_DIR/routing-data"
  run _routing_sub_suggest "" "$STATE_DIR/routing-data"
  [ "$status" -eq 0 ]
  [[ "$output" == *"no routing data"* ]]
}

# ── threshold check ───────────────────────────────────────────────────────────

@test "routing suggest: below threshold — prints insufficient-data message" {
  _seed_runs "claude-code" "code" 2
  _seed_runs "aider"       "code" 1
  run _routing_sub_suggest "code" "$STATE_DIR/routing-data"
  [ "$status" -eq 0 ]
  [[ "$output" == *"insufficient data"* ]]
  [[ "$output" == *"need ≥ 4"* ]]
}

@test "routing suggest: one adapter below threshold, one above — still insufficient" {
  _seed_runs "claude-code" "prd" 4
  _seed_runs "aider"       "prd" 2
  run _routing_sub_suggest "prd" "$STATE_DIR/routing-data"
  [ "$status" -eq 0 ]
  [[ "$output" == *"insufficient data"* ]]
}

# ── recommendation ────────────────────────────────────────────────────────────

@test "routing suggest: both adapters at threshold — emits recommendation" {
  _seed_runs "claude-code" "code" 4 1 "0.04"
  _seed_runs "aider"       "code" 4 1 "0.08"
  run _routing_sub_suggest "code" "$STATE_DIR/routing-data"
  [ "$status" -eq 0 ]
  [[ "$output" == *"recommendation:"* ]]
}

@test "routing suggest: higher ci_pass_rate wins over lower" {
  # claude-code: 4/4 ci pass (100%), aider: 2/4 ci pass (50%)
  _seed_runs "claude-code" "tests" 4 1 "0.05"
  _seed_runs "aider"       "tests" 2 1 "0.05"
  _seed_runs "aider"       "tests" 2 0 "0.05"
  run _routing_sub_suggest "tests" "$STATE_DIR/routing-data"
  [ "$status" -eq 0 ]
  [[ "$output" == *"recommendation: claude-code"* ]]
}

@test "routing suggest: lower cost wins when ci_pass_rate is equal" {
  # Both 100% ci pass; aider is cheaper
  _seed_runs "claude-code" "pr" 4 1 "0.20"
  _seed_runs "aider"       "pr" 4 1 "0.02"
  run _routing_sub_suggest "pr" "$STATE_DIR/routing-data"
  [ "$status" -eq 0 ]
  [[ "$output" == *"recommendation: aider"* ]]
}

@test "routing suggest: recommendation includes routing.yaml snippet" {
  _seed_runs "claude-code" "techspec" 4 1 "0.03"
  _seed_runs "aider"       "techspec" 4 0 "0.03"
  run _routing_sub_suggest "techspec" "$STATE_DIR/routing-data"
  [ "$status" -eq 0 ]
  [[ "$output" == *"techspec: claude-code"* ]]
}

# ── phase filter ──────────────────────────────────────────────────────────────

@test "routing suggest: phase filter limits output to that phase" {
  _seed_runs "claude-code" "prd"  4 1 "0.02"
  _seed_runs "claude-code" "code" 4 1 "0.05"
  _seed_runs "aider"       "prd"  4 1 "0.03"
  _seed_runs "aider"       "code" 4 1 "0.06"
  run _routing_sub_suggest "prd" "$STATE_DIR/routing-data"
  [ "$status" -eq 0 ]
  [[ "$output" == *"── Phase: prd ──"* ]]
  [[ "$output" != *"── Phase: code ──"* ]]
}

@test "routing suggest: no phase filter covers all phases with data" {
  _seed_runs "claude-code" "prd"  4 1 "0.02"
  _seed_runs "aider"       "prd"  4 1 "0.03"
  _seed_runs "claude-code" "code" 4 1 "0.05"
  _seed_runs "aider"       "code" 4 1 "0.06"
  run _routing_sub_suggest "" "$STATE_DIR/routing-data"
  [ "$status" -eq 0 ]
  [[ "$output" == *"── Phase: prd ──"* ]]
  [[ "$output" == *"── Phase: code ──"* ]]
}
