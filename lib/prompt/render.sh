#!/bin/bash
# lib/prompt/render.sh — Render a phase prompt template.
#
# Usage (source this file, then call):
#   source "$LIB_DIR/prompt/render.sh"
#   MONOZUKURI_FEATURE_ID=feat-001 FEATURE_TITLE="Add login" \
#     render_phase_prompt prd > /tmp/prd-prompt.md
#
# Recognised tokens ({{TOKEN}} in templates):
#   MONOZUKURI_FEATURE_ID  MONOZUKURI_PHASE  MONOZUKURI_AUTONOMY
#   MONOZUKURI_WORKTREE    MONOZUKURI_RUN_DIR MONOZUKURI_MODEL
#   FEATURE_TITLE          FEATURE_DESCRIPTION  LEARNINGS_BLOCK

_RENDER_SH_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# _render_sed_escape VAL — escapes a value for safe insertion into a sed s|...|RHS|
_render_sed_escape() {
  # Escape backslashes first, then the RHS delimiter (|), then literal newlines
  printf '%s' "$1" | sed 's/\\/\\\\/g; s/|/\\|/g'
}

# render_phase_prompt PHASE — renders the template for PHASE to stdout.
# Falls back to $MONOZUKURI_PHASE if PHASE is omitted.
render_phase_prompt() {
  local phase="${1:-${MONOZUKURI_PHASE:-prd}}"
  local prompt_dir="${PROMPT_PHASES_DIR:-${_RENDER_SH_DIR}/phases}"
  local tmpl="${prompt_dir}/${phase}.tmpl.md"

  if [[ ! -f "$tmpl" ]]; then
    printf 'render_phase_prompt: no template for phase "%s" (looked in %s)\n' \
      "$phase" "$prompt_dir" >&2
    return 1
  fi

  sed \
    -e "s|{{MONOZUKURI_FEATURE_ID}}|$(_render_sed_escape "${MONOZUKURI_FEATURE_ID:-}")|g" \
    -e "s|{{MONOZUKURI_PHASE}}|$(_render_sed_escape "${phase}")|g" \
    -e "s|{{MONOZUKURI_AUTONOMY}}|$(_render_sed_escape "${MONOZUKURI_AUTONOMY:-supervised}")|g" \
    -e "s|{{MONOZUKURI_WORKTREE}}|$(_render_sed_escape "${MONOZUKURI_WORKTREE:-}")|g" \
    -e "s|{{MONOZUKURI_RUN_DIR}}|$(_render_sed_escape "${MONOZUKURI_RUN_DIR:-}")|g" \
    -e "s|{{MONOZUKURI_MODEL}}|$(_render_sed_escape "${MONOZUKURI_MODEL:-}")|g" \
    -e "s|{{FEATURE_TITLE}}|$(_render_sed_escape "${FEATURE_TITLE:-}")|g" \
    -e "s|{{FEATURE_DESCRIPTION}}|$(_render_sed_escape "${FEATURE_DESCRIPTION:-}")|g" \
    -e "s|{{LEARNINGS_BLOCK}}|$(_render_sed_escape "${LEARNINGS_BLOCK:-No prior learnings.}")|g" \
    "$tmpl"
}
