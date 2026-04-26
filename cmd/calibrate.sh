#!/bin/bash
# cmd/calibrate.sh — sub_calibrate(): token-cost calibration (ADR-008 Gap 8)
# Sourced by orchestrate.sh; inherits SCRIPT_DIR, LIB_DIR, CMD_DIR,
# SCRIPTS_DIR, TEMPLATES_DIR, PROJECT_ROOT, ROOT_DIR, CONFIG_DIR,
# STATE_DIR, RESULTS_DIR, and all OPT_* variables.

sub_calibrate() {
  source "$LIB_DIR/config/load.sh"
  source "$LIB_DIR/core/cost.sh"
  source "$LIB_DIR/core/pricing.sh"
  source "$LIB_DIR/run/calibrate.sh"

  local config_file="$OPT_CONFIG"
  if [ ! -f "$config_file" ]; then
    [ -f ".monozukuri/config.yaml" ] && config_file=".monozukuri/config.yaml"
    [ -f ".monozukuri/config.yml"  ] && config_file=".monozukuri/config.yml"
    [ -f "orchestrator/config.yml"   ] && config_file="orchestrator/config.yml"
  fi

  load_config "$config_file" 2>/dev/null || true
  cost_load_config

  banner "Cost Calibration & USD Analysis"
  calibrate_run "$OPT_SAMPLE"
}
