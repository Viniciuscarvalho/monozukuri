#!/bin/bash
# cmd/cleanup.sh — sub_clean(): remove all worktrees and reset state
# Sourced by orchestrate.sh; inherits SCRIPT_DIR, LIB_DIR, CMD_DIR,
# SCRIPTS_DIR, PROJECT_ROOT, ROOT_DIR, CONFIG_DIR, STATE_DIR, RESULTS_DIR,
# and all OPT_* variables.

sub_clean() {
  # Destructive confirmation (TTY only; skipped with --non-interactive)
  if [ -t 0 ] && [ "${OPT_NON_INTERACTIVE:-false}" != "true" ]; then
    if command -v gum >/dev/null 2>&1; then
      gum confirm "Remove ALL worktrees and reset state? This cannot be undone." || { info "Aborted."; exit 0; }
    else
      printf "Remove ALL worktrees and reset state? This cannot be undone. [y/N]: "
      read -r _ans
      case "${_ans:-N}" in [yY]*) ;; *) info "Aborted."; exit 0 ;; esac
    fi
  fi

  source "$LIB_DIR/core/worktree.sh"
  source "$LIB_DIR/memory/memory.sh"

  banner "Cleaning orchestrator state"

  wt_cleanup_all
  mem_reset
  rm -rf "$STATE_DIR" "$RESULTS_DIR"
  mkdir -p "$STATE_DIR" "$RESULTS_DIR"

  info "All state cleared. Ready for a fresh run."
}
