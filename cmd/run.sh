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

  # Load modules
  source "$LIB_DIR/core/util.sh"
  source "$LIB_DIR/config/load.sh"
  source "$LIB_DIR/core/worktree.sh"
  source "$LIB_DIR/memory/memory.sh"
  source "$LIB_DIR/cli/output.sh"
  # ADR-011 foundation modules (must load before router)
  source "$LIB_DIR/core/json-io.sh"
  source "$LIB_DIR/core/stack-profile.sh"
  # ADR-008 modules
  source "$LIB_DIR/core/cost.sh"
  source "$LIB_DIR/core/router.sh"
  source "$LIB_DIR/memory/learning.sh"
  source "$LIB_DIR/plan/size-gate.sh"
  source "$LIB_DIR/plan/cycle-gate.sh"
  # ADR-009 modules (optional — loaded if present)
  [ -f "$LIB_DIR/run/local-model.sh"    ] && source "$LIB_DIR/run/local-model.sh"
  [ -f "$LIB_DIR/run/ingest.sh"         ] && source "$LIB_DIR/run/ingest.sh"
  # ADR-011 PR-F: local-model injection screen (optional — requires local-model.sh)
  [ -f "$LIB_DIR/run/injection-screen.sh" ] && source "$LIB_DIR/run/injection-screen.sh"
  source "$LIB_DIR/prompt/sanitize.sh"
  source "$LIB_DIR/run/pipeline.sh"

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

  # Execute
  run_backlog "$backlog_file"

  # Cleanup backlog file
  rm -f "$backlog_file"
}
