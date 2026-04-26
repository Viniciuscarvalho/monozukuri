#!/usr/bin/env bats
# test/unit/lib_core_pricing.bats — Unit tests for lib/core/pricing.sh (Gap 8)

setup() {
  export PROJECT_ROOT="$BATS_TEST_DIRNAME/../.."
  export SCRIPT_DIR="$PROJECT_ROOT"

  # Source the pricing module
  source "$PROJECT_ROOT/lib/core/pricing.sh"
}

@test "pricing_load reads pricing.yaml" {
  pricing_load

  # Verify version loaded
  [ -n "$PRICING_VERSION" ]
  [ "$PRICING_VERSION" = "1.0.0" ]
}

@test "pricing_load populates env vars for claude-code models" {
  pricing_load

  # Check claude-sonnet-4-6 pricing
  [ -n "$PRICING_CLAUDE_CODE_CLAUDE_SONNET_4_6_INPUT_PER_1M" ]
  [ "$PRICING_CLAUDE_CODE_CLAUDE_SONNET_4_6_INPUT_PER_1M" = "3.00" ]
  [ "$PRICING_CLAUDE_CODE_CLAUDE_SONNET_4_6_OUTPUT_PER_1M" = "15.00" ]
}

@test "pricing_load populates calibration coefficients" {
  pricing_load

  # Check default calibration (1.0)
  [ -n "$CALIBRATION_CLAUDE_CODE_CLAUDE_SONNET_4_6_PRD" ]
  [ "$CALIBRATION_CLAUDE_CODE_CLAUDE_SONNET_4_6_PRD" = "1.0" ]
}

@test "pricing_cost_usd calculates USD correctly for claude-sonnet-4-6" {
  pricing_load

  # Test: 100k input tokens, 30k output tokens
  # Cost = (100000 / 1M * 3.00) + (30000 / 1M * 15.00)
  #      = 0.30 + 0.45 = 0.75
  local cost
  cost=$(pricing_cost_usd "claude-code" "claude-sonnet-4-6" 100000 30000)

  # Check result (allowing for floating point precision)
  [[ "$cost" =~ ^0\.75 ]]
}

@test "pricing_cost_usd splits 70/30 for token-only estimates" {
  pricing_load

  # Test: 100k total tokens (no output specified)
  # Split: 70k input, 30k output
  # Cost = (70000 / 1M * 3.00) + (30000 / 1M * 15.00)
  #      = 0.21 + 0.45 = 0.66
  local cost
  cost=$(pricing_cost_usd "claude-code" "claude-sonnet-4-6" 100000 "")

  # Check result
  [[ "$cost" =~ ^0\.66 ]]
}

@test "pricing_calibration_factor returns default 1.0" {
  pricing_load

  local factor
  factor=$(pricing_calibration_factor "claude-code" "claude-sonnet-4-6" "prd")

  [ "$factor" = "1.0" ]
}

@test "pricing_calibration_factor returns 1.0 for unknown combinations" {
  pricing_load

  local factor
  factor=$(pricing_calibration_factor "unknown-agent" "unknown-model" "unknown-phase")

  [ "$factor" = "1.0" ]
}

@test "pricing_cost_usd handles missing pricing gracefully" {
  pricing_load

  # Test with unknown agent/model
  local cost
  cost=$(pricing_cost_usd "unknown-agent" "unknown-model" 100000 30000)

  [ "$cost" = "0.00" ]
}

@test "pricing_load caches parsed data" {
  # First load
  pricing_load
  [ "$_PRICING_LOADED" = true ]

  # Second load should skip
  pricing_load
  [ "$_PRICING_LOADED" = true ]
}
