#!/bin/bash
# lib/prompt/context-pack.sh — Build phase context JSON for template rendering.
#
# Usage:
#   source "$LIB_DIR/prompt/context-pack.sh"
#   context_pack_build feat-001 /path/to/context.json
#
# Output JSON keys consumed by prd.tmpl.md and techspec.tmpl.md:
#   FEATURE_ID, FEATURE_TITLE, SOURCE_REF, DATE, STATUS
#   STACK, LANGUAGES, FRAMEWORKS, PACKAGE_MANAGER, TEST_FRAMEWORK
#   ENTRY_POINTS, ORIGINAL_PROMPT, MAX_FILES
#   project_learnings: [{summary: "..."}]

# context_pack_build FEAT_ID OUT_FILE
# Reads MONOZUKURI_* / PROJECT_* env vars and writes context JSON to OUT_FILE.
context_pack_build() {
  local feat_id="${1:?context_pack_build: FEAT_ID required}"
  local out_file="${2:?context_pack_build: OUT_FILE required}"

  local learnings_raw="${LEARNINGS_BLOCK:-}"
  # Pull from learning store if available
  if declare -f mem_get_learnings &>/dev/null; then
    local _store_learnings
    _store_learnings=$(mem_get_learnings "$feat_id" 2>/dev/null || true)
    [ -n "$_store_learnings" ] && learnings_raw="$_store_learnings"
  fi

  MNZK_FEAT_ID="$feat_id" \
  MNZK_TITLE="${FEATURE_TITLE:-}" \
  MNZK_SOURCE="${SOURCE_REF:-${ADAPTER:-features.md}}" \
  MNZK_STACK="${PROJECT_STACK:-${DETECTED_STACK:-unknown}}" \
  MNZK_LANGS="${PROJECT_LANGUAGES:-${STACK_LANGUAGES:-}}" \
  MNZK_FRAMEWORKS="${PROJECT_FRAMEWORKS:-${STACK_FRAMEWORKS:-}}" \
  MNZK_PKGMGR="${PACKAGE_MANAGER:-npm}" \
  MNZK_TESTFW="${TEST_FRAMEWORK:-}" \
  MNZK_ENTRYPOINTS="${ENTRY_POINTS:-}" \
  MNZK_PROMPT="${FEATURE_DESCRIPTION:-${FEATURE_TITLE:-}}" \
  MNZK_MAXFILES="${MAX_FILE_CHANGES:-8}" \
  MNZK_LEARNINGS="$learnings_raw" \
  MNZK_OUT="$out_file" \
  node -e '
    const env = process.env;
    const project_learnings = (env.MNZK_LEARNINGS || "")
      .split("\n")
      .map(l => l.replace(/^[-*]\s*/, "").trim())
      .filter(Boolean)
      .map(s => ({ summary: s }));
    const ctx = {
      FEATURE_ID:      env.MNZK_FEAT_ID      || "",
      FEATURE_TITLE:   env.MNZK_TITLE        || "",
      SOURCE_REF:      env.MNZK_SOURCE       || "features.md",
      DATE:            new Date().toISOString().slice(0, 10),
      STATUS:          "draft",
      STACK:           env.MNZK_STACK        || "unknown",
      LANGUAGES:       env.MNZK_LANGS        || "",
      FRAMEWORKS:      env.MNZK_FRAMEWORKS   || "",
      PACKAGE_MANAGER: env.MNZK_PKGMGR       || "npm",
      TEST_FRAMEWORK:  env.MNZK_TESTFW       || "",
      ENTRY_POINTS:    env.MNZK_ENTRYPOINTS  || "",
      ORIGINAL_PROMPT: env.MNZK_PROMPT       || "",
      MAX_FILES:       env.MNZK_MAXFILES      || "8",
      project_learnings,
    };
    require("fs").writeFileSync(env.MNZK_OUT, JSON.stringify(ctx, null, 2));
  '
}
