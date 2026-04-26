#!/bin/bash
# lib/run/canary.sh — Canary benchmark orchestration (Gap 5)
#
# Public API:
#   canary_run  — Execute canary benchmark suite and record metrics

set -euo pipefail

# ── Config Loading ────────────────────────────────────────────────────────

# Load and validate canary config
# Returns: 0 if valid, 1 if invalid/missing
_canary_load_config() {
  local config_file="${CONFIG_DIR}/canary-config.json"

  if [ ! -f "$config_file" ]; then
    echo "Canary config not found: $config_file" >&2
    echo "Create .monozukuri/canary-config.json with feature list" >&2
    return 1
  fi

  # Validate JSON
  if ! jq empty "$config_file" 2>/dev/null; then
    echo "Invalid JSON in canary config: $config_file" >&2
    return 1
  fi

  # Check required fields
  if ! jq -e '.features' "$config_file" >/dev/null 2>&1; then
    echo "Canary config missing 'features' array" >&2
    return 1
  fi

  return 0
}

# ── Feature Execution (Stubbed for v1) ───────────────────────────────────

# Execute a single canary feature and track results
# Usage: _canary_execute_feature <feature_id> <stack>
# Returns: Sets feat_ci_pass, feat_tokens, feat_completed, feat_retries, feat_flakes
_canary_execute_feature() {
  local feature_id="$1"
  local stack="$2"

  # STUB for v1: Generate mock results
  # TODO: Replace with actual monozukuri run when monozukuri-canaries repo is ready

  # Simulate CI pass/fail (85% pass rate)
  if [ $((RANDOM % 100)) -lt 85 ]; then
    feat_ci_pass=1
  else
    feat_ci_pass=0
  fi

  # Simulate token count (40K-50K range)
  feat_tokens=$((40000 + RANDOM % 10000))

  # Simulate completion (90% complete rate)
  if [ $((RANDOM % 100)) -lt 90 ]; then
    feat_completed=1
  else
    feat_completed=0
  fi

  # Simulate retries (0-2 range)
  feat_retries=$((RANDOM % 3))

  # Simulate flakes (10% flake rate)
  if [ $((RANDOM % 100)) -lt 10 ]; then
    feat_flakes=1
  else
    feat_flakes=0
  fi

  echo "  Executed: $feature_id ($stack) — CI: $feat_ci_pass, Tokens: $feat_tokens, Complete: $feat_completed" >&2
}

# ── Metric Aggregation ────────────────────────────────────────────────────

# Aggregate results by stack slice
# Usage: _canary_aggregate_by_stack <results_json>
# Returns: JSON object with per-stack headline percentages
_canary_aggregate_by_stack() {
  local results_json="$1"

  # Use jq to group by stack and calculate per-stack CI pass rate
  echo "$results_json" | jq -r '
    group_by(.stack) |
    map({
      stack: .[0].stack,
      pass_rate: (map(select(.ci_pass == 1)) | length) * 100 / length
    }) |
    map({key: .stack, value: (.pass_rate | floor)}) |
    from_entries
  '
}

# ── Headline Metric Calculation ───────────────────────────────────────────

# Calculate overall CI-pass-rate-on-first-PR
# Usage: _canary_calculate_headline <results_json>
# Returns: Integer 0-100 or "N/A"
_canary_calculate_headline() {
  local results_json="$1"

  # Count features with CI pass on first PR attempt
  local total
  total=$(echo "$results_json" | jq 'length')

  if [ "$total" -eq 0 ]; then
    echo "N/A"
    return
  fi

  local pass_count
  pass_count=$(echo "$results_json" | jq '[.[] | select(.ci_pass == 1)] | length')

  # Calculate percentage
  awk -v p="$pass_count" -v t="$total" 'BEGIN {printf "%.0f", (p/t)*100}'
}

# ── Diagnostic Metrics Calculation ────────────────────────────────────────

