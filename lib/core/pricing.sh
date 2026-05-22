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


# Cache for parsed pricing data (avoid re-reading YAML on every call)
_PRICING_LOADED=false

# ── pricing_load ──────────────────────────────────────────────────────
# Load pricing tables into environment variables
# Populates: PRICING_VERSION, PRICING_UPDATED_AT, PRICING_<PROVIDER>_<MODEL>_*
# Usage: pricing_load

_pricing_load_file() {
  local pricing_file="$1"
  local providers

  if [ "$(yq eval 'has("providers")' "$pricing_file" 2>/dev/null || echo "false")" = "true" ]; then
    providers=$(yq eval '.providers | keys | .[]' "$pricing_file" 2>/dev/null || echo "")
  else
    providers=$(yq eval '.provider // ""' "$pricing_file" 2>/dev/null || echo "")
  fi

  local pricing_version pricing_updated_at
  pricing_version=$(yq eval '.version // ""' "$pricing_file" 2>/dev/null || echo "")
  pricing_updated_at=$(yq eval '.updated_at // ""' "$pricing_file" 2>/dev/null || echo "")
  [ -n "$pricing_version" ] && PRICING_VERSION="$pricing_version"
  [ -n "$pricing_updated_at" ] && PRICING_UPDATED_AT="$pricing_updated_at"

  local pricing_provider
  while IFS= read -r pricing_provider; do
    [ -z "$pricing_provider" ] && continue

    local models_path calibration_path pricing_models
    if [ "$(yq eval 'has("providers")' "$pricing_file" 2>/dev/null || echo "false")" = "true" ]; then
      models_path=".providers[\"$pricing_provider\"].models"
      calibration_path=".calibration[\"$pricing_provider\"]"
    else
      models_path=".models"
      calibration_path=".calibration"
    fi

    pricing_models=$(yq eval "$models_path | keys | .[]" "$pricing_file" 2>/dev/null || echo "")

    local pricing_model
    while IFS= read -r pricing_model; do
      [ -z "$pricing_model" ] && continue

      # Normalize provider/model names (replace hyphens/dots with underscores)
      local model_norm provider_norm
      model_norm=$(echo "$pricing_model" | tr '.-' '_' | tr '[:lower:]' '[:upper:]')
      provider_norm=$(echo "$pricing_provider" | tr '-' '_' | tr '[:lower:]' '[:upper:]')

      local input_price output_price
      input_price=$(yq eval "${models_path}[\"$pricing_model\"].input_per_1m // 0.0" "$pricing_file" 2>/dev/null || echo "0.0")
      output_price=$(yq eval "${models_path}[\"$pricing_model\"].output_per_1m // 0.0" "$pricing_file" 2>/dev/null || echo "0.0")

      export "PRICING_${provider_norm}_${model_norm}_INPUT_PER_1M=$input_price"
      export "PRICING_${provider_norm}_${model_norm}_OUTPUT_PER_1M=$output_price"

      for phase in prd techspec tasks code tests pr phase0 phase1 phase2 phase3 phase4; do
        local coeff phase_norm
        coeff=$(yq eval "${calibration_path}[\"$pricing_model\"].$phase // 1.0" "$pricing_file" 2>/dev/null || echo "1.0")
        phase_norm=$(echo "$phase" | tr '-' '_' | tr '[:lower:]' '[:upper:]')
        export "CALIBRATION_${provider_norm}_${model_norm}_${phase_norm}=$coeff"
      done
    done <<< "$pricing_models"
  done <<< "$providers"
}

pricing_load() {
  # Skip if already loaded
  [ "$_PRICING_LOADED" = true ] && return 0

  # Locate pricing tables. Install tables are versioned under lib/pricing;
  # project config/pricing.yaml remains a user-managed override for calibration.
  local _self_dir
  _self_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
  local install_root
  install_root="$(cd "$_self_dir/../.." && pwd)"

  # Check yq availability
  if ! command -v yq &>/dev/null; then
    warn "yq not installed — USD cost calculation disabled; install with: brew install yq"
    _PRICING_LOADED=true
    return 1
  fi

  PRICING_VERSION="unknown"
  PRICING_UPDATED_AT="unknown"

  local pricing_files=()
  [ -f "$install_root/config/pricing.yaml" ] && pricing_files+=("$install_root/config/pricing.yaml")
  local pricing_table
  for pricing_table in "$install_root"/lib/pricing/*.yaml; do
    [ -f "$pricing_table" ] && pricing_files+=("$pricing_table")
  done
  if [ -f "${PROJECT_ROOT:-}/config/pricing.yaml" ] && \
     [ "${PROJECT_ROOT:-}/config/pricing.yaml" != "$install_root/config/pricing.yaml" ]; then
    pricing_files+=("${PROJECT_ROOT}/config/pricing.yaml")
  fi

  if [ "${#pricing_files[@]}" -eq 0 ]; then
    warn "pricing tables not found — budget checks will use \$0 cost estimates"
    _PRICING_LOADED=true
    return 1
  fi

  for pricing_table in "${pricing_files[@]}"; do
    _pricing_load_file "$pricing_table"
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
  local requested_model=$2
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
  model_norm=$(echo "$requested_model" | tr '.-' '_' | tr '[:lower:]' '[:upper:]')

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
  # A 5% safety margin is applied to avoid undercounting token estimates.
  # Use awk for portable floating point math with guaranteed leading zero
  awk -v inp="$input_tokens" -v out="$output_tokens" \
      -v inp_price="$input_price" -v out_price="$output_price" \
      'BEGIN { printf "%.4f\n", ((inp / 1000000 * inp_price) + (out / 1000000 * out_price)) * 1.05 }'
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
  phase_norm=$(echo "$phase" | tr '-' '_' | tr '[:lower:]' '[:upper:]')

  # Lookup calibration coefficient
  local key="CALIBRATION_${agent_norm}_${model_norm}_${phase_norm}"
  echo "${!key:-1.0}"
}
