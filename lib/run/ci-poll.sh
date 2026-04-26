#!/bin/bash
# lib/run/ci-poll.sh — CI terminal-state poll + flake detection + reprompt (ADR-014)
#
# Waits for CI to reach a terminal state after PR creation:
#   1. Poll gh pr checks until all checks pass, any check fails, or timeout
#   2. On failure: re-run failed jobs up to CI_MAX_FLAKE_RERUNS (default 2)
#   3. Still red: one agent reprompt + fixup commit + push + re-poll once
#   4. Still red / timeout: feature.failed with PR link
#
# Env overrides:
#   CI_POLL_TIMEOUT      seconds before giving up (default 3600 = 60 min)
#   CI_POLL_INTERVAL     seconds between polls (default 30)
#   CI_MAX_FLAKE_RERUNS  failed-job reruns before escalating to agent (default 2)
#
# Public interface:
#   ci_wait_for_green <feat_id> <pr_url> <wt_path>
#   ci_check_status <pr_num>           → success|failure|pending|unknown
#   ci_rerun_failed_jobs <pr_num>      → triggers reruns; returns 0 if any rerun sent
#   ci_get_failed_log_url <pr_num>     → URL to first failed check's logs

CI_POLL_TIMEOUT="${CI_POLL_TIMEOUT:-3600}"
CI_POLL_INTERVAL="${CI_POLL_INTERVAL:-30}"
CI_MAX_FLAKE_RERUNS="${CI_MAX_FLAKE_RERUNS:-2}"

# ci_wait_for_green <feat_id> <pr_url> <wt_path>
ci_wait_for_green() {
  local feat_id="$1"
  local pr_url="$2"
  local wt_path="$3"

  local pr_num
  pr_num=$(echo "$pr_url" | sed 's|.*/||')

  local start_ts
  start_ts=$(date +%s)

  info "CI: polling PR #$pr_num for $feat_id (timeout: ${CI_POLL_TIMEOUT}s)"

  while true; do
    local elapsed
    elapsed=$(( $(date +%s) - start_ts ))

    if [ "$elapsed" -ge "$CI_POLL_TIMEOUT" ]; then
      warn "CI: timeout after ${elapsed}s for $feat_id PR #$pr_num"
      fstate_transition "$feat_id" "failed" "ci-timeout"
      monozukuri_emit feature.failed feature_id "$feat_id" \
        error "ci-timeout" pr_url "$pr_url" 2>/dev/null || true
      return 1
    fi

    local ci_status
    ci_status=$(ci_check_status "$pr_num")
    info "CI: PR #$pr_num → $ci_status (${elapsed}s elapsed)"

    case "$ci_status" in
      success)
        info "CI: green — $feat_id PR #$pr_num passed all checks"
        return 0
        ;;

      failure)
        local rerun_count
        rerun_count=$(cat "$STATE_DIR/$feat_id/ci-rerun-count" 2>/dev/null || echo "0")

        if [ "$rerun_count" -lt "$CI_MAX_FLAKE_RERUNS" ]; then
          rerun_count=$((rerun_count + 1))
          echo "$rerun_count" > "$STATE_DIR/$feat_id/ci-rerun-count"
          info "CI: red — flake rerun $rerun_count/$CI_MAX_FLAKE_RERUNS for $feat_id"
          ci_rerun_failed_jobs "$pr_num" || true
          sleep "$CI_POLL_INTERVAL"
          continue
        fi

        # Reruns exhausted — one agent reprompt (ADR-014 §2c)
        local reprompt_done
        reprompt_done=$(cat "$STATE_DIR/$feat_id/ci-reprompt-done" 2>/dev/null || echo "0")

        if [ "$reprompt_done" -eq 0 ]; then
          echo "1" > "$STATE_DIR/$feat_id/ci-reprompt-done"
          echo "0" > "$STATE_DIR/$feat_id/ci-rerun-count"
          info "CI: red after reruns — one agent reprompt for $feat_id (ADR-014)"
          if ci_reprompt_and_push "$feat_id" "$pr_num" "$wt_path"; then
            sleep "$CI_POLL_INTERVAL"
            continue
          fi
          warn "CI: reprompt/push failed for $feat_id"
        fi

        local ci_log_url
        ci_log_url=$(ci_get_failed_log_url "$pr_num" 2>/dev/null || echo "${pr_url}/checks")
        warn "CI: still red after reprompt for $feat_id — feature failed"
        fstate_transition "$feat_id" "failed" "ci-red-after-reprompt"
        monozukuri_emit feature.failed feature_id "$feat_id" \
          error "ci-red-after-reprompt" pr_url "$pr_url" ci_log "$ci_log_url" 2>/dev/null || true
        return 1
        ;;

      pending | in_progress | queued)
        sleep "$CI_POLL_INTERVAL"
        ;;

      *)
        sleep "$CI_POLL_INTERVAL"
        ;;
    esac
  done
}

