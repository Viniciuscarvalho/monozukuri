#!/bin/bash
# lib/run/policy.sh — Stratified failure policy table (ADR-013)
#
# Maps adapter error envelope classes to concrete run-time actions:
#
#   transient  → rate-limit ladder (sleep/defer/pause-clean) or cross-run retry
#   phase      → one immediate agent reprompt; fatal if sentinel already set
#   unknown    → treated as phase (conservative)
#   fatal      → feature aborted immediately
#
# Rate-limit threshold ladder (ADR-013 §4):
#   retryable_after ≤ 600s (10 min)  → sleep in-run, return 0 (retry now)
#   ≤ 3600s (60 min)                  → defer feature, return 2
#   > 3600s OR all features blocked   → pause-clean, return 3
#
# Return codes from policy_apply:
#   0  caller should re-run agent_run_phase immediately (after sleep/reprompt)
#   1  feature failed — caller should fall through to failure handling
#   2  feature deferred — caller should advance to next feature
#   3  pause-clean — caller should stop the run and emit resume instructions

# policy_apply <feat_id> <error_envelope_json> <wt_path> <log_file>
policy_apply() {
  local feat_id="$1"
  local error_json="$2"
  local wt_path="$3"
  local log_file="${4:-}"

  local class code retryable_after
  class=$(agent_error_field "$error_json" "class")
  code=$(agent_error_field "$error_json" "code")
  retryable_after=$(printf '%s' "$error_json" | node -p \
    "try{const d=JSON.parse(require('fs').readFileSync('/dev/stdin','utf-8'));d.retryable_after||0}catch(e){0}" \
    2>/dev/null || echo "0")

  case "${class:-unknown}" in
    transient)
      if [ "$code" = "rate-limit" ]; then
        policy_handle_rate_limit "$feat_id" "$retryable_after"
        return $?
      fi
      # Non-rate-limit transient (e.g. timeout): cross-run retry via state
      policy_handle_cross_run_retry "$feat_id"
      return $?
      ;;
    phase | unknown)
      policy_handle_phase_reprompt "$feat_id" "$wt_path" "$log_file"
      return $?
      ;;
    fatal)
      warn "Policy: fatal error for $feat_id (code: $code) — feature aborted"
      fstate_transition "$feat_id" "failed" "fatal-error"
      monozukuri_emit feature.failed feature_id "$feat_id" error "$code" 2>/dev/null || true
      return 1
      ;;
    *)
      warn "Policy: unrecognised error class '${class}' for $feat_id — treating as phase"
      policy_handle_phase_reprompt "$feat_id" "$wt_path" "$log_file"
      return $?
      ;;
  esac
}

# policy_handle_rate_limit <feat_id> <retryable_after_seconds>
policy_handle_rate_limit() {
  local feat_id="$1"
  local retryable_after="${2:-600}"

  if [ "$retryable_after" -le 600 ]; then
    info "Policy: rate-limit — sleeping ${retryable_after}s then retrying $feat_id"
    sleep "$retryable_after"
    fstate_transition "$feat_id" "in-progress" "rate-limit-recovered"
    return 0
  fi

  if [ "$retryable_after" -le 3600 ]; then
    info "Policy: rate-limit — deferring $feat_id (retry_after: ${retryable_after}s)"
    fstate_transition "$feat_id" "paused" "rate-limit-defer"
    fstate_record_pause "$feat_id" "transient" "rate-limit-defer:${retryable_after}s"
    return 2
  fi

  warn "Policy: rate-limit > 60min for $feat_id (${retryable_after}s) — pause-clean"
  fstate_transition "$feat_id" "paused" "rate-limit-pause-clean"
  fstate_record_pause "$feat_id" "transient" "rate-limit-pause-clean:${retryable_after}s"
  return 3
}

# policy_handle_cross_run_retry <feat_id>
# Sets retrying state for pick-up on the next monozukuri run.
policy_handle_cross_run_retry() {
  local feat_id="$1"
  local retry_count
  retry_count=$(cat "$STATE_DIR/$feat_id/retry-count" 2>/dev/null || echo "0")
  local max="${MAX_RETRIES:-3}"

  if [ "$retry_count" -lt "$max" ]; then
    retry_count=$((retry_count + 1))
    echo "$retry_count" > "$STATE_DIR/$feat_id/retry-count"
    fstate_transition "$feat_id" "retrying" "retry-$retry_count"
    info "Policy: transient — cross-run retry $retry_count/$max queued for $feat_id"
    return 2
  fi

  warn "Policy: transient retries exhausted ($max) for $feat_id"
  fstate_transition "$feat_id" "failed" "transient-retries-exhausted"
  mem_record_error "$feat_id" "implementation" "FINAL FAILURE: transient-retries-exhausted" 2>/dev/null || true
  return 1
}

# policy_handle_phase_reprompt <feat_id> <wt_path> <log_file>
# Sends a repair prompt to the agent and returns 0 to signal "retry agent_run_phase".
# On second call (sentinel present), returns 1 (exhausted).
policy_handle_phase_reprompt() {
  local feat_id="$1"
  local wt_path="$2"
  local log_file="${3:-}"
  local sentinel="$STATE_DIR/$feat_id/policy-reprompt-done"

  if [ -f "$sentinel" ]; then
    warn "Policy: phase reprompt already used for $feat_id — feature failed"
    fstate_transition "$feat_id" "failed" "phase-reprompt-exhausted"
    mem_record_error "$feat_id" "implementation" "FINAL FAILURE: phase-reprompt-exhausted" 2>/dev/null || true
    return 1
  fi

  touch "$sentinel"
  info "Policy: phase error — one reprompt for $feat_id (ADR-013 §3)"

  local fix_prompt="The previous agent run for feature $feat_id did not complete successfully. Please retry the full feature implementation from scratch."
  if [ -n "$log_file" ] && [ -f "$log_file" ]; then
    local last_errors
    last_errors=$(tail -30 "$log_file" 2>/dev/null || echo "")
    if [ -n "$last_errors" ]; then
      fix_prompt="${fix_prompt}\n\nLast agent output (for context):\n${last_errors}"
    fi
  fi

  local model_flag=""
  local _fix_model="${MODEL_DEFAULT:-}"
  [ "$_fix_model" = "opusplan" ] && _fix_model="opus"
  [ -n "$_fix_model" ] && model_flag="--model $_fix_model"

  local fix_perm_flag=""
  [ "${AUTONOMY:-}" = "full_auto" ] && fix_perm_flag="--permission-mode bypassPermissions"

  (cd "$wt_path" && printf '%b' "$fix_prompt" |
    platform_claude "${SKILL_TIMEOUT_SECONDS:-1800}" $model_flag $fix_perm_flag --print) \
    2>/dev/null || true

  fstate_transition "$feat_id" "in-progress" "phase-reprompt"
  return 0
}
