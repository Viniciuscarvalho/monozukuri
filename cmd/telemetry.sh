#!/bin/bash
# cmd/telemetry.sh — monozukuri telemetry subcommand
# Sourced by orchestrate.sh; inherits LIB_DIR and all OPT_* vars.

sub_telemetry() {
  source "$LIB_DIR/ops/telemetry.sh" 2>/dev/null || {
    printf 'error: could not load telemetry module\n' >&2
    exit 1
  }

  local action="${1:-}"
  # Allow --status / --opt-in / --opt-out passed as positional or flag
  case "$action" in
    --opt-in|opt-in)
      telemetry_set_consent true
      printf 'Telemetry: opted in.\n'
      ;;
    --opt-out|opt-out)
      telemetry_set_consent false
      printf 'Telemetry: opted out.\n'
      ;;
    --status|status|"")
      telemetry_status_text
      ;;
    *)
      printf 'Usage: monozukuri telemetry [--status | --opt-in | --opt-out]\n' >&2
      exit 1
      ;;
  esac
}
