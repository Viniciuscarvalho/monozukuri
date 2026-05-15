#!/bin/bash
# cmd/run.sh — sub_run(): main orchestration loop
# Sourced by orchestrate.sh; inherits SCRIPT_DIR, LIB_DIR, CMD_DIR,
# SCRIPTS_DIR, TEMPLATES_DIR, PROJECT_ROOT, ROOT_DIR, CONFIG_DIR,
# STATE_DIR, RESULTS_DIR, and all OPT_* variables.

# _run_check_incompatible_skills — hard block before any worktree is created.
# Reads CFG_AGENTS_<AGENT>_SKILLS_<PHASE> env vars (set by parse-config.js from
# agents.<agent>.skills.<phase> in config.yaml) and exits EXIT_CONFIG_INVALID=10
# when any explicit phase override maps to a known-incompatible skill.
#
# Uses tr for case conversion (bash 3.2-safe; avoids the ${^^} bash 4 operator
# in skill-detect.sh which silently degrades on macOS system bash).
# Only explicit config overrides are checked — hardcoded mz-* defaults are always safe.
_run_check_incompatible_skills() {
  local _ki_sh="${LIB_DIR}/agent/known-incompatible.sh"
  [ -f "$_ki_sh" ] || return 0

  if ! declare -f is_skill_known_incompatible &>/dev/null; then
    # shellcheck source=../lib/agent/known-incompatible.sh
    source "$_ki_sh"
  fi

  # Build agent-norm (uppercase, hyphens→underscores) using tr — bash 3.2 safe.
  local agent_norm
  agent_norm=$(printf '%s' "${MONOZUKURI_AGENT:-claude-code}" | tr '[:lower:]-' '[:upper:]_')

  local phase phase_upper cfg_var skill reason found=0
  for phase in prd techspec tasks code tests pr; do
    phase_upper=$(printf '%s' "$phase" | tr '[:lower:]' '[:upper:]')
    cfg_var="CFG_AGENTS_${agent_norm}_SKILLS_${phase_upper}"
    skill="${!cfg_var:-}"
    [ -z "$skill" ] && continue
    if is_skill_known_incompatible "$skill"; then
      reason="$(known_incompatible_reason "$skill")"
      err "Incompatible skill '${skill}' configured for phase '${phase}': ${reason}"
      found=1
    fi
  done
  if [ "$found" -eq 1 ]; then
    printf "   Fix: remove agents.claude-code.skills overrides from .monozukuri/config.yaml\n" >&2
    printf "        or run: monozukuri setup to install the mz-* replacement skills\n" >&2
    exit "${EXIT_CONFIG_INVALID}"
  fi
}

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
  module_require run/size-gate
  module_require run/cycle-gate
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
  # ADR-015 (Gap 4): per-phase adapter routing
  module_require run/routing
  # ADR-015 (Gap 7): explicit and implicit dependency detection
  module_require run/dep-check
  module_require run/implicit-dep
  # ADR-012 (Gap 3): phase template rendering + adapter routing
  module_require prompt/context-pack
  module_require prompt/render
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

  # ADR-015: load per-phase routing.yaml (exports PHASE_ADAPTER_<PHASE>)
  if declare -f routing_load &>/dev/null; then
    routing_load "$ROOT_DIR"
  fi

  WORKTREE_ROOT="$ROOT_DIR/$WORKTREE_BASE"
  export ROOT_DIR CONFIG_DIR STATE_DIR RESULTS_DIR WORKTREE_ROOT
  export WORKTREE_BASE BRANCH_PREFIX BASE_BRANCH ADAPTER AUTONOMY MODEL_DEFAULT MODEL_PLAN MODEL_EXECUTE

  mkdir -p "$STATE_DIR" "$RESULTS_DIR"

  # C1/C3: Init global budget and register this project in the cross-project registry.
  source "$LIB_DIR/ops/budget.sh"     2>/dev/null || true
  source "$LIB_DIR/ops/projects.sh"   2>/dev/null || true
  source "$LIB_DIR/ops/telemetry.sh"  2>/dev/null || true
  declare -f budget_init        &>/dev/null && budget_init
  declare -f projects_register  &>/dev/null && projects_register "$ROOT_DIR" "${ADAPTER:-unknown}"

  # E3: Prompt for telemetry consent on first run (no-op if already decided or non-interactive)
  declare -f telemetry_prompt &>/dev/null && telemetry_prompt

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
  # Scaffold AGENTS.md when neither it nor .claude/agents/ exist, so new projects
  # have clear agent configuration from the start.
  local agents_md="$ROOT_DIR/AGENTS.md"
  local agents_dir="$ROOT_DIR/.claude/agents"
  if [ "${MONOZUKURI_NO_SCAFFOLD:-}" != "1" ] \
     && [ ! -f "$agents_md" ] \
     && { [ ! -d "$agents_dir" ] || [ -z "$(ls -A "$agents_dir" 2>/dev/null)" ]; }; then
    local tmpl="$TEMPLATES_DIR/AGENTS.md"
    if [ -f "$tmpl" ]; then
      cp "$tmpl" "$agents_md"
      info "[scaffold] wrote $agents_md — declare project agents in this file"
    fi
  fi

  local manifest_file="$CONFIG_DIR/agents-manifest.json"
  if [ "$AGENT_DISCOVERY" = "true" ] && [ -f "$SCRIPTS_DIR/agent-discovery.sh" ]; then
    bash "$SCRIPTS_DIR/agent-discovery.sh" "$ROOT_DIR" "$manifest_file" 2>&1
  fi

  local skills_manifest_file="$CONFIG_DIR/skills-manifest.json"
  if [ "${SKILL_DISCOVERY:-true}" = "true" ] && [ -f "$SCRIPTS_DIR/skill-discovery.sh" ]; then
    bash "$SCRIPTS_DIR/skill-discovery.sh" "$ROOT_DIR" "$skills_manifest_file" 2>&1
    export MONOZUKURI_SKILLS_MANIFEST="$skills_manifest_file"
  fi

  # Hard block — refuse to start when any configured phase skill is known-incompatible.
  # Must run after skill discovery so the manifest is populated for phase_to_skill.
  _run_check_incompatible_skills

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

  # Count per-feature outcomes to derive correct manifest status and telemetry.
  # Done early (before finalize) so both blocks share one pass over status.json.
  local _done_count=0 _paused_count=0 _failed_count=0
  if [ -d "${STATE_DIR:-}" ]; then
    # grep -c exits 1 when count is 0; use { ... || true; } to avoid double-printing.
    _done_count=$(find "$STATE_DIR" -name status.json -exec \
      node -p "try{const d=JSON.parse(require('fs').readFileSync('{}','utf-8'));['done','pr-created'].includes(d.status)?'1':''}catch(e){''}" \; \
      2>/dev/null | { grep -c "^1$" || true; })
    _paused_count=$(find "$STATE_DIR" -name status.json -exec \
      node -p "try{const d=JSON.parse(require('fs').readFileSync('{}','utf-8'));d.status==='paused'?'1':''}catch(e){''}" \; \
      2>/dev/null | { grep -c "^1$" || true; })
    _failed_count=$(find "$STATE_DIR" -name status.json -exec \
      node -p "try{const d=JSON.parse(require('fs').readFileSync('{}','utf-8'));d.status==='failed'?'1':''}catch(e){''}" \; \
      2>/dev/null | { grep -c "^1$" || true; })
  fi

  # Derive aggregate run status: failed > paused-only > completed.
  local _run_final="completed"
  if (( _failed_count > 0 )); then
    _run_final="failed"
  elif (( _done_count == 0 && _paused_count > 0 )); then
    _run_final="paused"
  fi

  # Finalize manifest
  if declare -f manifest_finalize &>/dev/null && [ -n "${MANIFEST_RUN_ID:-}" ]; then
    manifest_finalize "$MANIFEST_RUN_ID" "$_run_final"
  fi

  # Auto-sync AGENTS.md from learning store (opt-in via conventions.auto_sync: true)
  if [ -f "$LIB_DIR/run/conventions-sync.sh" ]; then
    source "$LIB_DIR/run/conventions-sync.sh"
    conventions_auto_sync "$ROOT_DIR" || true
  fi

  # E3: Send anonymous telemetry (best-effort, background, no retries)
  if declare -f telemetry_send &>/dev/null && declare -f telemetry_build_payload &>/dev/null; then
    export TELEMETRY_AGENT="${ADAPTER:-unknown}"
    export TELEMETRY_COMPLETED TELEMETRY_PAUSED TELEMETRY_FAILED
    TELEMETRY_COMPLETED="$_done_count"
    TELEMETRY_PAUSED="$_paused_count"
    TELEMETRY_FAILED="$_failed_count"
    export TELEMETRY_TOP_ERROR="${MONOZUKURI_TOP_ERROR_CLASS:-none}"
    export TELEMETRY_COST_USD="${MONOZUKURI_RUN_COST_USD:-0}"
    local _payload
    _payload=$(telemetry_build_payload)
    telemetry_send "$_payload"
  fi

  # Cleanup backlog file
  rm -f "$backlog_file"
}
