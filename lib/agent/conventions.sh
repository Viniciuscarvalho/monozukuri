#!/bin/bash
# lib/agent/conventions.sh — Parse project convention files into learning records.
#
# Scans a repo root for AGENTS.md, CLAUDE.md, and legacy convention files.
# Parses each into structured records for injection into context packs.
#
# Public:
#   read_project_conventions REPO_ROOT    — JSON array of convention records
#   conventions_detected_sources REPO_ROOT — newline list of found files
#
# Output record shape:
#   { tier, kind, summary, body, source:{file,section,line}, confidence }
#
# Feature flag: MONOZUKURI_READ_CONVENTIONS=0 disables all parsing (default: 1).

_CONVENTIONS_SCAN_ORDER=(
  "AGENTS.md"
  ".agents/AGENTS.md"
  "docs/AGENTS.md"
  "CLAUDE.md"
  ".claude/CLAUDE.md"
  ".cursorrules"
  ".aiderrules"
  ".windsurfrules"
)

# _conventions_emit_record SUMMARY BODY FILE LINE
# Writes a single JSON record to stdout. Returns silently if body is blank.
_conventions_emit_record() {
  local summary="$1" body="$2" file="$3" line="$4"
  local trimmed
  trimmed=$(printf '%s' "$body" | sed 's/^[[:space:]]*//' | sed 's/[[:space:]]*$//')
  [[ -z "$trimmed" ]] && return 0
  jq -nc \
    --arg   tier      "project" \
    --arg   kind      "convention" \
    --arg   summary   "$summary" \
    --arg   body      "$trimmed" \
    --arg   file      "$file" \
    --arg   section   "$summary" \
    --argjson line    "$line" \
    --argjson conf    1.0 \
    '{tier:$tier,kind:$kind,summary:$summary,body:$body,
      source:{file:$file,section:$section,line:$line},confidence:$conf}'
}

# _conventions_parse_paragraphs ABS_PATH REL_PATH
# Fallback for files with no ## sections: emit one record per non-blank paragraph.
_conventions_parse_paragraphs() {
  local abs_path="$1" rel_path="$2"
  local paragraph="" para_line=0 line_num=0

  while IFS= read -r line || [[ -n "$line" ]]; do
    line_num=$((line_num + 1))
    if [[ -z "${line// }" ]]; then
      if [[ -n "$paragraph" ]]; then
        local first_line
        first_line=$(printf '%s' "${paragraph%%$'\n'*}" | sed 's/^[[:space:]]*//' | sed 's/[[:space:]]*$//')
        [[ -n "$first_line" ]] && \
          _conventions_emit_record "$first_line" "$paragraph" "$rel_path" "$para_line"
        paragraph=""
      fi
    else
      [[ -z "$paragraph" ]] && para_line=$line_num
      paragraph+="$line"$'\n'
    fi
  done < "$abs_path"

  if [[ -n "$paragraph" ]]; then
    local first_line
    first_line=$(printf '%s' "${paragraph%%$'\n'*}" | sed 's/^[[:space:]]*//' | sed 's/[[:space:]]*$//')
    [[ -n "$first_line" ]] && \
      _conventions_emit_record "$first_line" "$paragraph" "$rel_path" "$para_line"
  fi
}

# _conventions_parse_file ABS_PATH REL_PATH — emit JSON array for one file.
# On parse error: prints warning to stderr and returns [].
_conventions_parse_file() {
  local abs_path="$1" rel_path="$2"
  [[ -f "$abs_path" ]] || { echo '[]'; return 0; }

  local tmpjsonl
  tmpjsonl=$(mktemp 2>/dev/null) || { echo '[]'; return 0; }

  local current_section="" current_body="" current_line=0 line_num=0 has_sections=false

  while IFS= read -r line || [[ -n "$line" ]]; do
    line_num=$((line_num + 1))
    if [[ "$line" =~ ^##[[:space:]]+(.+)$ ]]; then
      has_sections=true
      if [[ -n "$current_section" && -n "$current_body" ]]; then
        _conventions_emit_record \
          "$current_section" "$current_body" "$rel_path" "$current_line" \
          >> "$tmpjsonl" 2>/dev/null || true
      fi
      current_section="${BASH_REMATCH[1]}"
      current_body=""
      current_line=$line_num
    elif [[ -n "$current_section" ]]; then
      current_body+="$line"$'\n'
    fi
  done < "$abs_path"

  # Flush final section
  if [[ -n "$current_section" && -n "$current_body" ]]; then
    _conventions_emit_record \
      "$current_section" "$current_body" "$rel_path" "$current_line" \
      >> "$tmpjsonl" 2>/dev/null || true
  fi

  # Fallback: no ## sections found — split by paragraph
  if [[ "$has_sections" == "false" ]]; then
    _conventions_parse_paragraphs "$abs_path" "$rel_path" >> "$tmpjsonl" 2>/dev/null || true
  fi

  local result
  if [[ -s "$tmpjsonl" ]]; then
    result=$(jq -s '.' "$tmpjsonl" 2>/dev/null) || result='[]'
  else
    result='[]'
  fi
  rm -f "$tmpjsonl"
  printf '%s\n' "$result"
}

# read_project_conventions REPO_ROOT
# Scans all convention files, parses them, and returns a deduped JSON array.
# Returns [] immediately when MONOZUKURI_READ_CONVENTIONS=0.
read_project_conventions() {
  local repo_root="${1:?read_project_conventions: REPO_ROOT required}"
  [[ "${MONOZUKURI_READ_CONVENTIONS:-1}" == "0" ]] && echo '[]' && return 0

  local tmpall
  tmpall=$(mktemp 2>/dev/null) || { echo '[]'; return 0; }

  local found=false
  for rel_path in "${_CONVENTIONS_SCAN_ORDER[@]}"; do
    local abs_path="$repo_root/$rel_path"
    [[ -f "$abs_path" ]] || continue
    found=true
    local file_records
    file_records=$(_conventions_parse_file "$abs_path" "$rel_path" 2>/dev/null) || continue
    [[ "$file_records" == "[]" || -z "$file_records" ]] && continue
    jq -c '.[]' <<<"$file_records" >> "$tmpall" 2>/dev/null || true
  done

  # Include promotion candidates when conventions-promote.sh is loaded.
  if declare -f conventions_list_candidates &>/dev/null; then
    local candidates
    candidates=$(conventions_list_candidates "$repo_root" 2>/dev/null) || candidates='[]'
    local cand_count
    cand_count=$(jq 'length' <<<"$candidates" 2>/dev/null || echo 0)
    if [[ "$cand_count" -gt 0 ]]; then
      jq -c '.[]' <<<"$candidates" >> "$tmpall" 2>/dev/null || true
      found=true
    fi
  fi

  local result
  if [[ "$found" == "true" && -s "$tmpall" ]]; then
    result=$(jq -s 'unique_by(.summary | ascii_downcase)' "$tmpall" 2>/dev/null) || result='[]'
  else
    result='[]'
  fi
  rm -f "$tmpall"
  printf '%s\n' "$result"
}

# conventions_detected_sources REPO_ROOT
# Prints repo-relative paths of convention files that exist (one per line).
conventions_detected_sources() {
  local repo_root="${1:?conventions_detected_sources: REPO_ROOT required}"
  local found=false
  for rel_path in "${_CONVENTIONS_SCAN_ORDER[@]}"; do
    if [[ -f "$repo_root/$rel_path" ]]; then
      found=true
      printf '%s\n' "$rel_path"
    fi
  done
  [[ "$found" == "false" ]] && return 1
  return 0
}
