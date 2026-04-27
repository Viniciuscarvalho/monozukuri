#!/bin/bash
# lib/agent/contract.sh — Agent adapter contract and dispatcher.
#
# Every adapter must implement six functions:
#   agent_name()            → echo the adapter name (e.g. "claude-code")
#   agent_capabilities()    → echo a JSON capability declaration
#   agent_doctor()          → check binary + auth; exit 0 or print fix and return 1
#   agent_estimate_tokens() → stdin: prompt → stdout: int (estimated tokens)
#   agent_run_phase()       → execute the current phase; reads MONOZUKURI_* env vars
#   agent_report_cost()     → stdin: trace JSON → stdout: USD float
#
# Optional functions (not checked by agent_verify):
#   agent_native_context_files() → echo JSON array of repo-relative paths this
#                                   agent reads on its own (e.g. AGENTS.md, CLAUDE.md).
#                                   Conventions from these files are referenced by path
#                                   rather than re-injected into prompts. Fallback: [].
#                                   Verified per-adapter in test/conformance/agent_native_context.bats.
#   agent_blocker_marker()       → echo an ERE regex that, when matched in the agent log,
#                                   signals the agent paused for human input. The adapter
#                                   must write a class:"human" envelope to MONOZUKURI_ERROR_FILE
#                                   and exit EXIT_AGENT_BLOCKED (21) when this fires. Adapters
#                                   that don't define this function use agent_scan_for_blocker()
#                                   from lib/agent/error.sh as the default scanner.

_AGENT_CONTRACT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# agent_load NAME — source the adapter for NAME into the current shell.
agent_load() {
  local name="${1:-${MONOZUKURI_AGENT:-claude-code}}"
  local adapter="${_AGENT_CONTRACT_DIR}/adapter-${name}.sh"
  if [[ ! -f "$adapter" ]]; then
    printf 'agent_load: no adapter for "%s" (looked in %s)\n' "$name" "${_AGENT_CONTRACT_DIR}" >&2
    return 1
  fi
  # shellcheck source=/dev/null
  source "$adapter"
}

# agent_verify — assert all six contract functions are defined after agent_load.
agent_verify() {
  local missing=0
  for fn in agent_name agent_capabilities agent_doctor \
            agent_estimate_tokens agent_run_phase agent_report_cost; do
    if ! declare -f "$fn" >/dev/null 2>&1; then
      printf 'agent_verify: adapter missing function "%s"\n' "$fn" >&2
      missing=$((missing + 1))
    fi
  done
  return "$missing"
}

# agent_list — print names of all available adapters (one per line).
agent_list() {
  local f base
  for f in "${_AGENT_CONTRACT_DIR}"/adapter-*.sh; do
    [[ -f "$f" ]] || continue
    base="$(basename "$f" .sh)"
    printf '%s\n' "${base#adapter-}"
  done
}

# monozukuri_default_agent — resolved default agent name (from MONOZUKURI_AGENT env).
monozukuri_default_agent() {
  echo "${MONOZUKURI_AGENT:-claude-code}"
}
