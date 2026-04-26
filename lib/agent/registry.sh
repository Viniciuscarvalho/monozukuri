#!/bin/bash
# lib/agent/registry.sh — Per-phase adapter routing.
#
# Extends contract.sh with phase-aware dispatch:
#   - prd/techspec: render template → pipe rendered prompt to agent
#   - other phases: existing feature-marker skill path (no change)
#
# Functions:
#   registry_adapter_for_phase PHASE  — echo adapter name for PHASE
#   registry_prepare_phase PHASE FEAT_ID WT_PATH — export MONOZUKURI_PHASE + CONTEXT_JSON
#   registry_dispatch PHASE FEAT_ID WT_PATH — prepare + load + run agent

_REGISTRY_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# registry_adapter_for_phase PHASE — echo adapter name for PHASE.
# Reads PHASE_ADAPTER_<PHASE> env vars set by routing_load (ADR-015);
# falls back to MONOZUKURI_AGENT.
registry_adapter_for_phase() {
  local phase="$1"
  if declare -f routing_adapter_for_phase &>/dev/null; then
    routing_adapter_for_phase "$phase"
  else
    local env_var
    env_var="PHASE_ADAPTER_$(printf '%s' "$phase" | tr '[:lower:]-' '[:upper:]_')"
    local adapter="${!env_var:-}"
    printf '%s\n' "${adapter:-${MONOZUKURI_AGENT:-claude-code}}"
  fi
}

# registry_prepare_phase PHASE FEAT_ID WT_PATH
# For prd/techspec: builds context JSON (if context-pack is loaded) and exports
# MONOZUKURI_PHASE + CONTEXT_JSON for the adapter's render path.
# For other phases: clears those vars so the adapter uses the legacy skill path.
registry_prepare_phase() {
  local phase="$1" feat_id="$2" wt_path="${3:-${MONOZUKURI_WORKTREE:-}}"

  case "$phase" in
    prd|techspec)
      export MONOZUKURI_PHASE="$phase"
      if declare -f context_pack_build &>/dev/null && [ -n "$wt_path" ]; then
        local ctx_file="$wt_path/.monozukuri-ctx-${phase}.json"
        context_pack_build "$feat_id" "$ctx_file" 2>/dev/null && \
          export CONTEXT_JSON="$ctx_file" || true
      fi
      ;;
    *)
      unset MONOZUKURI_PHASE CONTEXT_JSON 2>/dev/null || true
      ;;
  esac
}

# registry_dispatch PHASE FEAT_ID WT_PATH
# Prepares phase env, loads the adapter if needed, and calls agent_run_phase.
registry_dispatch() {
  local phase="$1" feat_id="$2" wt_path="${3:-${MONOZUKURI_WORKTREE:-}}"

  registry_prepare_phase "$phase" "$feat_id" "$wt_path"

  if ! declare -f agent_run_phase &>/dev/null; then
    agent_load "$(registry_adapter_for_phase "$phase")"
  fi

  agent_run_phase
}
