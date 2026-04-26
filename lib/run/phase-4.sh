#!/bin/bash
# lib/run/phase-4.sh — Dependency checking and PR creation (ADR-008 PR-A/C)
#
# Extracted from pipeline.sh so PR creation and dependency-merge polling are
# independently testable. All gh/az/glab calls route through platform.sh.
#
# Requires: lib/core/platform.sh    (platform_detect, platform_gh, platform_pr_merged)
#           lib/core/feature-state.sh (fstate_transition, fstate_record_pause,
#                                     fstate_set_pr_url)

# ── dep_check_merge_state ────────────────────────────────────────────────────
# Usage: dep_check_merge_state <feat_id> <deps_csv>
# ADR-008 PR-C: for each dependency in deps_csv, checks that its PR is merged.
# Returns 0 if all deps are merged (or have no PR data); 1 if any dep is unmerged.
dep_check_merge_state() {
  local feat_id="$1"
  local deps_csv="$2"

  [ -z "$deps_csv" ] && return 0

  platform_detect

  local all_merged=0
  local IFS_ORIG="$IFS"
  IFS=","
  for dep_id in $deps_csv; do
    IFS="$IFS_ORIG"
    dep_id=$(echo "$dep_id" | sed 's/^[[:space:]]*//' | sed 's/[[:space:]]*$//')
    [ -z "$dep_id" ] && IFS="," && continue

    local dep_results="$STATE_DIR/$dep_id/results.json"
    if [ ! -f "$dep_results" ]; then
      info "Dep $dep_id: no results.json — assuming not yet run (allowing)"
      IFS=","
      continue
    fi

    local pr_url
    pr_url=$(node -p "
      try {
        const r = JSON.parse(require('fs').readFileSync('$dep_results','utf-8'));
        r.pr_url || '';
      } catch(e) { ''; }
    " 2>/dev/null || echo "")

    if [ -z "$pr_url" ]; then
      info "Dep $dep_id: no PR URL recorded — assuming not complete (blocking)"
      all_merged=1
      IFS=","
      continue
    fi

    local pr_num
    pr_num=$(echo "$pr_url" | sed 's|.*/||')

    if platform_pr_merged "$pr_num"; then
      info "Dep $dep_id: PR #$pr_num merged — OK"
    else
      info "Dep $dep_id: PR #$pr_num not yet merged"
      all_merged=1
    fi

    IFS=","
  done
  IFS="$IFS_ORIG"

  return $all_merged
}

# ── run_pr_creation ──────────────────────────────────────────────────────────
# Usage: run_pr_creation <feat_id> <title> <wt_path> <results_file>
# Pushes the feature branch and opens a PR via platform_gh.
# On success: writes PR URL via fstate_set_pr_url, marks pr-created.
# On failure: marks done (graceful degradation) and prints manual instructions.
run_pr_creation() {
  local feat_id="$1" title="$2" wt_path="$3" results_file="$4"

  if [ "$PR_STRATEGY" = "none" ]; then
    fstate_transition "$feat_id" "done" "complete"
    info "Done: $feat_id (pr_strategy=none)"
    return 0
  fi

  if ! command -v gh &>/dev/null; then
    fstate_transition "$feat_id" "done" "complete"
    info "Done: $feat_id (no gh CLI — PR skipped)"
    return 0
  fi

  info "Creating PR for $feat_id..."
  local branch="${BRANCH_PREFIX:-feat}/$feat_id"
  local push_err="" push_exit=0

  if [ -d "$wt_path" ]; then
    local push_tmpfile
    push_tmpfile=$(mktemp)
    (
      cd "$wt_path"
      git add -A 2>/dev/null || true
      git commit -m "feat: $title" --allow-empty 2>/dev/null || true
      git push --force-with-lease origin "$branch" || git push --force origin "$branch"
    ) 2>"$push_tmpfile" || push_exit=$?
    push_err=$(cat "$push_tmpfile")
    rm -f "$push_tmpfile"
  else
    push_err="worktree $wt_path no longer exists (cleaned up before PR creation)"
    push_exit=1
  fi

  # ADR-011 PR-C: audit command log before creating PR
  if [ -f "${SCRIPTS_DIR}/audit_commands.sh" ]; then
    bash "${SCRIPTS_DIR}/audit_commands.sh" verify-clean "$wt_path" 2>&1 || {
      warn "audit_commands: deny-list hits detected — blocking PR creation for $feat_id"
      fstate_transition "$feat_id" "error" "audit-denied"
      return 1
    }
  fi

  local pr_flag=""
  [ "$PR_STRATEGY" = "draft" ] && pr_flag="--draft"

  local pr_url="" pr_err="" pr_exit=0 pr_tmpfile
  pr_tmpfile=$(mktemp)
  if pr_url=$(platform_gh 60 pr create \
    --base "$BASE_BRANCH" \
    --head "$branch" \
    --title "feat: $title" \
    --body "Automated by feature-marker orchestrator." \
    $pr_flag 2>"$pr_tmpfile"); then
    pr_exit=0
  else
    pr_exit=$?
  fi
  pr_err=$(cat "$pr_tmpfile")
  rm -f "$pr_tmpfile"

  # gh pr create may emit the URL to stderr when an existing PR already matches
  [ -z "$pr_url" ] && pr_url=$(echo "$pr_err" | grep -Eo 'https://github\.com/[^ ]+' | head -1) || true

  if [ "$pr_exit" -eq 0 ] && [ -n "$pr_url" ]; then
    fstate_transition "$feat_id" "pr-created" "complete"
    monozukuri_emit feature.completed feature_id "$feat_id" pr_url "$pr_url" 2>/dev/null || true
    fstate_set_pr_url "$feat_id" "$pr_url"
    info "PR: $pr_url"
    if declare -f ingest_trigger_if_merged &>/dev/null; then
      ingest_trigger_if_merged "$feat_id"
    fi
  else
    fstate_transition "$feat_id" "done" "complete"
    local W=64
    local inner=$((W - 2))
    echo ""
    printf "  ┌%s┐\n" "$(printf '─%.0s' $(seq 1 $W))"
    printf "  │  %-*s│\n" "$((inner - 2))" "PR creation failed: $feat_id"
    printf "  ├%s┤\n" "$(printf '─%.0s' $(seq 1 $W))"
    if [ $push_exit -ne 0 ] && [ -n "$push_err" ]; then
      printf "  │  %-*s│\n" "$((inner - 2))" "git push $branch:"
      while IFS= read -r line; do
        printf "  │    %-*s│\n" "$((inner - 4))" "${line:0:$((inner - 4))}"
      done <<< "$(echo "$push_err" | head -5)"
    fi
    if [ -n "$pr_err" ]; then
      printf "  │  %-*s│\n" "$((inner - 2))" ""
      printf "  │  %-*s│\n" "$((inner - 2))" "gh pr create:"
      while IFS= read -r line; do
        printf "  │    %-*s│\n" "$((inner - 4))" "${line:0:$((inner - 4))}"
      done <<< "$(echo "$pr_err" | head -5)"
    fi
    printf "  ├%s┤\n" "$(printf '─%.0s' $(seq 1 $W))"
    printf "  │  %-*s│\n" "$((inner - 2))" "To create manually:"
    printf "  │    %-*s│\n" "$((inner - 4))" "git push origin $branch"
    printf "  │    %-*s│\n" "$((inner - 4))" "gh pr create --base $BASE_BRANCH --head $branch \\"
    printf "  │      %-*s│\n" "$((inner - 6))" "--title \"feat: $title\""
    printf "  └%s┘\n" "$(printf '─%.0s' $(seq 1 $W))"
    echo ""
  fi
}
