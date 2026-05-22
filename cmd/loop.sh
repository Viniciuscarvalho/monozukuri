#!/bin/bash
# cmd/loop.sh — sub_loop(): sequential non-interactive feature loop
# Sourced by orchestrate.sh; inherits SCRIPT_DIR, LIB_DIR, CMD_DIR,
# SCRIPTS_DIR, TEMPLATES_DIR, PROJECT_ROOT, ROOT_DIR, CONFIG_DIR,
# STATE_DIR, RESULTS_DIR, and all OPT_* variables.

_loop_bootstrap_modules() {
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
  module_optional run/local-model "local_model::embed" "local_model::classify" \
                                  "local_model::summarize" "local_model::generate"
  module_optional run/ingest "ingest_trigger_if_merged" "ingest_reap_stale"
  module_optional run/injection-screen "sanitize_with_local_model"
  module_require prompt/sanitize
  module_require schema/validate
  module_require agent/error
  module_require run/policy
  module_require run/manifest
  module_require run/ci-poll
  module_require run/routing
  module_require run/dep-check
  module_require run/implicit-dep
  module_require prompt/context-pack
  module_require prompt/render
  module_require agent/registry
  module_require run/pause
  module_require run/phase-3
  module_require run/phase-4
  module_require run/pipeline
}

_loop_resolve_config_file() {
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
  printf '%s\n' "$config_file"
}

_loop_make_run_id() {
  local rand
  rand=$(od -An -N3 -tx1 /dev/urandom 2>/dev/null | tr -d ' \n')
  [ -n "$rand" ] || rand=$(printf '%06d' "$$")
  printf 'loop-%s-%s\n' "$(date +%Y-%m-%d)" "$rand"
}

_loop_collect_ids() {
  local ids="${OPT_LOOP_IDS:-}"
  if [ -z "$ids" ] && [ ! -t 0 ]; then
    local line trimmed
    while IFS= read -r line; do
      trimmed=$(printf '%s' "$line" | sed 's/^[[:space:]]*//' | sed 's/[[:space:]]*$//')
      [ -z "$trimmed" ] && continue
      if [ -n "$ids" ]; then
        ids="${ids},$trimmed"
      else
        ids="$trimmed"
      fi
    done
  fi
  printf '%s\n' "$ids"
}

_loop_item_for_id() {
  local backlog_file="$1" feat_id="$2"
  node - "$backlog_file" "$feat_id" <<'JSEOF'
const [,, backlogFile, featureId] = process.argv;
const fs = require('fs');
const items = JSON.parse(fs.readFileSync(backlogFile, 'utf8'));
const item = items.find((entry) => entry.id === featureId);
if (!item) process.exit(1);
process.stdout.write(JSON.stringify(item));
JSEOF
}

_loop_pr_label() {
  local feat_id="$1" status="$2"
  local pr_url pr_num
  pr_url=$(fstate_get_pr_url "$feat_id")
  if [ -n "$pr_url" ]; then
    pr_num="${pr_url##*/}"
    printf 'PR #%s\n' "$pr_num"
  elif [ "$status" = "done" ]; then
    printf 'done\n'
  else
    printf '%s\n' "$status"
  fi
}

