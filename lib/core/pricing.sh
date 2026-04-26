#!/bin/bash
# lib/core/pricing.sh — USD cost calculation from token counts (ADR-008 Gap 8)
#
# Converts token estimates to USD costs using versioned pricing table.
# Supports per-(agent, model, phase) calibration coefficients.
#
# Public API:
#   pricing_load                                     — Load pricing.yaml into env vars
#   pricing_cost_usd <agent> <model> <input> <output> — Calculate USD cost
#   pricing_calibration_factor <agent> <model> <phase> — Get calibration multiplier

set -euo pipefail

# Helper functions (if not already defined)
warn() { echo "⚠ [pricing] $*" >&2; }
info() { echo "  [pricing] $*"; }
log() { echo "▶ [pricing] $*"; }

# Cache for parsed pricing data (avoid re-reading YAML on every call)
_PRICING_LOADED=false

# ── pricing_load ──────────────────────────────────────────────────────
# Load pricing.yaml into environment variables
# Populates: PRICING_VERSION, PRICING_UPDATED_AT, PRICING_<PROVIDER>_<MODEL>_*
# Usage: pricing_load

pricing_load() {
  # Skip if already loaded
  [ "$_PRICING_LOADED" = true ] && return 0

  # Locate pricing.yaml (project config or bundled default)
  local pricing_file=""
  if [ -f "$PROJECT_ROOT/config/pricing.yaml" ]; then
    pricing_file="$PROJECT_ROOT/config/pricing.yaml"
  elif [ -f "$SCRIPT_DIR/config/pricing.yaml" ]; then
    pricing_file="$SCRIPT_DIR/config/pricing.yaml"
  else
    # Pricing file missing — warn and use defaults
    warn "pricing.yaml not found — using default calibration (1.0)"
    _PRICING_LOADED=true
    return 0
  fi

  # Check yq availability
  if ! command -v yq &>/dev/null; then
    warn "yq not installed — USD cost calculation disabled"
    _PRICING_LOADED=true
    return 0
  fi

  # Parse metadata
  PRICING_VERSION=$(yq eval '.version' "$pricing_file" 2>/dev/null || echo "1.0.0")
  PRICING_UPDATED_AT=$(yq eval '.updated_at' "$pricing_file" 2>/dev/null || echo "unknown")

  # Parse provider pricing (claude-code and aider)
  # Format: PRICING_CLAUDE_CODE_CLAUDE_SONNET_4_6_INPUT_PER_1M=3.00
  for provider in claude-code aider; do
    local models
    models=$(yq eval ".providers.$provider.models | keys | .[]" "$pricing_file" 2>/dev/null || echo "")

    while IFS= read -r model; do
      [ -z "$model" ] && continue

      # Normalize model name (replace hyphens/dots with underscores)
      local model_norm
      model_norm=$(echo "$model" | tr '.-' '_' | tr '[:lower:]' '[:upper:]')
      local provider_norm
      provider_norm=$(echo "$provider" | tr '-' '_' | tr '[:lower:]' '[:upper:]')

      local input_price output_price
      input_price=$(yq eval ".providers.$provider.models.$model.input_per_1m" "$pricing_file" 2>/dev/null || echo "0.0")
      output_price=$(yq eval ".providers.$provider.models.$model.output_per_1m" "$pricing_file" 2>/dev/null || echo "0.0")

      # Export as env vars
      export "PRICING_${provider_norm}_${model_norm}_INPUT_PER_1M=$input_price"
      export "PRICING_${provider_norm}_${model_norm}_OUTPUT_PER_1M=$output_price"
    done <<< "$models"
  done

  # Parse calibration coefficients
  # Format: CALIBRATION_CLAUDE_CODE_CLAUDE_SONNET_4_6_PRD=1.0
  for provider in claude-code aider; do
    local models
    models=$(yq eval ".calibration.$provider | keys | .[]" "$pricing_file" 2>/dev/null || echo "")

    while IFS= read -r model; do
      [ -z "$model" ] && continue

      local model_norm provider_norm
      model_norm=$(echo "$model" | tr '.-' '_' | tr '[:lower:]' '[:upper:]')
      provider_norm=$(echo "$provider" | tr '-' '_' | tr '[:lower:]' '[:upper:]')

      for phase in prd techspec tasks code tests pr; do
        local coeff phase_norm
        coeff=$(yq eval ".calibration.$provider.$model.$phase" "$pricing_file" 2>/dev/null || echo "1.0")
        phase_norm=$(echo "$phase" | tr '[:lower:]' '[:upper:]')
        export "CALIBRATION_${provider_norm}_${model_norm}_${phase_norm}=$coeff"
      done
    done <<< "$models"
  done

  _PRICING_LOADED=true
  export PRICING_VERSION PRICING_UPDATED_AT
}

