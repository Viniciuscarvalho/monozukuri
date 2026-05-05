#!/bin/bash
# lib/util.sh — Portable utility helpers (ADR-010)

# State schema version written to every status.json / results.json.
# On load: refuse if state_version > this value (written by a newer install).
MONOZUKURI_STATE_VERSION_SUPPORTED=1

# op_timeout <seconds> <command...>
# Wraps command in a timeout. Tries: timeout (Linux) → gtimeout (Homebrew coreutils) → perl alarm.
op_timeout() {
  local secs="$1"; shift
  if command -v timeout &>/dev/null; then
    timeout "$secs" "$@"
  elif command -v gtimeout &>/dev/null; then
    gtimeout "$secs" "$@"
  else
    # perl fallback — available on every macOS installation
    perl -e "alarm $secs; exec @ARGV" -- "$@"
  fi
}
