#!/bin/bash
# cmd/status.sh — sub_status(): show current orchestrator state
# Sourced by orchestrate.sh; inherits SCRIPT_DIR, LIB_DIR, CMD_DIR,
# SCRIPTS_DIR, PROJECT_ROOT, ROOT_DIR, CONFIG_DIR, STATE_DIR, RESULTS_DIR,
# and all OPT_* variables.

sub_status() {
  source "$LIB_DIR/core/worktree.sh"
  source "$LIB_DIR/cli/output.sh"

  if [ ! -d "$STATE_DIR" ] || [ -z "$(ls -A "$STATE_DIR" 2>/dev/null)" ]; then
    if [ "${OPT_JSON:-false}" = "true" ]; then
      echo '{"features":[],"summary":{"total":0,"done":0,"pr":0,"ready":0,"failed":0}}'
    else
      info "No features tracked yet. Run: monozukuri run"
    fi
    exit 0
  fi

  local done_n=0 pr_n=0 ready_n=0 failed_n=0 total=0

  if [ "${OPT_JSON:-false}" = "true" ]; then
    local json_parts=()
    for dir in "$STATE_DIR"/*/; do
      [ -d "$dir" ] || continue
      local fid; fid=$(basename "$dir")
      [ -f "$dir/status.json" ] || continue
      total=$((total + 1))
      local st; st=$(wt_get_status "$fid")
      case "$st" in
        done) done_n=$((done_n+1)) ;;
        pr-created) pr_n=$((pr_n+1)) ;;
        ready) ready_n=$((ready_n+1)) ;;
        failed) failed_n=$((failed_n+1)) ;;
      esac
      json_parts+=("$(cat "$dir/status.json")")
    done
    local joined
    joined=$(printf '%s,' "${json_parts[@]}" | sed 's/,$//')
    printf '{"features":[%s],"summary":{"total":%d,"done":%d,"pr":%d,"ready":%d,"failed":%d}}\n' \
      "$joined" "$total" "$done_n" "$pr_n" "$ready_n" "$failed_n"
    exit 0
  fi

  banner "Orchestrator Status"

  for dir in "$STATE_DIR"/*/; do
    [ -d "$dir" ] || continue
    local fid; fid=$(basename "$dir")
    [ -f "$dir/status.json" ] || continue
    total=$((total + 1))
    display_feature_result "$fid"
    local st; st=$(wt_get_status "$fid")
    case "$st" in
      done) done_n=$((done_n+1)) ;;
      pr-created) pr_n=$((pr_n+1)) ;;
      ready) ready_n=$((ready_n+1)) ;;
      failed) failed_n=$((failed_n+1)) ;;
    esac
  done

  echo ""
  info "Total: $total | Done: $done_n | PR: $pr_n | Ready: $ready_n | Failed: $failed_n"

  echo ""
  log "Worktrees:"
  wt_list

  if [ -f "$CONFIG_DIR/agents-manifest.json" ]; then
    local agent_count
    agent_count=$(node -p "JSON.parse(require('fs').readFileSync('$CONFIG_DIR/agents-manifest.json','utf-8')).agents.length" 2>/dev/null || echo "0")
    echo ""
    info "Discovered agents: $agent_count"
  fi
}
