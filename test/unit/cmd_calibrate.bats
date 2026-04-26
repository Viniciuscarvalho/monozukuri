#!/usr/bin/env bats
# test/unit/cmd_calibrate.bats — Unit tests for calibrate command (Gap 8)

setup() {
  REPO_ROOT="$(cd "$(dirname "$BATS_TEST_FILENAME")/../.." && pwd)"
  export LIB_DIR="$REPO_ROOT/lib"
  export CMD_DIR="$REPO_ROOT/cmd"
  export SCRIPT_DIR="$REPO_ROOT"
  export PROJECT_ROOT="$REPO_ROOT"

  TMPDIR_TEST="$(mktemp -d)"
  export STATE_DIR="$TMPDIR_TEST/state"
  mkdir -p "$STATE_DIR"

  # Source pricing and calibrate modules
  source "$LIB_DIR/core/pricing.sh"
  source "$LIB_DIR/run/calibrate.sh"
}

teardown() {
  rm -rf "$TMPDIR_TEST"
}

# ── Helper ────────────────────────────────────────────────────────────

make_cost_json() {
  local feat_id="$1"
  local phase="$2"
  local estimated="$3"
  local actual="$4"

  local dir="$STATE_DIR/$feat_id"
  mkdir -p "$dir"
  node -e "
    const fs = require('fs');
    fs.writeFileSync('$dir/cost.json', JSON.stringify({
      feature_id: '$feat_id',
      phases: [{
        phase: '$phase',
        estimated_tokens: $estimated,
        actual_tokens: $actual,
        estimated_usd: 0.05,
        recorded_at: new Date().toISOString()
      }],
      cumulative_tokens: $estimated
    }, null, 2));
  "
}

# ── Tests ─────────────────────────────────────────────────────────────

@test "calibrate_run warns when fewer than 5 features" {
  # Create only 3 features
  for i in 1 2 3; do
    make_cost_json "feat-00$i" "code" 10000 8500
  done

  run calibrate_run 20
  [ "$status" -eq 0 ]
  [[ "$output" == *"Insufficient data"* ]]
}

@test "calibrate_run reports 0 features found for empty state dir" {
  run calibrate_run 20
  [ "$status" -eq 0 ]
  [[ "$output" == *"Insufficient data"* ]]
}

@test "calibrate_run proceeds with 5 or more features" {
  for i in 1 2 3 4 5; do
    make_cost_json "feat-00$i" "code" 12000 10000
  done

  run calibrate_run 20
  [ "$status" -eq 0 ]
  [[ "$output" == *"Calibration Report"* ]]
}

@test "calibrate_run displays phase table headers" {
  for i in $(seq 1 5); do
    make_cost_json "feat-$(printf '%03d' $i)" "code" 12000 11000
  done

  run calibrate_run 20
  [ "$status" -eq 0 ]
  [[ "$output" == *"Phase"* ]]
  [[ "$output" == *"Est tokens"* ]]
  [[ "$output" == *"Ratio"* ]]
  [[ "$output" == *"Guidance"* ]]
}

@test "calibrate_run shows ratio above 1.1 as raise baseline" {
  # actual > estimated by more than 10%
  for i in $(seq 1 5); do
    make_cost_json "feat-$(printf '%03d' $i)" "code" 10000 12000
  done

  run calibrate_run 20
  [ "$status" -eq 0 ]
  [[ "$output" == *"raise baseline"* ]]
}

@test "calibrate_run shows ratio below 0.9 as reduce baseline" {
  # actual < estimated by more than 10%
  for i in $(seq 1 5); do
    make_cost_json "feat-$(printf '%03d' $i)" "code" 10000 8000
  done

  run calibrate_run 20
  [ "$status" -eq 0 ]
  [[ "$output" == *"reduce baseline"* ]]
}

@test "calibrate_run shows accurate baseline for ratio near 1.0" {
  # actual ≈ estimated (within 10%)
  for i in $(seq 1 5); do
    make_cost_json "feat-$(printf '%03d' $i)" "code" 10000 10000
  done

  run calibrate_run 20
  [ "$status" -eq 0 ]
  [[ "$output" == *"baseline accurate"* ]]
}

@test "calibrate_run respects --sample size" {
  # Create 10 features
  for i in $(seq 1 10); do
    make_cost_json "feat-$(printf '%03d' $i)" "code" 10000 9000
  done

  # With sample=3, should warn insufficient data
  run calibrate_run 3
  [ "$status" -eq 0 ]
  [[ "$output" == *"Insufficient data"* ]]
}

@test "calibrate_run warns when no actual_tokens present" {
  # Create features with no actual_tokens (null)
  for i in $(seq 1 6); do
    local dir="$STATE_DIR/feat-$(printf '%03d' $i)"
    mkdir -p "$dir"
    node -e "
      const fs = require('fs');
      fs.writeFileSync('$dir/cost.json', JSON.stringify({
        feature_id: 'feat-$(printf '%03d' $i)',
        phases: [{ phase: 'code', estimated_tokens: 10000, actual_tokens: null }],
        cumulative_tokens: 10000
      }, null, 2));
    "
  done

  run calibrate_run 20
  [ "$status" -eq 0 ]
  [[ "$output" == *"No actual token data"* ]]
}
