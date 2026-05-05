#!/bin/bash
# lib/ops/telemetry.sh — Opt-in anonymous run-outcome telemetry (E3)
#
# Consent file: ~/.monozukuri/telemetry.json  { opted_in: bool, decided_at: ISO }
# Endpoint:     $MONOZUKURI_TELEMETRY_ENDPOINT (HTTPS; no-op when unset)
#
# Payload sent per run (no file paths, no prompt content, no project names):
#   { version, os, agent, features_completed, features_paused,
#     features_failed, top_error_class, total_cost_usd }
#
# Best-effort: background curl, max 5s, silent failure, no retries.
# Privacy: users can opt-out at any time with: monozukuri telemetry --opt-out

_TELEMETRY_FILE="${_TELEMETRY_FILE:-${HOME}/.monozukuri/telemetry.json}"

# telemetry_is_opted_in — returns 0 if user has opted in, 1 otherwise
telemetry_is_opted_in() {
  [ -f "$_TELEMETRY_FILE" ] || return 1
  local opted_in
  opted_in=$(node -p "
    try { JSON.parse(require('fs').readFileSync('$_TELEMETRY_FILE','utf-8')).opted_in; }
    catch(e) { false; }
  " 2>/dev/null || echo "false")
  [ "$opted_in" = "true" ]
}

# telemetry_has_decided — returns 0 if user has already answered the prompt
telemetry_has_decided() {
  [ -f "$_TELEMETRY_FILE" ]
}

# telemetry_prompt — ask once on first run (TTY only; skips silently otherwise)
telemetry_prompt() {
  telemetry_has_decided && return 0

  # Non-interactive or no TTY: default to no without prompting
  if [ "${OPT_NON_INTERACTIVE:-false}" = "true" ] || [ ! -t 0 ]; then
    _telemetry_save_consent false
    return 0
  fi

  printf '\n'
  printf '  Monozukuri can send anonymous run-outcome metrics to help improve the tool.\n'
  printf '  No file paths, prompts, or project names are included.\n'
  printf '  You can opt out at any time: monozukuri telemetry --opt-out\n'
  printf '\n'
  printf '  Send anonymous metrics? (y/N): '
  local ans
  read -r ans
  case "${ans:-N}" in
    [yY]*) _telemetry_save_consent true  ;;
    *)     _telemetry_save_consent false ;;
  esac
}

_telemetry_save_consent() {
  local opted_in="$1"
  mkdir -p "$(dirname "$_TELEMETRY_FILE")"
  node -e "
    const fs = require('fs');
    fs.writeFileSync('$_TELEMETRY_FILE', JSON.stringify({
      opted_in: $opted_in,
      decided_at: new Date().toISOString()
    }, null, 2));
  " 2>/dev/null || true
}

# telemetry_send <payload_json> — fire-and-forget background POST
# No-op when: user not opted in, endpoint not configured, curl missing.
telemetry_send() {
  local payload="${1:-}"
  telemetry_is_opted_in || return 0

  local endpoint="${MONOZUKURI_TELEMETRY_ENDPOINT:-}"
  [ -z "$endpoint" ] && return 0
  command -v curl &>/dev/null || return 0

  ( curl -s -X POST "$endpoint" \
      -H "Content-Type: application/json" \
      --data-raw "$payload" \
      --max-time 5 \
      >/dev/null 2>&1 ) &
}

# telemetry_build_payload — build the JSON payload from run outcome vars
# Caller sets: TELEMETRY_AGENT, TELEMETRY_COMPLETED, TELEMETRY_PAUSED,
#              TELEMETRY_FAILED, TELEMETRY_TOP_ERROR, TELEMETRY_COST_USD
telemetry_build_payload() {
  local version="${MONOZUKURI_VERSION:-unknown}"
  local os_name
  os_name=$(uname -s 2>/dev/null | tr '[:upper:]' '[:lower:]' || echo "unknown")

  node -p "
    JSON.stringify({
      version:            '${version}',
      os:                 '${os_name}',
      agent:              '${TELEMETRY_AGENT:-unknown}',
      features_completed: parseInt('${TELEMETRY_COMPLETED:-0}', 10),
      features_paused:    parseInt('${TELEMETRY_PAUSED:-0}',    10),
      features_failed:    parseInt('${TELEMETRY_FAILED:-0}',    10),
      top_error_class:    '${TELEMETRY_TOP_ERROR:-none}',
      total_cost_usd:     parseFloat('${TELEMETRY_COST_USD:-0}') || 0
    })
  " 2>/dev/null || echo '{}'
}

# telemetry_set_consent <true|false> — update consent file (used by cmd/telemetry.sh)
telemetry_set_consent() {
  _telemetry_save_consent "$1"
}

# telemetry_status_text — print human-readable consent status
telemetry_status_text() {
  if ! telemetry_has_decided; then
    printf 'Telemetry: not yet decided (will prompt on next run)\n'
    return
  fi
  if telemetry_is_opted_in; then
    printf 'Telemetry: opted in\n'
    local endpoint="${MONOZUKURI_TELEMETRY_ENDPOINT:-not configured}"
    printf '  Endpoint: %s\n' "$endpoint"
  else
    printf 'Telemetry: opted out\n'
  fi
  local decided
  decided=$(node -p "
    try { JSON.parse(require('fs').readFileSync('$_TELEMETRY_FILE','utf-8')).decided_at; }
    catch(e) { 'unknown'; }
  " 2>/dev/null || echo "unknown")
  printf '  Decided:  %s\n' "$decided"
}