sub_loop() {
  trap 'exit 130' INT

  _loop_bootstrap_modules

  # Reuse run's incompatible-skill guard without invoking sub_run.
  if ! declare -f _run_check_incompatible_skills >/dev/null 2>&1; then
    source "$CMD_DIR/run.sh"
  fi

  local config_file
  config_file=$(_loop_resolve_config_file)
  load_config "$config_file"

  if declare -f routing_load >/dev/null 2>&1; then
    routing_load "$ROOT_DIR"
  fi

  local loop_run_id
  loop_run_id=$(_loop_make_run_id)
  WORKTREE_ROOT="$ROOT_DIR/.monozukuri/worktrees/$loop_run_id"
  AUTO_CLEANUP=false
  if [ "${OPT_LOOP_CLEANUP:-false}" = "true" ]; then
    AUTO_CLEANUP=true
  fi
  BRANCH_PREFIX="${BRANCH_PREFIX:-feat}/$loop_run_id"

  export ROOT_DIR CONFIG_DIR STATE_DIR RESULTS_DIR WORKTREE_ROOT
  export WORKTREE_BASE BRANCH_PREFIX BASE_BRANCH ADAPTER AUTONOMY MODEL_DEFAULT MODEL_PLAN MODEL_EXECUTE
  mkdir -p "$STATE_DIR" "$RESULTS_DIR" "$WORKTREE_ROOT" "$CONFIG_DIR/runs/$loop_run_id"

  _run_check_incompatible_skills
  mem_refresh_env

  local ids_csv
  ids_csv=$(_loop_collect_ids)
  if [ -z "$ids_csv" ]; then
    err "No feature IDs provided."
    err "Usage: monozukuri loop <id...> or pipe IDs on stdin"
    return 1
  fi

  run_adapter >/dev/null
  local backlog_file="$ROOT_DIR/$BACKLOG_OUTPUT"

  local ids=()
  local IFS_ORIG="$IFS"
  IFS=","
  read -r -a ids <<< "$ids_csv"
  IFS="$IFS_ORIG"

  local total="${#ids[@]}"
  local index=0 any_failed=0
  local feat_id item_json title body priority labels deps next_feat_id
  for feat_id in "${ids[@]}"; do
    index=$((index + 1))
    feat_id=$(printf '%s' "$feat_id" | sed 's/^[[:space:]]*//' | sed 's/[[:space:]]*$//')
    [ -z "$feat_id" ] && continue

    if ! item_json=$(_loop_item_for_id "$backlog_file" "$feat_id"); then
      printf '[%d/%d] %s ✗ not found\n' "$index" "$total" "$feat_id"
      any_failed=1
      continue
    fi

    title=$(echo "$item_json"    | node -p "JSON.parse(require('fs').readFileSync('/dev/stdin','utf-8')).title")
    body=$(echo "$item_json"     | node -p "JSON.parse(require('fs').readFileSync('/dev/stdin','utf-8')).body")
    priority=$(echo "$item_json" | node -p "JSON.parse(require('fs').readFileSync('/dev/stdin','utf-8')).priority")
    labels=$(echo "$item_json"   | node -p "JSON.parse(require('fs').readFileSync('/dev/stdin','utf-8')).labels.join(', ')")
    deps=$(echo "$item_json"     | node -p "JSON.parse(require('fs').readFileSync('/dev/stdin','utf-8')).dependencies.join(', ')||'none'")

    next_feat_id=""
    if [ "$index" -lt "$total" ]; then
      next_feat_id="${ids[$index]}"
    fi

    local loop_log="$CONFIG_DIR/runs/$loop_run_id/$feat_id/loop.log"
    mkdir -p "$(dirname "$loop_log")"

    local feature_exit=0
    run_feature "$feat_id" "$title" "$body" "$priority" "$labels" "$deps" "$index" "$total" "$next_feat_id" \
      >"$loop_log" 2>&1 || feature_exit=$?

    local final_status label
    final_status=$(fstate_get_status "$feat_id")
    if { [ "$feature_exit" -eq 0 ] && [ "$final_status" = "done" ]; } || [ "$final_status" = "pr-created" ]; then
      label=$(_loop_pr_label "$feat_id" "$final_status")
      printf '[%d/%d] %s ✓ %s\n' "$index" "$total" "$feat_id" "$label"
    else
      [ -n "$final_status" ] || final_status="failed"
      printf '[%d/%d] %s ✗ %s\n' "$index" "$total" "$feat_id" "$final_status"
      any_failed=1
    fi

    if [ "$AUTO_CLEANUP" = "true" ]; then
      wt_remove "$feat_id"
    fi
  done

  rm -f "$backlog_file"
  [ "$any_failed" -eq 0 ] || return 1
  return 0
}
