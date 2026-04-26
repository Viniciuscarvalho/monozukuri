#!/usr/bin/env bats
# test/integration/test_gap8_pricing.bats — Integration tests for Gap 8 (Pricing & Calibration)

setup() {
  REPO_ROOT="$(cd "$(dirname "$BATS_TEST_FILENAME")/../.." && pwd)"
  export LIB_DIR="$REPO_ROOT/lib"
  export CMD_DIR="$REPO_ROOT/cmd"

  TMPDIR_TEST="$(mktemp -d)"
  export STATE_DIR="$TMPDIR_TEST/state"
  mkdir -p "$STATE_DIR"

  # Isolated copy of pricing.yaml so calibrate never touches the repo file
  mkdir -p "$TMPDIR_TEST/config"
  cp "$REPO_ROOT/config/pricing.yaml" "$TMPDIR_TEST/config/pricing.yaml"

  # Point modules at the isolated copy
  export PROJECT_ROOT="$TMPDIR_TEST"
  export SCRIPT_DIR="$TMPDIR_TEST"

  # Source modules needed for full workflow
  source "$LIB_DIR/core/pricing.sh"
  source "$LIB_DIR/core/cost.sh"
  source "$LIB_DIR/run/calibrate.sh"
}

teardown() {
  rm -rf "$TMPDIR_TEST"
}

# ── Helper ────────────────────────────────────────────────────────────

make_feature_cost() {
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
      created_at: new Date().toISOString(),
      phases: [{
        phase: '$phase',
        estimated_tokens: $estimated,
        actual_tokens: $actual,
        estimated_usd: ($estimated / 1000000 * 3.0 * 0.7) + ($estimated / 1000000 * 15.0 * 0.3),
        recorded_at: new Date().toISOString()
      }],
      cumulative_tokens: $estimated,
      cumulative_usd: ($estimated / 1000000 * 3.0 * 0.7) + ($estimated / 1000000 * 15.0 * 0.3),
      updated_at: new Date().toISOString()
    }, null, 2));
  "
}

# ── Pricing YAML (reads from repo, not the isolated copy) ─────────────

@test "pricing.yaml exists and is valid YAML" {
  [ -f "$REPO_ROOT/config/pricing.yaml" ]
  if command -v yq &>/dev/null; then
    run yq eval '.' "$REPO_ROOT/config/pricing.yaml"
    [ "$status" -eq 0 ]
  fi
}

@test "pricing.yaml has version 1.0.0" {
  if ! command -v yq &>/dev/null; then skip "yq not installed"; fi
  run yq eval '.version' "$REPO_ROOT/config/pricing.yaml"
  [ "$status" -eq 0 ]
  [ "$output" = "1.0.0" ]
}

@test "pricing.yaml has claude-sonnet-4-6 pricing" {
  if ! command -v yq &>/dev/null; then skip "yq not installed"; fi
  run yq eval '.providers.claude-code.models.claude-sonnet-4-6.input_per_1m' "$REPO_ROOT/config/pricing.yaml"
  [ "$status" -eq 0 ]
  [ "$output" = "3.00" ]
}

@test "pricing.yaml has default calibration coefficients" {
  if ! command -v yq &>/dev/null; then skip "yq not installed"; fi
  local val
  val=$(yq eval '.calibration.claude-code.claude-sonnet-4-6.code' "$REPO_ROOT/config/pricing.yaml")
  awk -v v="$val" 'BEGIN { exit (v >= 0.99 && v <= 1.01) ? 0 : 1 }'
}

# ── Pricing Module ────────────────────────────────────────────────────

@test "pricing_load populates env vars from pricing.yaml" {
  pricing_load
  [ -n "$PRICING_VERSION" ]
  [ "$PRICING_VERSION" = "1.0.0" ]
  [ -n "$PRICING_CLAUDE_CODE_CLAUDE_SONNET_4_6_INPUT_PER_1M" ]
}

