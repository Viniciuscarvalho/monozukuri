#!/bin/bash
# cmd/run.sh — sub_run(): main orchestration loop
# Sourced by orchestrate.sh; inherits SCRIPT_DIR, LIB_DIR, CMD_DIR,
# SCRIPTS_DIR, TEMPLATES_DIR, PROJECT_ROOT, ROOT_DIR, CONFIG_DIR,
# STATE_DIR, RESULTS_DIR, and all OPT_* variables.

sub_run() {
  # Load event emitter (no-ops gracefully when absent or jq missing)
  if [ -f "$LIB_DIR/cli/emit.sh" ]; then
    source "$LIB_DIR/cli/emit.sh"
  else
    monozukuri_emit() { :; }
  fi

  # Bootstrap module registry — must come first so all subsequent loads are tracked
  source "$LIB_DIR/core/modules.sh"
  modules_init "$LIB_DIR"

  # Foundation (required)
  module_require core/util
  module_require config/load
  module_require core/worktree
  module_require memory/memory
  module_require cli/output
  # ADR-011 foundation (must load before router and feature-state)
  module_require core/json-io
  module_require core/stack-profile
  # Architecture seams (depend on worktree + json-io)
  module_require core/feature-state
  module_require core/platform
  # ADR-008 modules
  module_require core/cost
  module_require core/router
  # Agent adapter contract (multi-agent support)
  source "$LIB_DIR/agent/contract.sh"
  module_require memory/learning
  module_require plan/size-gate
  module_require plan/cycle-gate
  # ADR-009 optional modules — stubs registered so `declare -f` guards work
  module_optional run/local-model  "local_model::embed" "local_model::classify" \
                                   "local_model::summarize" "local_model::generate"
  module_optional run/ingest       "ingest_trigger_if_merged" "ingest_reap_stale"
  # ADR-011 PR-F: injection screen (optional — requires local-model)
  module_optional run/injection-screen "sanitize_with_local_model"
  module_require  prompt/sanitize
  # ADR-012: phase artifact schema validation
  module_require schema/validate
  # ADR-013: failure classification, policy, manifest, CI poll
  module_require agent/error
  module_require run/policy
  module_require run/manifest
  module_require run/ci-poll
  # ADR-012 (Gap 3): phase template rendering + adapter routing
  module_require prompt/context-pack
  module_require agent/registry
  # Phase modules (extracted from pipeline.sh)
  module_require run/pause
  module_require run/phase-3
  module_require run/phase-4
  module_require run/pipeline

  # Resolve config file — check multiple locations
  local config_file="$OPT_CONFIG"
  if [ ! -f "$config_file" ]; then
    if [ -f ".monozukuri/config.yaml" ]; then
      config_file=".monozukuri/config.yaml"
    elif [ -f ".monozukuri/config.yml" ]; then
      config_file=".monozukuri/config.yml"
    elif [ -f "$TEMPLATES_DIR/config.yaml" ]; then
      config_file="$TEMPLATES_DIR/config.yaml"
    fi
  fi

  # Interactive: prompt when no project-specific config exists (TTY only)
  if [ ! -f ".monozukuri/config.yaml" ] && [ ! -f ".monozukuri/config.yml" ] \
      && [ -t 0 ] && [ "${OPT_NON_INTERACTIVE:-false}" != "true" ]; then
    if command -v gum >/dev/null 2>&1; then
      gum confirm "No project config found. Run 'monozukuri init' first?" \
        && { source "$CMD_DIR/init.sh"; sub_init; } || exit 0
    else
      printf "No project config found. Run 'monozukuri init' first? [Y/n]: "
      read -r _ans
      case "${_ans:-Y}" in
        [nN]*) exit 0 ;;
        *) source "$CMD_DIR/init.sh"; sub_init ;;
      esac
    fi
    # Re-resolve config after init
    [ -f ".monozukuri/config.yaml" ] && config_file=".monozukuri/config.yaml"
  fi

  # Load config + secrets + validate
  load_config "$config_file"

  WORKTREE_ROOT="$ROOT_DIR/$WORKTREE_BASE"
  export ROOT_DIR CONFIG_DIR STATE_DIR RESULTS_DIR WORKTREE_ROOT
  export WORKTREE_BASE BRANCH_PREFIX BASE_BRANCH ADAPTER AUTONOMY MODEL_DEFAULT MODEL_PLAN MODEL_EXECUTE

  mkdir -p "$STATE_DIR" "$RESULTS_DIR"

  banner "Orchestrate — $ADAPTER / $AUTONOMY / $BASE_BRANCH / model:$MODEL_DEFAULT"

  # ADR-010: reap any finished background ingest jobs from prior sessions
  if declare -f ingest_reap_stale &>/dev/null; then
    ingest_reap_stale || true
  fi

  # ADR-009 PR-E: startup health check (when local-model.sh is present)
  if declare -f local_model_health_check &>/dev/null; then
    local_model_health_check || true
  fi

  # Agent discovery (ADR-006)
  local manifest_file="$CONFIG_DIR/agents-manifest.json"
  if [ "$AGENT_DISCOVERY" = "true" ] && [ -f "$SCRIPTS_DIR/agent-discovery.sh" ]; then
    bash "$SCRIPTS_DIR/agent-discovery.sh" "$ROOT_DIR" "$manifest_file" 2>&1
  fi

  # Environment discovery
  mem_refresh_env

  # Emit run.started
  monozukuri_emit run.started \
    autonomy "$AUTONOMY" \
    model "$MODEL_DEFAULT" \
    source "$ADAPTER"

  # Run adapter
  info "Loading backlog via $ADAPTER adapter..."
  local adapter_out count
  adapter_out=$(run_adapter)
  # run_adapter prints a status line + the integer count; extract just the number
  count=$(echo "$adapter_out" | grep -Eo '^[0-9]+$' | tail -1 || echo "$adapter_out" | tail -1 | grep -Eo '[0-9]+' | tail -1)
  info "Loaded $count features"

  monozukuri_emit backlog.loaded feature_count "$count"

  # ADR-011 PR-B: sanitize backlog items before any feature processing
  if [ "${SANITIZE_MODE:-strict}" != "off" ] && command -v node &>/dev/null; then
    local backlog_json="$ROOT_DIR/$BACKLOG_OUTPUT"
    [ -f "$backlog_json" ] && node "$SCRIPTS_DIR/sanitize-backlog.js" "$backlog_json" 2>&1 \
      | grep -v "^$" | sed 's/^/  [sanitize] /' || true
  fi

  local backlog_file="$ROOT_DIR/$BACKLOG_OUTPUT"

  # Dry-run: show plan and exit
  if [ "$OPT_DRY_RUN" = true ]; then
    banner "Dry Run — Plan"
    display_backlog "$backlog_file"
    echo ""
    info "Autonomy: $AUTONOMY"
    info "Worktrees: $WORKTREE_ROOT"
    info "Model: $MODEL_DEFAULT (plan: ${MODEL_PLAN:-inherit}, execute: ${MODEL_EXECUTE:-inherit})"
    info "PR strategy: $PR_STRATEGY"
    rm -f "$backlog_file"
    exit 0
  fi

  # ADR-013: initialise run manifest (or reconcile on --resume)
  if declare -f manifest_init &>/dev/null; then
    if [ "${OPT_RESUME:-false}" = "true" ]; then
      local _latest_run
      _latest_run=$(manifest_find_latest)
      if [ -n "$_latest_run" ]; then
        MANIFEST_RUN_ID="$_latest_run"
        export MANIFEST_RUN_ID
        info "Resuming run $MANIFEST_RUN_ID"
        manifest_reconcile "$MANIFEST_RUN_ID" || {
          warn "Manifest drift: missing worktrees for ${MANIFEST_MISSING_WORKTREES:-unknown}"
        }
      else
        manifest_init > /dev/null
      fi
    else
      manifest_init > /dev/null
    fi
  fi

  # Execute
  run_backlog "$backlog_file"

  # Finalize manifest
  if declare -f manifest_finalize &>/dev/null && [ -n "${MANIFEST_RUN_ID:-}" ]; then
    manifest_finalize "$MANIFEST_RUN_ID" "completed"
  fi

  # Cleanup backlog file
  rm -f "$backlog_file"
}
