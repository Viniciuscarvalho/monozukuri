#!/bin/bash
# cmd/stop.sh — Kill switch for autonomous runs across all projects.
#
# Sentinel file: ~/.monozukuri/STOP
# When present, the pipeline aborts the current run after the active feature
# finishes (no mid-feature kill — worktrees are left clean).
#
# Usage:
#   monozukuri stop --all     create sentinel (halts all running pipelines)
#   monozukuri stop --clear   remove sentinel (allow future runs)
#   monozukuri stop --status  print current sentinel state

_STOP_SENTINEL="${_STOP_SENTINEL:-${HOME}/.monozukuri/STOP}"

sub_stop() {
  local cmd="${1:---status}"
  mkdir -p "$(dirname "$_STOP_SENTINEL")"

  case "$cmd" in
    --all)
      touch "$_STOP_SENTINEL"
      printf 'Kill switch SET — active pipelines will halt after current feature.\n'
      printf 'Clear with: monozukuri stop --clear\n'
      ;;
    --clear)
      rm -f "$_STOP_SENTINEL"
      printf 'Kill switch CLEARED — pipelines may run.\n'
      ;;
    --status)
      if [ -f "$_STOP_SENTINEL" ]; then
        printf 'Kill switch: SET (set at %s)\n' "$(date -r "$_STOP_SENTINEL" 2>/dev/null || stat -c%y "$_STOP_SENTINEL" 2>/dev/null || echo 'unknown')"
      else
        printf 'Kill switch: CLEAR\n'
      fi
      ;;
    *)
      printf 'Usage: monozukuri stop --all | --clear | --status\n' >&2
      return 1
      ;;
  esac
}
