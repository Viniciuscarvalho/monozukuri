#!/bin/bash
# lib/prompt/skill-inject.sh — portable SKILL.md prompt prefixing.
#
# Claude Code consumes mz-* skills natively. Thin-shell adapters such as Codex
# and Gemini only receive a rendered prompt, so this module lets the prompt
# renderer prefix the same phase-specific SKILL.md content in a stable format.

_SKILL_INJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
_SKILL_INJECT_ROOT="$(cd "${_SKILL_INJECT_DIR}/../.." && pwd)"

monozukuri_skill_for_phase() {
  case "${1:-}" in
    prd)      printf '%s\n' "mz-create-prd" ;;
    techspec) printf '%s\n' "mz-create-techspec" ;;
    tasks)    printf '%s\n' "mz-create-tasks" ;;
    code)     printf '%s\n' "mz-execute-task" ;;
    tests)    printf '%s\n' "mz-run-tests" ;;
    pr)       printf '%s\n' "mz-open-pr" ;;
    *)        return 1 ;;
  esac
}

monozukuri_skill_path_for_phase() {
  local phase="${1:-}" skill
  skill=$(monozukuri_skill_for_phase "$phase") || return 1
  printf '%s/skills/%s/SKILL.md\n' "${MONOZUKURI_SKILLS_ROOT:-$_SKILL_INJECT_ROOT}" "$skill"
}

monozukuri_skill_prefix_for_phase() {
  local phase="${1:-}" skill_path skill_name
  skill_name=$(monozukuri_skill_for_phase "$phase") || return 0
  skill_path=$(monozukuri_skill_path_for_phase "$phase") || return 0
  [[ -f "$skill_path" ]] || return 0

  printf -- '## Monozukuri portable skill instructions\n\n'
  printf -- 'The active adapter does not consume Claude Code skills natively. Apply the following canonical phase skill exactly as if the `%s` skill had been invoked.\n\n' "$skill_name"
  printf -- '--- BEGIN %s SKILL.md ---\n' "$skill_name"
  cat "$skill_path"
  printf -- '\n--- END %s SKILL.md ---\n\n' "$skill_name"
}

_monozukuri_skill_capability() {
  local key="$1" fallback="$2" caps
  if declare -f agent_capabilities >/dev/null 2>&1 && command -v jq >/dev/null 2>&1; then
    caps=$(agent_capabilities 2>/dev/null || true)
    if [[ -n "$caps" ]]; then
      printf '%s\n' "$caps" | jq -r --arg key "$key" --arg fallback "$fallback" \
        '.supports as $supports | if ($supports | has($key)) then $supports[$key] else ($fallback == "true") end' 2>/dev/null && return 0
    fi
  fi
  printf '%s\n' "$fallback"
}

_monozukuri_skill_fallback_supported() {
  case "${ADAPTER:-${MONOZUKURI_AGENT:-}}" in
    codex|gemini) printf '%s\n' "true" ;;
    *)            printf '%s\n' "false" ;;
  esac
}

monozukuri_should_inject_skill() {
  local phase="${1:-}"
  case "${MONOZUKURI_SKILL_INJECTION:-auto}" in
    1|true|yes|on) return 0 ;;
    0|false|no|off) return 1 ;;
  esac

  local supported every_turn
  supported=$(_monozukuri_skill_capability "skill_injection" "$(_monozukuri_skill_fallback_supported)")
  [[ "$supported" == "true" ]] || return 1

  if [[ "${MONOZUKURI_MULTI_TURN_ACTIVE:-0}" == "1" && "$phase" != "prd" ]]; then
    every_turn=$(_monozukuri_skill_capability "skill_injection_every_turn" "false")
    [[ "$every_turn" == "true" ]] || return 1
  fi

  return 0
}

monozukuri_inject_skill_prompt() {
  local phase="${1:-}" prompt="${2:-}"
  if ! monozukuri_should_inject_skill "$phase"; then
    printf '%s' "$prompt"
    return 0
  fi

  local prefix
  prefix=$(monozukuri_skill_prefix_for_phase "$phase")
  if [[ -z "$prefix" ]]; then
    printf '%s' "$prompt"
    return 0
  fi
  printf '%s\n\n%s' "$prefix" "$prompt"
}
