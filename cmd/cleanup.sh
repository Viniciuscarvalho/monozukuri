#!/bin/bash
# cmd/cleanup.sh — sub_clean(): remove all worktrees and reset state
# Sourced by orchestrate.sh; inherits SCRIPT_DIR, LIB_DIR, CMD_DIR,
# SCRIPTS_DIR, PROJECT_ROOT, ROOT_DIR, CONFIG_DIR, STATE_DIR, RESULTS_DIR,
# and all OPT_* variables.

sub_clean() {
  source "$LIB_DIR/core/worktree.sh"
  source "$LIB_DIR/memory/memory.sh"

  banner "Cleaning orchestrator state"

  wt_cleanup_all
  mem_reset
  rm -rf "$STATE_DIR" "$RESULTS_DIR"
  mkdir -p "$STATE_DIR" "$RESULTS_DIR"

  info "All state cleared. Ready for a fresh run."
}
