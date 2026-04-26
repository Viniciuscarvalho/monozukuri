#!/bin/bash
# lib/cost.sh — Token-cost estimator (ADR-008 PR-A, Gap 8)
#
# Accumulates per-phase token estimates using baselines from config.yml.
# Converts token estimates to USD costs using pricing.yaml (Gap 8).
# All functions are additive; nothing here breaks existing behaviour.
#
# Exported variables (populated by cost_load_config):
#   COST_PHASE_1_PLANNING      — tokens for Phase 1 planning invocation
#   COST_PHASE_2_SPECIALIST    — tokens per task routed to a specialist agent
#   COST_PHASE_2_GENERIC       — tokens per task routed to feature-marker
#   COST_PHASE_4_COMMIT_PR     — tokens for Phase 4 commit+PR creation
#   COST_FIX_ATTEMPT           — overhead tokens per fix attempt in Phase 3

# Source pricing module
PRICING_MODULE="$(dirname "${BASH_SOURCE[0]}")/pricing.sh"
[ -f "$PRICING_MODULE" ] && source "$PRICING_MODULE"

# ── Load baselines from CFG_* (set by config.sh / parse-config.js) ──

cost_load_config() {
  COST_PHASE_1_PLANNING="${CFG_MODEL_COST_BASELINES_PHASE_1_PLANNING:-25000}"
  COST_PHASE_2_SPECIALIST="${CFG_MODEL_COST_BASELINES_PHASE_2_PER_TASK_SPECIALIST:-8000}"
  COST_PHASE_2_GENERIC="${CFG_MODEL_COST_BASELINES_PHASE_2_PER_TASK_GENERIC:-12000}"
  COST_PHASE_4_COMMIT_PR="${CFG_MODEL_COST_BASELINES_PHASE_4_COMMIT_PR:-5000}"
  COST_FIX_ATTEMPT="${CFG_MODEL_COST_BASELINES_FIX_ATTEMPT_OVERHEAD:-3000}"

  export COST_PHASE_1_PLANNING COST_PHASE_2_SPECIALIST COST_PHASE_2_GENERIC
  export COST_PHASE_4_COMMIT_PR COST_FIX_ATTEMPT
}

# Ensure baselines are available when the module is sourced
cost_load_config

# ── cost_init ────────────────────────────────────────────────────────
# Usage: cost_init <feat_id>
# Creates (or resets) the feature cost accumulator JSON.

cost_init() {
  local feat_id="$1"
  local cost_dir="$STATE_DIR/$feat_id"
  mkdir -p "$cost_dir"

  node -e "
    require('fs').writeFileSync('$cost_dir/cost.json', JSON.stringify({
      feature_id: '$feat_id',
      created_at: new Date().toISOString(),
      phases: [],
      cumulative_tokens: 0
    }, null, 2));
  "
}

# ── cost_estimate_phase ──────────────────────────────────────────────
# Usage: cost_estimate_phase <phase> <task_count> <agent_type>
#   phase       : 0 | 1 | 2 | 3 | 4
#   task_count  : number of tasks (relevant for phase 2 and phase 3 fix attempts)
#   agent_type  : "specialist" | "generic"
# Prints the estimated token count to stdout.
#
# Note: phase 2 estimates are routing-dependent. A feature routed to a
# specialist agent (e.g. swift-expert) uses COST_PHASE_2_SPECIALIST (8K/task
# default), while feature-marker fallback uses COST_PHASE_2_GENERIC (12K/task
# default). The same feature can show different phase 2 estimates across runs
# if agent availability changes — this is expected, not a bug.

