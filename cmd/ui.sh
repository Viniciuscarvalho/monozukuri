#!/bin/bash
# cmd/ui.sh — Launch the monozukuri web dashboard (localhost only, opt-in)
#
# Usage:
#   monozukuri ui            — connects to the most recent run
#   monozukuri ui <run-id>  — connects to a specific run by UUID

sub_ui() {
  local run_id="${1:-}"
  local runs_dir="${HOME}/.monozukuri/runs"

  if [ -z "$run_id" ]; then
    run_id=$(ls -t "$runs_dir" 2>/dev/null | head -1)
    if [ -z "$run_id" ]; then
      err "No runs found in $runs_dir — start a run first: monozukuri run"
      exit 1
    fi
  fi

  local events_file="$runs_dir/$run_id/events.jsonl"
  if [ ! -f "$events_file" ]; then
    err "Run '$run_id' not found at $events_file"
    err "Available runs: $(ls "$runs_dir" 2>/dev/null | head -5 | tr '\n' ' ')"
    exit 1
  fi

  local server_script="$LIB_DIR/ui/server.js"
  if [ ! -f "$server_script" ]; then
    err "Dashboard server not found: $server_script"
    exit 1
  fi

  node "$server_script" "$events_file" "$run_id"
}
