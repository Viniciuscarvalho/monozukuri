#!/bin/bash
# lib/run/pause.sh — Pause taxonomy, sentinel cleanup, and resume
#
# Extracted from pipeline.sh so the pause/resume lifecycle is testable
# through its own interface without loading the full pipeline.
#
# Requires: lib/core/feature-state.sh (fstate_record_pause, fstate_get_pause,
#                                      fstate_transition)

# ── _runner_record_pause ─────────────────────────────────────────────────────
# Internal alias kept for call sites that have not yet migrated to fstate_record_pause.
# pause_kind: "human" (operator must --ack) | "transient" (auto-retry on next run)
_runner_record_pause() {
  fstate_record_pause "$1" "$2" "$3"
}

# ── runner_clear_sentinels ───────────────────────────────────────────────────
# Usage: runner_clear_sentinels <feat_id> <class: transient|all>
# class=transient: removes retry-count and phase3-fix-attempts
# class=all: also removes pause.json (requires --ack at call site)
runner_clear_sentinels() {
  local feat_id="$1"
  local class="${2:-transient}"
  local state_dir="$STATE_DIR/$feat_id"

  [ -d "$state_dir" ] || return 0

  rm -f "$state_dir/retry-count"
  rm -f "$state_dir/phase3-fix-attempts"
  info "Sentinels cleared (transient) for $feat_id"

  if [ "$class" = "all" ]; then
    rm -f "$state_dir/pause.json"
    info "Sentinels cleared (human) for $feat_id"
  fi
}

# ── run_feature_resume ───────────────────────────────────────────────────────
# Usage: run_feature_resume <feat_id> [--ack]
# Re-enters a paused feature from its last checkpoint phase.
# --ack is required for human-class pauses.
run_feature_resume() {
  local feat_id="$1"
  local ack=false
  [ "${2:-}" = "--ack" ] && ack=true

  local results_file="$STATE_DIR/$feat_id/results.json"
  if [ ! -f "$results_file" ]; then
    err "resume: no results.json for $feat_id — has it run at all?"
    return 1
  fi

  local pause_kind
  local reason
  pause_kind=$(fstate_get_pause "$feat_id" "pause_kind")
  reason=$(fstate_get_pause "$feat_id" "reason")
  pause_kind="${pause_kind:-transient}"

  if [ "$pause_kind" = "human" ] && [ "$ack" != "true" ]; then
    err "resume: $feat_id is paused with pause_kind=human (reason: $reason)"
    err "Use --resume-paused $feat_id --ack to acknowledge and resume."
    return 1
  fi

  info "Resuming $feat_id (pause_kind: $pause_kind, reason: $reason)"
  runner_clear_sentinels "$feat_id" "$( [ "$pause_kind" = "human" ] && echo all || echo transient )"

  # Determine the next unfinished phase from checkpoint.json
  local checkpoint_file="$STATE_DIR/$feat_id/checkpoint.json"
  local resume_phase="phase0"
  if [ -f "$checkpoint_file" ]; then
    resume_phase=$(node -e "
      const cp = JSON.parse(require('fs').readFileSync('$checkpoint_file','utf-8'));
      const phases = ['phase0','phase1','phase2','phase3','phase4'];
      const last = phases.slice().reverse().find(p => cp[p] && cp[p].status === 'complete');
      const next = last ? phases[phases.indexOf(last)+1] : phases[0];
      console.log(next || 'done');
    " 2>/dev/null || echo "phase0")
  fi

  if [ "$resume_phase" = "done" ]; then
    info "$feat_id appears complete (all phases done). Nothing to resume."
    return 0
  fi

  info "Resuming $feat_id from $resume_phase"

  local title
  title=$(node -p "try{JSON.parse(require('fs').readFileSync('$results_file','utf-8')).title||'$feat_id'}catch(e){'$feat_id'}" \
    2>/dev/null || echo "$feat_id")

  export RUNNER_RESUME_FROM="$resume_phase"
  run_feature "$feat_id" "$title" "" "medium" "" "" "1" "1"
  unset RUNNER_RESUME_FROM
}