# Calculate diagnostic metrics
# Usage: _canary_calculate_diagnostics <results_json>
# Returns: Sets diag_tokens_avg, diag_completion_pct, diag_retry_rate, diag_flake_rate
_canary_calculate_diagnostics() {
  local results_json="$1"

  local total
  total=$(echo "$results_json" | jq 'length')

  if [ "$total" -eq 0 ]; then
    diag_tokens_avg=0
    diag_completion_pct=0
    diag_retry_rate=0
    diag_flake_rate=0
    return
  fi

  # tokens_avg: mean token count
  local tokens_sum
  tokens_sum=$(echo "$results_json" | jq '[.[] | .tokens] | add')
  diag_tokens_avg=$(awk -v s="$tokens_sum" -v t="$total" 'BEGIN {printf "%.0f", s/t}')

  # completion_%: (features_completed / total) * 100
  local completed_count
  completed_count=$(echo "$results_json" | jq '[.[] | select(.completed == 1)] | length')
  diag_completion_pct=$(awk -v c="$completed_count" -v t="$total" 'BEGIN {printf "%.0f", (c/t)*100}')

  # phase_retry_rate: average retries per feature
  local retries_sum
  retries_sum=$(echo "$results_json" | jq '[.[] | .retries] | add')
  diag_retry_rate=$(awk -v s="$retries_sum" -v t="$total" 'BEGIN {printf "%.2f", s/t}')

  # ci_flake_rate: (features_with_flakes / total) * 100
  local flake_count
  flake_count=$(echo "$results_json" | jq '[.[] | select(.flakes == 1)] | length')
  diag_flake_rate=$(awk -v f="$flake_count" -v t="$total" 'BEGIN {printf "%.0f", (f/t)*100}')
}

# ── Main Canary Run Function ──────────────────────────────────────────────

# Execute canary benchmark suite and record metrics
# Expects: CONFIG_DIR, PROJECT_ROOT, LIB_DIR set
canary_run() {
  # Source dependencies
  source "$LIB_DIR/core/modules.sh" 2>/dev/null || true
  if command -v modules_init &>/dev/null; then
    modules_init "$LIB_DIR"
    module_require core/util 2>/dev/null || true
    module_require memory/metrics
  else
    source "$LIB_DIR/memory/metrics.sh"
  fi

  echo "Starting canary benchmark run..." >&2

  # Load and validate config
  if ! _canary_load_config; then
    return 1
  fi

  local config_file="${CONFIG_DIR}/canary-config.json"

  # Generate unique run_id
  local run_id
  run_id="run-$(date -u +%Y%m%d-%H%M%S)"
  echo "Run ID: $run_id" >&2

  # Execute features and collect results
  local -a results=()
  local feature_count
  feature_count=$(jq '.features | length' "$config_file")

  echo "Executing $feature_count canary features..." >&2

  for ((i=0; i<feature_count; i++)); do
    local feature_id stack

    feature_id=$(jq -r ".features[$i].id" "$config_file")
    stack=$(jq -r ".features[$i].stack" "$config_file")

    # Execute feature (stub for v1)
    _canary_execute_feature "$feature_id" "$stack"

    # Collect result as JSON
    results+=("{\"id\":\"$feature_id\",\"stack\":\"$stack\",\"ci_pass\":$feat_ci_pass,\"tokens\":$feat_tokens,\"completed\":$feat_completed,\"retries\":$feat_retries,\"flakes\":$feat_flakes}")
  done

  # Build results JSON array
  local results_json
  results_json="[$(IFS=,; echo "${results[*]}")]"

  # Calculate headline metric
  local headline_pct
  headline_pct=$(_canary_calculate_headline "$results_json")
  echo "Headline metric: ${headline_pct}%" >&2

  # Calculate diagnostic metrics
  _canary_calculate_diagnostics "$results_json"
  echo "Diagnostic metrics: tokens_avg=$diag_tokens_avg, completion=$diag_completion_pct%, retry_rate=$diag_retry_rate, flake_rate=$diag_flake_rate%" >&2

  # Aggregate by stack
  local stack_breakdown
  stack_breakdown=$(_canary_aggregate_by_stack "$results_json")
  echo "Stack breakdown: $stack_breakdown" >&2

  # Append to history
  local history_file="${PROJECT_ROOT}/docs/canary-history.md"
  metrics_append "$history_file" "$run_id" "$headline_pct" "$diag_tokens_avg" "$diag_completion_pct" "$stack_breakdown"

  echo "Canary run complete: $run_id" >&2
  echo "Results appended to: $history_file" >&2
}

# Allow direct invocation for testing
if [ "${BASH_SOURCE[0]}" = "${0}" ]; then
  canary_run
fi
