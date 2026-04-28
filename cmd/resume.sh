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

  if [ -f "$LIB_DIR/cli/emit.sh" ]; then
    source "$LIB_DIR/cli/emit.sh"
  else
    monozukuri_emit() { :; }
  fi

  source "$LIB_DIR/core/modules.sh"
  modules_init "$LIB_DIR"

  module_require core/util
  module_require config/load
  module_require core/worktree
  module_require memory/memory
  module_require cli/output
  module_require core/json-io
  module_require core/stack-profile
  module_require core/feature-state
  module_require core/platform
  module_require core/cost
  module_require core/router
  source "$LIB_DIR/agent/contract.sh"
  module_require memory/learning
  module_require plan/size-gate
  module_require plan/cycle-gate
  module_optional run/local-model  "local_model::embed" "local_model::classify" \
                                   "local_model::summarize" "local_model::generate"
  module_optional run/ingest       "ingest_trigger_if_merged" "ingest_reap_stale"
  module_optional run/injection-screen "sanitize_with_local_model"
  module_require  prompt/sanitize
  module_require schema/validate
  module_require agent/error
  module_require run/policy
  module_require run/manifest
  module_require run/ci-poll
  module_require run/routing
  module_require run/dep-check
  module_require run/implicit-dep
  module_require prompt/context-pack
  module_require agent/registry
  module_require run/pause
  module_require run/phase-3
  module_require run/phase-4
  module_require run/pipeline

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
  local _resume_exit=$?

  [ "$AUTO_CLEANUP" = "true" ] && { local cleaned; cleaned=$(wt_cleanup); [ -n "$cleaned" ] && info "Cleaned:$cleaned"; }

  return $_resume_exit
}