# ── pricing_cost_usd ──────────────────────────────────────────────────
# Calculate USD cost from token counts
# Usage: pricing_cost_usd <agent> <model> <input_tokens> <output_tokens>
# Returns: USD cost as float (e.g., "0.1234")
# Note: If output_tokens is empty, splits total into 70% input / 30% output

pricing_cost_usd() {
  local agent=$1
  local model=$2
  local input_tokens=$3
  local output_tokens=${4:-}

  # Ensure pricing is loaded
  pricing_load

  # If output is empty (token-only estimate), split 70/30
  if [ -z "$output_tokens" ] || [ "$output_tokens" = "0" ]; then
    output_tokens=$(awk -v t="$input_tokens" 'BEGIN { printf "%d", t * 0.3 }')
    input_tokens=$(awk -v t="$input_tokens" 'BEGIN { printf "%d", t * 0.7 }')
  fi

  # Normalize agent and model names
  local agent_norm model_norm
  agent_norm=$(echo "$agent" | tr '-' '_' | tr '[:lower:]' '[:upper:]')
  model_norm=$(echo "$model" | tr '.-' '_' | tr '[:lower:]' '[:upper:]')

  # Lookup pricing from env vars
  local input_price_var="PRICING_${agent_norm}_${model_norm}_INPUT_PER_1M"
  local output_price_var="PRICING_${agent_norm}_${model_norm}_OUTPUT_PER_1M"
  local input_price="${!input_price_var:-0.0}"
  local output_price="${!output_price_var:-0.0}"

  # If pricing not found, warn and return 0.0
  if [ "$input_price" = "0.0" ] && [ "$output_price" = "0.0" ]; then
    echo "0.00"
    return 0
  fi

  # Calculate cost: (input / 1M * input_price) + (output / 1M * output_price)
  # Use awk for portable floating point math with guaranteed leading zero
  awk -v inp="$input_tokens" -v out="$output_tokens" \
      -v inp_price="$input_price" -v out_price="$output_price" \
      'BEGIN { printf "%.4f\n", (inp / 1000000 * inp_price) + (out / 1000000 * out_price) }'
}

# ── pricing_calibration_factor ────────────────────────────────────────
# Get calibration multiplier for (agent, model, phase)
# Usage: pricing_calibration_factor <agent> <model> <phase>
# Returns: calibration coefficient (default 1.0 if not found)

pricing_calibration_factor() {
  local agent=$1
  local model=$2
  local phase=$3

  # Ensure pricing is loaded
  pricing_load

  # Normalize names
  local agent_norm model_norm phase_norm
  agent_norm=$(echo "$agent" | tr '-' '_' | tr '[:lower:]' '[:upper:]')
  model_norm=$(echo "$model" | tr '.-' '_' | tr '[:lower:]' '[:upper:]')
  phase_norm=$(echo "$phase" | tr '[:lower:]' '[:upper:]')

  # Lookup calibration coefficient
  local key="CALIBRATION_${agent_norm}_${model_norm}_${phase_norm}"
  echo "${!key:-1.0}"
}