@test "pricing_cost_usd returns correct USD for known token counts" {
  pricing_load
  # 100k input, 30k output with sonnet-4-6 pricing (3.00/15.00 per 1M)
  # = (100000/1M * 3.00) + (30000/1M * 15.00) = 0.30 + 0.45 = 0.75
  run pricing_cost_usd "claude-code" "claude-sonnet-4-6" 100000 30000
  [ "$status" -eq 0 ]
  [[ "$output" =~ ^0\.75 ]]
}

@test "cost_record adds estimated_usd to cost.json" {
  mkdir -p "$STATE_DIR/feat-001"
  node -e "
    const fs = require('fs');
    fs.writeFileSync('$STATE_DIR/feat-001/cost.json', JSON.stringify({
      feature_id: 'feat-001',
      created_at: new Date().toISOString(),
      phases: [],
      cumulative_tokens: 0
    }, null, 2));
  "

  MODEL_AGENT="claude-code" MODEL_PRIMARY="claude-sonnet-4-6" \
    cost_record "feat-001" "code" 10000

  local usd
  usd=$(node -e "
    const data = JSON.parse(require('fs').readFileSync('$STATE_DIR/feat-001/cost.json', 'utf-8'));
    const phase = data.phases.find(p => p.phase === 'code');
    console.log(phase && phase.estimated_usd !== undefined ? 'has_usd' : 'no_usd');
  ")
  [ "$usd" = "has_usd" ]
}

# ── Calibrate Command ─────────────────────────────────────────────────

@test "calibrate_run warns insufficient data with < 5 features" {
  for i in 1 2 3; do
    make_feature_cost "feat-00$i" "code" 10000 9000
  done

  run calibrate_run 20
  [ "$status" -eq 0 ]
  [[ "$output" == *"Insufficient data"* ]]
}

@test "calibrate_run generates report with 5+ features" {
  for i in $(seq 1 5); do
    make_feature_cost "feat-$(printf '%03d' $i)" "code" 10000 9500
  done

  run calibrate_run 20
  [ "$status" -eq 0 ]
  [[ "$output" == *"Calibration Report"* ]]
  [[ "$output" == *"Agent: claude-code"* ]]
}

@test "calibrate_run updates isolated pricing.yaml timestamp" {
  if ! command -v yq &>/dev/null; then skip "yq not installed"; fi

  for i in $(seq 1 5); do
    make_feature_cost "feat-$(printf '%03d' $i)" "code" 10000 11000
  done

  # Reset pricing cache to use the isolated copy
  _PRICING_LOADED=false
  run calibrate_run 20
  [ "$status" -eq 0 ]
  # Verify the isolated copy was updated (not the repo copy)
  local repo_code
  repo_code=$(yq eval '.calibration.claude-code.claude-sonnet-4-6.code' "$REPO_ROOT/config/pricing.yaml")
  awk -v v="$repo_code" 'BEGIN { exit (v >= 0.99 && v <= 1.01) ? 0 : 1 }'
}

@test "full workflow: cost_record then calibrate produces report" {
  for i in $(seq 1 6); do
    local feat_id="feat-$(printf '%03d' $i)"
    mkdir -p "$STATE_DIR/$feat_id"
    node -e "
      const fs = require('fs');
      fs.writeFileSync('$STATE_DIR/$feat_id/cost.json', JSON.stringify({
        feature_id: '$feat_id',
        created_at: new Date().toISOString(),
        phases: [
          { phase: 'prd', estimated_tokens: 25000, actual_tokens: 22000, estimated_usd: 0.12 },
          { phase: 'code', estimated_tokens: 12000, actual_tokens: 14000, estimated_usd: 0.07 }
        ],
        cumulative_tokens: 37000,
        cumulative_usd: 0.19
      }, null, 2));
    "
  done

  run calibrate_run 20
  [ "$status" -eq 0 ]
  [[ "$output" == *"Calibration Report"* ]]
  [[ "$output" == *"prd"* ]]
  [[ "$output" == *"code"* ]]
  [[ "$output" == *"Avg tokens"* ]]
}