# ci_check_status <pr_num>
# Returns: success | failure | pending | unknown
ci_check_status() {
  local pr_num="$1"

  if ! command -v gh &>/dev/null; then
    echo "unknown"
    return 0
  fi

  local checks_json
  checks_json=$(platform_gh 30 pr checks "$pr_num" \
    --json name,state,conclusion 2>/dev/null || echo "[]")

  printf '%s' "$checks_json" | node -e "
    const data = JSON.parse(require('fs').readFileSync('/dev/stdin','utf-8'));
    if (!Array.isArray(data) || data.length === 0) { console.log('pending'); process.exit(0); }
    const conclusions = data.map(c => (c.conclusion || c.state || '').toLowerCase());
    if (conclusions.every(s => s === 'success')) { console.log('success'); process.exit(0); }
    if (conclusions.some(s => s === 'failure' || s === 'error' || s === 'cancelled')) {
      console.log('failure'); process.exit(0);
    }
    console.log('pending');
  " 2>/dev/null || echo "unknown"
}

# ci_rerun_failed_jobs <pr_num>
# Fetches failed check run IDs and triggers reruns. Returns 0 if any sent.
ci_rerun_failed_jobs() {
  local pr_num="$1"
  local rerun_count=0

  local failed_ids
  failed_ids=$(platform_gh 30 pr checks "$pr_num" \
    --json databaseId,conclusion 2>/dev/null | node -e "
    const d = JSON.parse(require('fs').readFileSync('/dev/stdin','utf-8'));
    (d||[])
      .filter(c => c.conclusion === 'failure' || c.conclusion === 'error')
      .forEach(c => { if (c.databaseId) console.log(c.databaseId); });
  " 2>/dev/null || echo "")

  while IFS= read -r run_id; do
    [ -z "$run_id" ] && continue
    platform_gh 60 run rerun "$run_id" --failed 2>/dev/null || true
    rerun_count=$((rerun_count + 1))
  done <<< "$failed_ids"

  [ "$rerun_count" -gt 0 ]
}

# ci_get_failed_log_url <pr_num>
# Returns detailsUrl of the first failed check, or empty string.
ci_get_failed_log_url() {
  local pr_num="$1"
  if ! command -v gh &>/dev/null; then echo ""; return 0; fi

  platform_gh 30 pr checks "$pr_num" \
    --json name,detailsUrl,conclusion 2>/dev/null | node -e "
    const data = JSON.parse(require('fs').readFileSync('/dev/stdin','utf-8'));
    const f = (data||[]).find(c => c.conclusion === 'failure' || c.conclusion === 'error');
    console.log(f ? (f.detailsUrl || '') : '');
  " 2>/dev/null || echo ""
}

# ci_reprompt_and_push <feat_id> <pr_num> <wt_path>
# Sends CI failure context to the agent, expects fixup commits, re-pushes.
ci_reprompt_and_push() {
  local feat_id="$1"
  local pr_num="$2"
  local wt_path="$3"

  local ci_output
  ci_output=$(platform_gh 60 pr checks "$pr_num" --fail-fast 2>&1 | head -50 \
    || echo "CI check details unavailable")

  local fix_prompt
  fix_prompt=$(printf \
    'CI checks failed for this PR. Please fix the code so all CI checks pass.\n\nCI output:\n%s\n\nMake the necessary changes and commit them.\n' \
    "$ci_output")

  local model_flag=""
  local _fix_model="${MODEL_DEFAULT:-}"
  [ "$_fix_model" = "opusplan" ] && _fix_model="opus"
  [ -n "$_fix_model" ] && model_flag="--model $_fix_model"

  local fix_perm_flag=""
  [ "${AUTONOMY:-}" = "full_auto" ] && fix_perm_flag="--permission-mode bypassPermissions"

  local reprompt_exit=0
  (cd "$wt_path" && printf '%b' "$fix_prompt" |
    platform_claude "${SKILL_TIMEOUT_SECONDS:-1800}" $model_flag $fix_perm_flag --print) \
    2>/dev/null || reprompt_exit=$?

  if [ "$reprompt_exit" -ne 0 ]; then
    warn "CI: agent reprompt failed (exit $reprompt_exit) for $feat_id"
    return 1
  fi

  local branch="${BRANCH_PREFIX:-feat}/$feat_id"
  local push_exit=0
  (cd "$wt_path" \
    && git add -A 2>/dev/null || true \
    && git commit -m "fix: CI fixup for $feat_id" --allow-empty 2>/dev/null || true \
    && git push origin "$branch" 2>/dev/null) || push_exit=$?

  if [ "$push_exit" -ne 0 ]; then
    warn "CI: push after reprompt failed for $feat_id"
    return 1
  fi

  info "CI: reprompt fixup pushed for $feat_id"
  return 0
}
