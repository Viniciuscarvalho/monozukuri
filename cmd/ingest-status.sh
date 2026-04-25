#!/bin/bash
# cmd/ingest-status.sh — sub_ingest_status(): show active background ingest jobs (ADR-009)
# Sourced by orchestrate.sh; inherits SCRIPT_DIR, LIB_DIR, CMD_DIR,
# SCRIPTS_DIR, PROJECT_ROOT, ROOT_DIR, CONFIG_DIR, STATE_DIR, RESULTS_DIR,
# and all OPT_* variables.

sub_ingest_status() {
  [ -f "$LIB_DIR/run/ingest.sh" ] && source "$LIB_DIR/run/ingest.sh" || true

  banner "Background Ingest Status"
  if declare -f ingest_status &>/dev/null; then
    ingest_status
  else
    info "ingest.sh not loaded — no background ingest infrastructure present."
  fi
}
