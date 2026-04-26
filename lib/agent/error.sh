#!/bin/bash
# lib/agent/error.sh — Adapter error envelope and classification (ADR-013)
#
# Provides a structured error envelope for agent failures:
#   {class: transient|phase|fatal|unknown, code, message, retryable_after?}
#
# Adapters may write a structured error to $MONOZUKURI_ERROR_FILE.
# The classifier falls back to log inspection and exit-code heuristics.
#
# Public interface:
#   agent_error_classify <exit_code> <log_file> [error_file]
#   agent_error_field <envelope_json> <field>

# agent_error_classify <exit_code> <log_file> [error_file]
# Prints a JSON error envelope to stdout. Never fails itself.
agent_error_classify() {
  local exit_code="$1"
  local log_file="${2:-}"
  local error_file="${3:-${MONOZUKURI_ERROR_FILE:-}}"

  # Adapter wrote a structured error — validate and trust it
  if [ -n "$error_file" ] && [ -f "$error_file" ]; then
    local adapter_class
    adapter_class=$(node -p \
      "try{JSON.parse(require('fs').readFileSync('$error_file','utf-8')).class||''}catch(e){''}" \
      2>/dev/null || echo "")
    if echo "$adapter_class" | grep -qE "^(transient|phase|fatal|unknown)$"; then
      cat "$error_file"
      return 0
    fi
  fi

  # Timeout exit codes (op_timeout uses 124; SIGKILL produces 137)
  if [ "$exit_code" -eq 124 ] || [ "$exit_code" -eq 137 ]; then
    printf '{"class":"transient","code":"timeout","message":"Agent timed out (exit %d)","retryable_after":0}\n' \
      "$exit_code"
    return 0
  fi

  # Inspect log tail for signal patterns
  local log_tail=""
  if [ -n "$log_file" ] && [ -f "$log_file" ]; then
    log_tail=$(tail -100 "$log_file" 2>/dev/null || echo "")
  fi

  # Rate limit
  if echo "$log_tail" | grep -qiE "rate.?limit|too many requests|429|retry.?after"; then
    local retry_after=600
    local extracted
    extracted=$(echo "$log_tail" | grep -iE "retry.?after:[[:space:]]*[0-9]+" \
      | grep -Eo "[0-9]+" | tail -1 || echo "")
    [ -n "$extracted" ] && retry_after="$extracted"
    printf '{"class":"transient","code":"rate-limit","message":"Rate limit exceeded","retryable_after":%d}\n' \
      "$retry_after"
    return 0
  fi

  # Auth failure
  if echo "$log_tail" | grep -qiE "unauthorized|authentication|401|invalid.api.key|not authenticated"; then
    printf '{"class":"fatal","code":"auth-failure","message":"Authentication failed — run: claude auth login"}\n'
    return 0
  fi

  # Tool / executable missing
  if echo "$log_tail" | grep -qiE "command not found|no such file or directory|executable not found"; then
    printf '{"class":"fatal","code":"tool-missing","message":"Required tool not found in PATH"}\n'
    return 0
  fi

  # Default: unknown (policy table treats as phase per ADR-013 §2)
  printf '{"class":"unknown","code":"exit-%d","message":"Agent exited with code %d"}\n' \
    "$exit_code" "$exit_code"
}

# agent_error_field <envelope_json> <field>
# Extracts a single field from a JSON error envelope string.
agent_error_field() {
  local envelope="$1"
  local field="$2"
  printf '%s' "$envelope" | node -p \
    "try{JSON.parse(require('fs').readFileSync('/dev/stdin','utf-8'))['$field']||''}catch(e){''}" \
    2>/dev/null || echo ""
}
