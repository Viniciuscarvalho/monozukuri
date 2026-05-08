#!/bin/bash
# cmd/retry.sh — sub_retry(): batch recovery for schema-validation-failed features
#
# Usage:
#   monozukuri retry                          # list recoverable candidates (dry-run)
#   monozukuri retry --all                    # retry every matching feature
#   monozukuri retry --feat <id> [--feat <id> ...]  # retry named features
#   monozukuri retry --reason <substring>     # filter by pause/error reason substring
#
# Matches features whose status is `error` or `paused` and whose recorded reason
# contains the --reason substring (default: schema-needs-review|schema-validation-failed).
#
# Token budget: honours MONOZUKURI_SCHEMA_MAX_REPROMPTS from env so the caller
# can lift the reprompt ceiling for a triage pass:
#   MONOZUKURI_SCHEMA_MAX_REPROMPTS=6 monozukuri retry --all
#
# Sourced by orchestrate.sh; inherits SCRIPT_DIR, LIB_DIR, CMD_DIR,
# SCRIPTS_DIR, TEMPLATES_DIR, PROJECT_ROOT, ROOT_DIR, CONFIG_DIR,
# STATE_DIR, RESULTS_DIR, and all OPT_* variables.

sub_retry() {
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
  module_require run/size-gate
  module_require run/cycle-gate
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
  fi
  load_config "$config_file" 2>/dev/null || true

  WORKTREE_ROOT="$ROOT_DIR/$WORKTREE_BASE"
  export ROOT_DIR CONFIG_DIR STATE_DIR RESULTS_DIR WORKTREE_ROOT
  export WORKTREE_BASE BRANCH_PREFIX BASE_BRANCH ADAPTER AUTONOMY MODEL_DEFAULT MODEL_PLAN MODEL_EXECUTE
  mkdir -p "$STATE_DIR" "$RESULTS_DIR"

  # Parse args passed via OPT_RETRY_* variables set by orchestrate.sh arg parsing.
  local retry_all="${OPT_RETRY_ALL:-false}"
  local retry_reason="${OPT_RETRY_REASON:-schema}"
  local -a retry_feat_ids=()
  if [ -n "${OPT_RETRY_FEATS:-}" ]; then
    IFS=',' read -ra retry_feat_ids <<< "$OPT_RETRY_FEATS"
  fi

  # Discover candidate features from STATE_DIR.
  local -a candidates=()
  while IFS= read -r status_file; do
    [ -f "$status_file" ] || continue
    local fid
    fid=$(node -p "try{JSON.parse(require('fs').readFileSync('$status_file','utf-8')).feature_id||''}catch(e){''}" \
      2>/dev/null || true)
    [ -z "$fid" ] && fid=$(basename "$(dirname "$status_file")")

    local st
    st=$(fstate_get_status "$fid" 2>/dev/null || echo "none")

    if [ "$st" != "error" ] && [ "$st" != "paused" ]; then
      continue
    fi

    # Check reason — pull from pause.json if present, fall back to status.json phase field.
    local recorded_reason=""
    if [ -f "$STATE_DIR/$fid/pause.json" ]; then
      recorded_reason=$(fstate_get_pause "$fid" "reason" 2>/dev/null || true)
    fi
    if [ -z "$recorded_reason" ]; then
      recorded_reason=$(node -p \
        "try{JSON.parse(require('fs').readFileSync('$status_file','utf-8')).phase||''}catch(e){''}" \
        2>/dev/null || true)
    fi

    if ! echo "$recorded_reason" | grep -qiE "$retry_reason"; then
      continue
    fi

    candidates+=("$fid")
  done < <(find "$STATE_DIR" -name status.json -mindepth 2 -maxdepth 2 2>/dev/null | sort)

  if [ "${#candidates[@]}" -eq 0 ]; then
    info "retry: no recoverable features found matching reason '${retry_reason}'"
    return 0
  fi

  # Dry-run: list and exit when neither --all nor --feat was given.
  if [ "$retry_all" != "true" ] && [ "${#retry_feat_ids[@]}" -eq 0 ]; then
    banner "Retry — Recoverable Features"
    for fid in "${candidates[@]}"; do
      local st reason
      st=$(fstate_get_status "$fid" 2>/dev/null || echo "?")
      reason=$(fstate_get_pause "$fid" "reason" 2>/dev/null || true)
      printf "  %-30s  %s  %s\n" "$fid" "$st" "${reason:-unknown}"
    done
    echo ""
    info "Run with --all to retry all, or --feat <id> to pick specific features."
    return 0
  fi

  # Resolve the final set to retry.
  local -a to_retry=()
  if [ "$retry_all" = "true" ]; then
    to_retry=("${candidates[@]}")
  else
    for fid in "${retry_feat_ids[@]}"; do
      local found=false
      for c in "${candidates[@]}"; do
        [ "$c" = "$fid" ] && found=true && break
      done
      if [ "$found" = "true" ]; then
        to_retry+=("$fid")
      else
        warn "retry: '$fid' is not a recoverable candidate (status or reason mismatch) — skipping"
      fi
    done
  fi

  if [ "${#to_retry[@]}" -eq 0 ]; then
    info "retry: nothing to retry after filtering"
    return 0
  fi

  banner "Retry — $((${#to_retry[@]})) feature(s)"

  local succeeded=0 failed=0
  for fid in "${to_retry[@]}"; do
    info "retry: processing $fid..."

    # Migrate error → paused so resume logic and status display are correct.
    local prior_status
    prior_status=$(fstate_get_status "$fid" 2>/dev/null || echo "error")
    if [ "$prior_status" = "error" ]; then
      fstate_transition "$fid" "paused" "schema-needs-review"
      fstate_record_pause "$fid" "human" "schema-needs-review"
    fi

    monozukuri_emit feature.retry_started \
      feature_id "$fid" prior_status "$prior_status"

    # Clear retry/phase3 sentinels (and pause.json — implied by the ack).
    runner_clear_sentinels "$fid" "all"

    # Recover the feature title from results.json if available, else fall back to feat_id.
    local title="$fid"
    local results_file="$STATE_DIR/$fid/results.json"
    if [ -f "$results_file" ]; then
      title=$(node -p \
        "try{JSON.parse(require('fs').readFileSync('$results_file','utf-8')).title||'$fid'}catch(e){'$fid'}" \
        2>/dev/null || echo "$fid")
    fi

    # Re-enter run_feature directly. Planning artifact cache checks ([ -f "$_af" ])
    # skip already-generated phases, so only code + schema validation re-run.
    local _retry_exit=0
    run_feature "$fid" "$title" "" "medium" "" "" "1" "1" || _retry_exit=$?

    local new_status
    new_status=$(fstate_get_status "$fid" 2>/dev/null || echo "unknown")
    monozukuri_emit feature.retry_completed \
      feature_id "$fid" new_status "$new_status" exit_code "$_retry_exit"

    if [ "$_retry_exit" -eq 0 ]; then
      succeeded=$((succeeded + 1))
      info "retry: $fid succeeded (status: $new_status)"
    else
      failed=$((failed + 1))
      warn "retry: $fid still failing (status: $new_status, exit: $_retry_exit)"
    fi
  done

  echo ""
  info "retry complete — succeeded: $succeeded  still-failing: $failed"
  [ "$failed" -gt 0 ] && return 1 || return 0
}
