#!/bin/bash
# cmd/summary.sh — Aggregate view across all registered monozukuri projects.
#
# Reads ~/.monozukuri/projects.json (populated by every `monozukuri run`).
# For each project, reads .monozukuri/ state to count feature outcomes and
# sum costs, then prints a single dashboard for weekly triage.
#
# Usage:
#   monozukuri summary [--all]    print cross-project overview

sub_summary() {
  source "$LIB_DIR/ops/budget.sh"   2>/dev/null || true
  source "$LIB_DIR/ops/projects.sh" 2>/dev/null || true

  local projects_file="${HOME}/.monozukuri/projects.json"

  if [ ! -f "$projects_file" ]; then
    printf 'No projects registered. Run "monozukuri run" in a project first.\n'
    return 0
  fi

  local project_count
  project_count=$(node -p "JSON.parse(require('fs').readFileSync('$projects_file','utf-8')).length" 2>/dev/null || echo 0)

  if [ "$project_count" -eq 0 ]; then
    printf 'No projects registered.\n'
    return 0
  fi

  printf '\n=== Monozukuri Summary — %s ===\n\n' "$(date -u +%Y-%m-%dT%H:%M:%SZ)"

  local total_cost_usd=0

  node -e "
    const fs = require('fs');
    const projects = JSON.parse(fs.readFileSync('$projects_file','utf-8'));
    projects.forEach(p => console.log(JSON.stringify(p)));
  " 2>/dev/null | while IFS= read -r proj_json; do
    local proj_path proj_agent proj_last_run
    proj_path=$(node -p "JSON.parse(require('fs').readFileSync('/dev/stdin','utf-8')).path" <<< "$proj_json" 2>/dev/null)
    proj_agent=$(node -p "JSON.parse(require('fs').readFileSync('/dev/stdin','utf-8')).agent" <<< "$proj_json" 2>/dev/null)
    proj_last_run=$(node -p "JSON.parse(require('fs').readFileSync('/dev/stdin','utf-8')).last_run" <<< "$proj_json" 2>/dev/null)

    [ -z "$proj_path" ] && continue

    local state_dir="$proj_path/.monozukuri/state"
    [ -d "$proj_path/.monozukuri/feature-state" ] && state_dir="$proj_path/.monozukuri/feature-state"

    # Relative time since last run
    local elapsed_label="unknown"
    if [ -n "$proj_last_run" ]; then
      local now_epoch last_epoch elapsed_secs
      now_epoch=$(date +%s)
      last_epoch=$(node -p "Math.floor(new Date('$proj_last_run').getTime()/1000)" 2>/dev/null || echo "$now_epoch")
      elapsed_secs=$(( now_epoch - last_epoch ))
      if [ "$elapsed_secs" -lt 3600 ]; then
        elapsed_label="${elapsed_secs}s ago"
      elif [ "$elapsed_secs" -lt 86400 ]; then
        elapsed_label="$(( elapsed_secs / 3600 ))h ago"
      else
        elapsed_label="$(( elapsed_secs / 86400 ))d ago"
      fi
    fi

    printf 'Project: %s\n' "$proj_path"
    printf '  Agent:    %s\n' "${proj_agent:-unknown}"
    printf '  Last run: %s (%s)\n' "$proj_last_run" "$elapsed_label"

    # Count feature outcomes from state directory
    local done_n=0 pr_n=0 paused_n=0 failed_n=0 proj_cost=0

    if [ -d "$state_dir" ]; then
      for feat_dir in "$state_dir"/*/; do
        [ -d "$feat_dir" ] || continue
        local status_file="$feat_dir/status.json"
        [ -f "$status_file" ] || continue
        local st
        st=$(node -p "try{JSON.parse(require('fs').readFileSync('$status_file','utf-8')).status||''}catch(e){''}" 2>/dev/null || echo "")
        case "$st" in
          done)         done_n=$((done_n+1)) ;;
          pr-created)   pr_n=$((pr_n+1)) ;;
          paused)       paused_n=$((paused_n+1)) ;;
          failed|error) failed_n=$((failed_n+1)) ;;
        esac

        local cost_file="$feat_dir/cost.json"
        if [ -f "$cost_file" ]; then
          local feat_cost
          feat_cost=$(node -p "try{JSON.parse(require('fs').readFileSync('$cost_file','utf-8')).cost_usd||0}catch(e){0}" 2>/dev/null || echo 0)
          proj_cost=$(node -p "Math.round(($proj_cost+$feat_cost)*10000)/10000" 2>/dev/null || echo "$proj_cost")
        fi
      done
    fi

    local total_features=$(( done_n + pr_n + paused_n + failed_n ))
    local pause_rate=0
    if [ "$total_features" -gt 0 ]; then
      pause_rate=$(node -p "Math.round($paused_n/$total_features*100)" 2>/dev/null || echo 0)
    fi

    printf '  Status:   done:%-2d  pr-created:%-2d  paused:%-2d  failed:%-2d\n' \
      "$done_n" "$pr_n" "$paused_n" "$failed_n"
    printf '  Pause %%:  %d%%' "$pause_rate"
    [ "$pause_rate" -gt 30 ] && printf '  ⚠ exceeds 30%% SLO'
    printf '\n'
    printf '  Cost:     $%s\n' "$proj_cost"
    printf '\n'
  done

  # Global budget line
  if declare -f budget_status &>/dev/null; then
    budget_status
  fi
  printf '\n'
}
