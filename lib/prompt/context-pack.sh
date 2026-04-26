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

  # Prepend project convention records (AGENTS.md, CLAUDE.md, etc.) when available.
  # Conventions are a separate read-only dataset — never written to the learning store.
  if ! declare -f read_project_conventions &>/dev/null; then
    local _conv_sh
    _conv_sh="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/../agent/conventions.sh"
    [[ -f "$_conv_sh" ]] && source "$_conv_sh" 2>/dev/null || true
  fi
  if ! declare -f measure_tokens &>/dev/null; then
    local _measure_sh
    _measure_sh="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/../../lib/run/measure.sh"
    [[ -f "$_measure_sh" ]] && source "$_measure_sh" 2>/dev/null || true
    # Also try relative to LIB_DIR
    if ! declare -f measure_tokens &>/dev/null && [[ -n "${LIB_DIR:-}" ]]; then
      [[ -f "$LIB_DIR/run/measure.sh" ]] && source "$LIB_DIR/run/measure.sh" 2>/dev/null || true
    fi
  fi
  if declare -f read_project_conventions &>/dev/null && [[ -n "${ROOT_DIR:-}" ]]; then
    local _conv_json
    _conv_json=$(read_project_conventions "$ROOT_DIR" 2>/dev/null || echo '[]')
    if [[ "$_conv_json" != "[]" && -n "$_conv_json" ]]; then
      # Ask the active adapter which files it reads natively (optional, fallback []).
      local _native_files='[]'
      if declare -f agent_native_context_files &>/dev/null; then
        _native_files=$(agent_native_context_files 2>/dev/null || echo '[]')
      fi

      # Conventions from native files are replaced with a single reference line.
      # Conventions from non-native files are injected in full.
      local _inject _native_refs _conv_learnings
      _inject=$(jq --argjson native "$_native_files" \
        '[.[] | select(.source.file as $f | ($native | index($f)) == null)]' \
        <<<"$_conv_json" 2>/dev/null || echo '[]')

      _native_refs=$(jq -n --argjson native "$_native_files" \
        '$native | if length > 0 then
          [.[] | {summary: ("See " + . + " for additional conventions")}]
        else [] end' 2>/dev/null || echo '[]')

      _conv_learnings=$(jq \
        '[.[] | {summary: ("[" + .source.section + "] " + .body)}]' \
        <<<"$_inject" 2>/dev/null || echo '[]')

      # Measure: record token counts for economics reporting
      if declare -f measure_tokens &>/dev/null; then
        local _injected_tokens _suppressed_count
        _injected_tokens=$(jq '[.[] | .body | length] | add // 0' <<<"$_inject")
        _suppressed_count=$(jq --argjson native "$_native_files" \
          '[.[] | select(.source.file as $f | ($native | index($f)) != null)] | length' \
          <<<"$_conv_json" 2>/dev/null || echo '0')
        measure_tokens "conventions-injected"   "$(jq -r '[.[].summary] | join(" ")' <<<"$_conv_learnings")"
        measure_tokens "conventions-suppressed" "$_suppressed_count conventions suppressed"
      fi

      learnings_json=$(jq -n \
        --argjson inject "$_conv_learnings" \
        --argjson refs   "$_native_refs" \
        --argjson store  "$learnings_json" \
        '$inject + $refs + $store')
    fi
  fi

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
