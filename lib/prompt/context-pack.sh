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
#
# Dependencies: jq

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

  # Build learnings array: split on newlines, strip "- " / "* " prefixes, skip blanks
  local learnings_json
  learnings_json=$(printf '%s\n' "$learnings_raw" \
    | sed 's/^[[:space:]]*[-*][[:space:]]*//' \
    | grep -v '^[[:space:]]*$' \
    | jq -R '{summary: .}' \
    | jq -s '.' 2>/dev/null || echo '[]')

  jq -n \
    --arg FEATURE_ID      "$feat_id" \
    --arg FEATURE_TITLE   "${FEATURE_TITLE:-}" \
    --arg SOURCE_REF      "${SOURCE_REF:-${ADAPTER:-features.md}}" \
    --arg DATE            "$(date +%Y-%m-%d)" \
    --arg STATUS          "draft" \
    --arg STACK           "${PROJECT_STACK:-${DETECTED_STACK:-unknown}}" \
    --arg LANGUAGES       "${PROJECT_LANGUAGES:-${STACK_LANGUAGES:-}}" \
    --arg FRAMEWORKS      "${PROJECT_FRAMEWORKS:-${STACK_FRAMEWORKS:-}}" \
    --arg PACKAGE_MANAGER "${PACKAGE_MANAGER:-npm}" \
    --arg TEST_FRAMEWORK  "${TEST_FRAMEWORK:-}" \
    --arg ENTRY_POINTS    "${ENTRY_POINTS:-}" \
    --arg ORIGINAL_PROMPT "${FEATURE_DESCRIPTION:-${FEATURE_TITLE:-}}" \
    --arg MAX_FILES       "${MAX_FILE_CHANGES:-8}" \
    --argjson project_learnings "$learnings_json" \
    '{
      FEATURE_ID:      $FEATURE_ID,
      FEATURE_TITLE:   $FEATURE_TITLE,
      SOURCE_REF:      $SOURCE_REF,
      DATE:            $DATE,
      STATUS:          $STATUS,
      STACK:           $STACK,
      LANGUAGES:       $LANGUAGES,
      FRAMEWORKS:      $FRAMEWORKS,
      PACKAGE_MANAGER: $PACKAGE_MANAGER,
      TEST_FRAMEWORK:  $TEST_FRAMEWORK,
      ENTRY_POINTS:    $ENTRY_POINTS,
      ORIGINAL_PROMPT: $ORIGINAL_PROMPT,
      MAX_FILES:       $MAX_FILES,
      project_learnings: $project_learnings
    }' > "$out_file"
}
