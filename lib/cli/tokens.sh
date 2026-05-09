#!/bin/bash
# lib/cli/tokens.sh — Semantic design tokens for monozukuri CLI output.
# Source this AFTER lib/cli/colors.sh (which sets NO_COLOR logic).
# Provides T_* semantic aliases that map to Compozy's visual language.
# Legacy C_* names remain in colors.sh for back-compat.

# Truecolor sequences if supported; fall back to basic ANSI 16 colors.
# Respects NO_COLOR (no-color.org standard). If colors.sh was sourced, C_NC carries its decision.
if [[ -n "${NO_COLOR:-}" ]] || [[ -z "${C_NC:-}" && -z "${COLORTERM:-}" && "${TERM:-dumb}" == "dumb" ]]; then
  # No-color mode — all tokens are empty strings
  T_BRAND='';  T_SUCCESS=''; T_DANGER='';  T_WARNING=''; T_INFO=''
  T_MUTED='';  T_DIM='';     T_BORDER='';  T_SURFACE=''
  T_BOLD='';   T_RESET=''
else
  # Check for 24-bit truecolor support
  if [[ "${COLORTERM:-}" == "truecolor" ]] || [[ "${COLORTERM:-}" == "24bit" ]]; then
    T_BRAND=$'\033[38;2;214;242;74m'    # #d6f24a
    T_SUCCESS=$'\033[38;2;49;213;139m'  # #31d58b
    T_DANGER=$'\033[38;2;255;107;99m'   # #ff6b63
    T_WARNING=$'\033[38;2;245;158;11m'  # #f59e0b
    T_INFO=$'\033[38;2;59;130;246m'     # #3b82f6
    T_MUTED=$'\033[38;2;168;162;158m'   # #a8a29e stone-400
    T_DIM=$'\033[38;2;87;83;78m'        # #57534e stone-600
    T_BORDER=$'\033[38;2;41;37;36m'     # #292524 stone-800
    T_SURFACE=$'\033[48;2;28;25;23m'    # #1c1917 surface-base (bg)
  else
    # 256-color fallback
    T_BRAND=$'\033[38;5;191m'    # closest to #d6f24a
    T_SUCCESS=$'\033[38;5;85m'   # closest to #31d58b
    T_DANGER=$'\033[38;5;203m'   # closest to #ff6b63
    T_WARNING=$'\033[38;5;214m'  # closest to #f59e0b
    T_INFO=$'\033[38;5;75m'      # closest to #3b82f6
    T_MUTED=$'\033[38;5;248m'    # stone-400
    T_DIM=$'\033[38;5;242m'      # stone-600
    T_BORDER=$'\033[38;5;238m'   # stone-800
    T_SURFACE=''
  fi
  T_BOLD=$'\033[1m'
  T_RESET=$'\033[0m'
fi
export T_BRAND T_SUCCESS T_DANGER T_WARNING T_INFO T_MUTED T_DIM T_BORDER T_SURFACE T_BOLD T_RESET

# Box-drawing panel primitives (Compozy-style rounded borders)
# Usage: panel_open "Title"; echo "content"; panel_close
# Width defaults to terminal width minus 2, capped at 78.
_panel_width() {
  local cols="${COLUMNS:-$(tput cols 2>/dev/null || echo 80)}"
  echo $(( cols < 80 ? cols - 2 : 78 ))
}

panel_open() {
  local title="${1:-}"
  local w; w=$(_panel_width)
  local inner=$(( w - 2 ))
  local title_str=""
  if [[ -n "$title" ]]; then
    title_str=" ${T_BOLD}${T_BRAND}${title}${T_RESET} "
    # Subtract visible title length (without ANSI)
    local visible_title=" ${title} "
    inner=$(( inner - ${#visible_title} ))
  fi
  (( inner < 1 )) && inner=1
  local dashes; dashes=$(printf '─%.0s' $(seq 1 $inner))
  printf '%s╭─%s%s%s╮%s\n' "${T_BORDER}" "${title_str}" "${T_BORDER}" "${dashes}" "${T_RESET}"
}

panel_line() {
  printf '%s│%s ' "${T_BORDER}" "${T_RESET}"
}

panel_close() {
  local w; w=$(_panel_width)
  local dashes; dashes=$(printf '─%.0s' $(seq 1 $(( w - 2 )) ))
  printf '%s╰%s╯%s\n' "${T_BORDER}" "${dashes}" "${T_RESET}"
}
