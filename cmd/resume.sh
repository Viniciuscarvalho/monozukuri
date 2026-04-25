#!/bin/bash
# cmd/resume.sh — sub_resume_paused(): resume a paused feature from checkpoint (ADR-010)
# Sourced by orchestrate.sh; inherits SCRIPT_DIR, LIB_DIR, CMD_DIR,
# SCRIPTS_DIR, TEMPLATES_DIR, PROJECT_ROOT, ROOT_DIR, CONFIG_DIR,
# STATE_DIR, RESULTS_DIR, and all OPT_* variables.

sub_resume_paused() {
  if [ -z "$OPT_RESUME_FEAT" ]; then
    err "Usage: monozukuri --resume-paused <feat-id> [--ack]"
    exit 1
  fi

  source "$LIB_DIR/core/util.sh"
  source "$LIB_DIR/config/load.sh"
  source "$LIB_DIR/core/worktree.sh"
  source "$LIB_DIR/memory/memory.sh"
  source "$LIB_DIR/cli/output.sh"
  source "$LIB_DIR/core/cost.sh"
  source "$LIB_DIR/core/router.sh"
  source "$LIB_DIR/memory/learning.sh"
  source "$LIB_DIR/plan/size-gate.sh"
  source "$LIB_DIR/plan/cycle-gate.sh"
  [ -f "$LIB_DIR/run/local-model.sh" ] && source "$LIB_DIR/run/local-model.sh"
  [ -f "$LIB_DIR/run/ingest.sh"      ] && source "$LIB_DIR/run/ingest.sh"
  source "$LIB_DIR/core/json-io.sh"
  source "$LIB_DIR/core/stack-profile.sh"
  source "$LIB_DIR/prompt/sanitize.sh"
  source "$LIB_DIR/run/pipeline.sh"

  local config_file="$OPT_CONFIG"
  if [ ! -f "$config_file" ]; then
    [ -f ".monozukuri/config.yaml" ] && config_file=".monozukuri/config.yaml"
    [ -f ".monozukuri/config.yml"  ] && config_file=".monozukuri/config.yml"
    [ -f "orchestrator/config.yml"   ] && config_file="orchestrator/config.yml"
  fi
  load_config "$config_file" 2>/dev/null || true

  WORKTREE_ROOT="$ROOT_DIR/$WORKTREE_BASE"
  export ROOT_DIR CONFIG_DIR STATE_DIR RESULTS_DIR WORKTREE_ROOT
  export WORKTREE_BASE BRANCH_PREFIX BASE_BRANCH ADAPTER AUTONOMY MODEL_DEFAULT MODEL_PLAN MODEL_EXECUTE
  mkdir -p "$STATE_DIR" "$RESULTS_DIR"

  banner "Resume Paused — $OPT_RESUME_FEAT"

  local ack_flag=""
  [ "$OPT_RESUME_ACK" = "true" ] && ack_flag="--ack"

  run_feature_resume "$OPT_RESUME_FEAT" $ack_flag
}
