#!/bin/bash
# lib/agent/thin-shell-base.sh — Shared base for thin-shell CLI adapters.
#
# Thin-shell adapters (codex, gemini, kiro) all follow the same pattern:
# pipe prompt to <cli> [flags] -. This base provides the shared agent_run_phase,
# agent_estimate_tokens, and agent_report_cost implementations so each adapter
# manifest only declares its per-adapter hooks.
#
# Required hooks (must be defined by the adapter manifest before sourcing this file,
# OR by overriding after sourcing — the former is the standard pattern):
#
#   _thin_shell_invoke <prompt> <log_file> <feat_id> <wt_path>
#       Invokes the CLI: cd wt_path, pipe prompt to the CLI via stdin.
#       Must propagate the CLI's exit code.
#
#   _thin_shell_auth_check <log_file>
#       Returns 0 if the log contains an auth-expiry marker (signals exit 15).
#       Default implementation (below) returns 1 (no auth check).
#
#   _thin_shell_pre_phase <feat_id> <wt_path> <log_file> <phase>
#       Called before the normal rendered-prompt path. If it handles the phase
#       itself (e.g. kiro native-spec workflow), it returns 0 (handled+success)
#       or a non-zero exit code (handled+failed). Return 99 (sentinel) to signal
#       "not handled" — the base then proceeds to the rendered-prompt path.
#       Default implementation (below) returns 99.

# op_timeout is sourced from lib/core/util.sh by pipeline.sh before this adapter loads.
if ! declare -f op_timeout &>/dev/null; then
  op_timeout() { local _secs="$1"; shift; "$@"; }
fi

# adapter_tee is sourced from lib/cli/emit.sh by pipeline.sh before this adapter loads.
if ! declare -f adapter_tee &>/dev/null; then
  adapter_tee() {
    local _f="$1" _tmp _status
    shift
    [ "${1:-}" = "--" ] && shift
    _tmp=$(mktemp)
    "$@" > "$_tmp" 2>&1
    _status=$?
    tee "$_f" < "$_tmp"
    rm -f "$_tmp"
    return "$_status"
  }
fi

# Default hook implementations — adapters override by defining these AFTER sourcing this file.
_thin_shell_auth_check() { return 1; }
_thin_shell_pre_phase()  { return 99; }

agent_estimate_tokens() {
  local prompt; prompt=$(cat)
  if declare -f cost_estimate_tokens &>/dev/null; then
    cost_estimate_tokens "$prompt"
  else
    printf '%d\n' $(( ${#prompt} / 4 ))
  fi
}

agent_report_cost() {
  if declare -f cost_report &>/dev/null; then
    cost_report
  else
    echo "0.00"
  fi
}

agent_run_phase() {
  local feat_id="${MONOZUKURI_FEATURE_ID:?agent_run_phase: MONOZUKURI_FEATURE_ID not set}"
  local wt_path="${MONOZUKURI_WORKTREE:?agent_run_phase: MONOZUKURI_WORKTREE not set}"
  local log_file="${MONOZUKURI_LOG_FILE:-/tmp/monozukuri-${feat_id}-$(date +%s).log}"
  local phase="${MONOZUKURI_PHASE:-prd}"

  # fix-schema / fix-retry: same invocation, different default fallback prompt.
  if [[ "$phase" == "fix-schema" || "$phase" == "fix-retry" ]]; then
    local _default_ctx="Fix the failing tests."
    [ "$phase" = "fix-schema" ] && _default_ctx="Rewrite the artifact with all required sections."
    local fix_context="${MONOZUKURI_FIX_CONTEXT:-$_default_ctx}"
    local exit_code=0
    _thin_shell_invoke "$fix_context" "$log_file" "$feat_id" "$wt_path" || exit_code=$?
    _thin_shell_auth_check "$log_file" && return 15
    if [ "$exit_code" -ne 0 ] && [ -n "${MONOZUKURI_ERROR_FILE:-}" ]; then
      printf '{"class":"phase","code":"%s-failed","message":"%s %s exited with code %d"}\n' \
        "$phase" "$(agent_name)" "$phase" "$exit_code" \
        > "$MONOZUKURI_ERROR_FILE" 2>/dev/null || true
    fi
    return "$exit_code"
  fi

  # Pre-phase hook: return 99 = not handled; anything else = handled (use that exit code).
  _thin_shell_pre_phase "$feat_id" "$wt_path" "$log_file" "$phase"
  local _pre_rc=$?
  [ "$_pre_rc" -ne 99 ] && return "$_pre_rc"

  local rendered_prompt
  if declare -f render_phase_prompt &>/dev/null; then
    local _agent_raw="${MONOZUKURI_AGENT:-}"
    local _agent_norm
    _agent_norm=$(printf '%s' "$_agent_raw" | tr '[:lower:]-' '[:upper:]_')
    local _phase_norm
    _phase_norm=$(printf '%s' "$phase" | tr '[:lower:]' '[:upper:]')
    local _override_var="CFG_AGENTS_${_agent_norm}_SKILLS_${_phase_norm}"
    local _override="${!_override_var:-}"
    rendered_prompt=$(render_phase_prompt "$phase" "${_override}")
  else
    rendered_prompt="Implement feature ${feat_id}."
  fi

  local exit_code=0
  _thin_shell_invoke "$rendered_prompt" "$log_file" "$feat_id" "$wt_path" || exit_code=$?
  _thin_shell_auth_check "$log_file" && return 15
  if [ "$exit_code" -eq 0 ] && declare -f memory_v2_mark_phase_success &>/dev/null; then
    memory_v2_mark_phase_success "$phase" 2>/dev/null || true
  fi
  return "$exit_code"
}