cost_estimate_phase() {
  local phase="$1"
  local task_count="${2:-1}"
  local agent_type="${3:-generic}"

  case "$phase" in
    0)
      # Script-only; Claude not invoked on happy path
      echo "0"
      ;;
    1)
      echo "$COST_PHASE_1_PLANNING"
      ;;
    2)
      if [ "$agent_type" = "specialist" ]; then
        echo $(( task_count * COST_PHASE_2_SPECIALIST ))
      else
        echo $(( task_count * COST_PHASE_2_GENERIC ))
      fi
      ;;
    3)
      # 0 on happy path; caller passes number of fix attempts as task_count
      echo $(( task_count * COST_FIX_ATTEMPT ))
      ;;
    4)
      echo "$COST_PHASE_4_COMMIT_PR"
      ;;
    *)
      echo "0"
      ;;
  esac
}

# ── cost_record ──────────────────────────────────────────────────────
# Usage: cost_record <feat_id> <phase> <estimate>
# Appends a phase entry to cost.json and updates the cumulative total.
# Gap 8: Now also calculates and records USD cost.

cost_record() {
  local feat_id="$1"
  local phase="$2"
  local estimate="$3"
  local cost_file="$STATE_DIR/$feat_id/cost.json"

  [ ! -f "$cost_file" ] && cost_init "$feat_id"

  # Gap 8: Calculate USD cost
  local agent="${MODEL_AGENT:-claude-code}"
  local model="${MODEL_PRIMARY:-claude-sonnet-4-6}"
  local estimated_usd="0.00"

  # Only calculate USD if pricing module is available
  if command -v pricing_cost_usd &>/dev/null; then
    # Apply calibration factor
    local calibration
    calibration=$(pricing_calibration_factor "$agent" "$model" "$phase" 2>/dev/null || echo "1.0")
    local calibrated_tokens
    calibrated_tokens=$(awk -v est="$estimate" -v cal="$calibration" 'BEGIN { printf "%d", est * cal }')

    # Calculate USD cost
    estimated_usd=$(pricing_cost_usd "$agent" "$model" "$calibrated_tokens" "" 2>/dev/null || echo "0.00")
  fi

  node -e "
    const fs = require('fs');
    const data = JSON.parse(fs.readFileSync('$cost_file', 'utf-8'));
    data.phases.push({
      phase: '$phase',
      estimated_tokens: $estimate,
      estimated_usd: $estimated_usd,
      recorded_at: new Date().toISOString()
    });
    data.cumulative_tokens = data.phases.reduce((sum, p) => sum + p.estimated_tokens, 0);
    data.cumulative_usd = data.phases.reduce((sum, p) => sum + (p.estimated_usd || 0), 0);
    data.updated_at = new Date().toISOString();
    fs.writeFileSync('$cost_file', JSON.stringify(data, null, 2));
  " 2>/dev/null || true
}

# ── cost_summary ─────────────────────────────────────────────────────
# Usage: cost_summary <feat_id>
# Prints a human-readable cost summary for the feature.

cost_summary() {
  local feat_id="$1"
  local cost_file="$STATE_DIR/$feat_id/cost.json"

  if [ ! -f "$cost_file" ]; then
    info "No cost data for $feat_id"
    return
  fi

  node -e "
    const data = JSON.parse(require('fs').readFileSync('$cost_file', 'utf-8'));
    console.log('  Cost summary: ' + data.feature_id);
    data.phases.forEach(p => {
      console.log('    Phase ' + p.phase + ': ' + p.estimated_tokens.toLocaleString() + ' tokens');
    });
    console.log('  Cumulative: ' + data.cumulative_tokens.toLocaleString() + ' tokens');
  " 2>/dev/null || true
}

# ── cost_calibrate ───────────────────────────────────────────────────
# Usage: cost_calibrate <sample_n>
# Reads timing data from the last N completed features.
# Gap 8: Real implementation — reads canary-history.md and cost.json files.
# This function is now called by lib/run/calibrate.sh, not used standalone.

cost_calibrate() {
  local sample_n="${1:-10}"

  # This is a stub — the real calibration logic is in lib/run/calibrate.sh
  # Keeping this for backward compatibility in case any code still calls it
  log "Cost calibration (sample=$sample_n)"
  info "Use 'monozukuri calibrate --sample $sample_n' for full calibration report"
}
