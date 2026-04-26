#!/bin/bash
# lib/prompt/render.sh — Render a phase prompt template.
#
# Usage (source this file, then call):
#   source "$LIB_DIR/prompt/render.sh"
#   MONOZUKURI_FEATURE_ID=feat-001 FEATURE_TITLE="Add login" \
#     render_phase_prompt prd > /tmp/prd-prompt.md
#
# Rich rendering (prd/techspec) — set CONTEXT_JSON to a context-pack JSON file:
#   CONTEXT_JSON=/path/to/ctx.json render_phase_prompt prd > /tmp/prd-prompt.md
#
# Recognised tokens ({{TOKEN}} in templates):
#   Sed path (no CONTEXT_JSON):
#     MONOZUKURI_FEATURE_ID  FEATURE_ID  MONOZUKURI_PHASE  MONOZUKURI_AUTONOMY
#     MONOZUKURI_WORKTREE    MONOZUKURI_RUN_DIR  MONOZUKURI_MODEL
#     FEATURE_TITLE          FEATURE_DESCRIPTION
#   Node path (CONTEXT_JSON set):
#     All keys in the JSON file; arrays expanded via {{#each key}}...{{/each}}

_RENDER_SH_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# _render_sed_escape VAL — escapes a value for safe insertion into a sed s|...|RHS|
_render_sed_escape() {
  printf '%s' "$1" | sed 's/\\/\\\\/g; s/|/\\|/g'
}

# _render_with_node TMPL_FILE CTX_FILE — render template via node.js.
# Expands {{#each key}}...{{/each}} loops and substitutes uppercase context keys.
# Unknown tokens (agent fill-ins like {{PROBLEM_STATEMENT}}) are left intact.
_render_with_node() {
  local tmpl="$1" ctx_file="$2"
  MNZK_TMPL="$tmpl" MNZK_CTX="$ctx_file" node -e '
    const fs = require("fs");
    const tmpl = fs.readFileSync(process.env.MNZK_TMPL, "utf-8");
    const ctx = JSON.parse(fs.readFileSync(process.env.MNZK_CTX, "utf-8"));
    let out = tmpl.replace(/\{\{#each ([^}]+)\}\}([\s\S]*?)\{\{\/each\}\}/g, (_, key, block) => {
      const arr = ctx[key.trim()];
      if (!Array.isArray(arr) || !arr.length) return "";
      return arr.map(item => block.replace(/\{\{this\.([^}]+)\}\}/g, (m, f) =>
        item[f.trim()] !== undefined ? String(item[f.trim()]) : m
      )).join("");
    });
    out = out.replace(/\{\{([A-Z_][A-Z0-9_]*)\}\}/g, (m, k) =>
      ctx[k] !== undefined ? String(ctx[k]) : m
    );
    process.stdout.write(out);
  '
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

  # Rich rendering path: node + context JSON (prd/techspec phases)
  if [[ -n "${CONTEXT_JSON:-}" ]] && [[ -f "${CONTEXT_JSON}" ]] && command -v node &>/dev/null; then
    _render_with_node "$tmpl" "$CONTEXT_JSON"
    return $?
  fi

  # Legacy sed rendering path (backward compat)
  sed \
    -e "s|{{MONOZUKURI_FEATURE_ID}}|$(_render_sed_escape "${MONOZUKURI_FEATURE_ID:-}")|g" \
    -e "s|{{FEATURE_ID}}|$(_render_sed_escape "${MONOZUKURI_FEATURE_ID:-}")|g" \
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
