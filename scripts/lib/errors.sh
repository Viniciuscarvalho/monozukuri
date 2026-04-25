#!/bin/bash
# lib/errors.sh — Structured error output
# Source this file; do not execute it directly.
#
# Every user-facing error in Monozukuri goes through monozukuri_error.
# Format:
#   ❌ <what>
#      Why: <one-sentence cause>
#      Fix: <literal command or imperative action>
#
# Exit codes follow lib/exit-codes.sh:
#   1  — user-recoverable (bad config, missing dep, gate rejected)
#   2  — internal / unexpected (worktree corruption, unhandled path)
#   11 — dependency missing
#   12 — size gate rejected
#   13 — cycle gate rejected

monozukuri_error() {
  local what="${1:-}" why="${2:-}" fix="${3:-}" code="${4:-1}"
  printf "\033[31m❌\033[0m %s\n" "$what" >&2
  [ -n "$why" ] && printf "   \033[2mWhy:\033[0m %s\n" "$why" >&2
  [ -n "$fix" ] && printf "   \033[2mFix:\033[0m %s\n" "$fix" >&2
  exit "$code"
}
