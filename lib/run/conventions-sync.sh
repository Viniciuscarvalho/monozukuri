#!/bin/bash
# lib/run/conventions-sync.sh — Auto-sync AGENTS.md from learning store after each run.
#
# Activated when conventions.auto_sync: true in config.yaml.
# Runs after run_backlog completes (all features done/failed for this session).
# Never fails the run — all errors are swallowed (best-effort).
#
# Usage:
#   source "$LIB_DIR/run/conventions-sync.sh"
#   conventions_auto_sync "$ROOT_DIR"   # or conventions_auto_sync (uses $ROOT_DIR)
#
# Dependencies: lib/agent/conventions-generate.sh, lib/agent/conventions-merge.sh, jq.

conventions_auto_sync() {
  local repo_root="${1:-${ROOT_DIR:-$(pwd)}}"

  # Gate: only run when explicitly opted in.
  [[ "${CONVENTIONS_AUTO_SYNC:-false}" == "true" ]] || return 0

  local _gen_sh="$LIB_DIR/agent/conventions-generate.sh"
  local _merge_sh="$LIB_DIR/agent/conventions-merge.sh"

  if [[ ! -f "$_gen_sh" || ! -f "$_merge_sh" ]]; then
    return 0
  fi

  # shellcheck source=../agent/conventions-generate.sh
  source "$_gen_sh" 2>/dev/null || return 0
  # shellcheck source=../agent/conventions-merge.sh
  source "$_merge_sh" 2>/dev/null || return 0

  # Skip when no non-archived learnings exist in either tier.
  local _project_path="$repo_root/.claude/feature-state/learned.json"
  local _global_path="$HOME/.claude/monozukuri/learned/learned.json"
  local _has_learnings=false

  for _tier_path in "$_project_path" "$_global_path"; do
    if [[ -f "$_tier_path" ]]; then
      local _count
      _count=$(jq '[.[] | select(.archived != true)] | length' < "$_tier_path" 2>/dev/null || echo 0)
      [[ "$_count" -gt 0 ]] && _has_learnings=true && break
    fi
  done

  [[ "$_has_learnings" == "true" ]] || return 0

  local _block; _block=$(mktemp)
  conventions_generate_content "$repo_root" > "$_block" 2>/dev/null || { rm -f "$_block"; return 0; }
  conventions_merge_write "$repo_root" "$_block" > /dev/null 2>&1 || true
  rm -f "$_block"

  if declare -f info &>/dev/null; then
    info "conventions: AGENTS.md synced from learning store"
  fi

  return 0
}
