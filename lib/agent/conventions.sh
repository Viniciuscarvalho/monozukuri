#!/bin/bash
# lib/agent/conventions.sh — Convention lifecycle: read, generate, merge, promote.
#
# Namespace:
#   conventions_detected_sources  REPO_ROOT            — newline list of found files
#   read_project_conventions      REPO_ROOT            — JSON array of convention records
#   conventions_generate_content  REPO_ROOT            — print generated block to stdout
#   conventions_merge_diff        REPO_ROOT BLOCK_FILE — unified diff (no write)
#   conventions_merge_write       REPO_ROOT BLOCK_FILE — write with backup
#   conventions_merge_insert_above_marker REPO_ROOT CONTENT_FILE
#   conventions_restore           REPO_ROOT [BACKUP]   — restore latest (or named) backup
#   conventions_restore_list      REPO_ROOT            — list available backups
#   conventions_list_candidates   REPO_ROOT            — JSON array of promotion candidates
#   conventions_write_promoted    REPO_ROOT LEARN_ID   — write candidate to AGENTS.md
#
# Feature flag: MONOZUKURI_READ_CONVENTIONS=0 disables read_project_conventions.
# Output record shape:
#   { tier, kind, summary, body, source:{file,section,line}, confidence }

# ── Shared constants ──────────────────────────────────────────────────

_CONVENTIONS_MARKER_START='<!-- monozukuri:generated-start v1 -->'
_CONVENTIONS_MARKER_END='<!-- monozukuri:generated-end -->'
_CONVENTIONS_BACKUP_SUBDIR=".monozukuri/conventions-backups"

_CONVENTIONS_SCAN_ORDER=(
  "AGENTS.md"
  ".agents/AGENTS.md"
  "docs/AGENTS.md"
  "CLAUDE.md"
  ".claude/CLAUDE.md"
  "GEMINI.md"
  ".cursorrules"
  ".aiderrules"
  ".windsurfrules"
)

# ── Read-side helpers ─────────────────────────────────────────────────

# _conventions_emit_record SUMMARY BODY FILE LINE
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

# _conventions_parse_file ABS_PATH REL_PATH
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

  if [[ -n "$current_section" && -n "$current_body" ]]; then
    _conventions_emit_record \
      "$current_section" "$current_body" "$rel_path" "$current_line" \
      >> "$tmpjsonl" 2>/dev/null || true
  fi

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

# ── Public: read ──────────────────────────────────────────────────────

# read_project_conventions REPO_ROOT
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

# ── Public: generate ──────────────────────────────────────────────────

# conventions_generate_content REPO_ROOT
conventions_generate_content() {
  local repo_root="${1:?conventions_generate_content: REPO_ROOT required}"

  local project_path="$repo_root/.claude/feature-state/learned.json"
  local global_path="$HOME/.claude/monozukuri/learned/learned.json"

  local project_entries global_entries
  project_entries=$([ -f "$project_path" ] && cat "$project_path" || echo '[]')
  global_entries=$([ -f "$global_path" ] && cat "$global_path" || echo '[]')

  local learnings
  learnings=$(jq -n \
    --argjson proj "$project_entries" \
    --argjson glob "$global_entries" \
    '($proj + $glob)
     | [.[] | select(.archived != true)]
     | group_by(.pattern)
     | [.[] | first]
     | sort_by(-.confidence)' 2>/dev/null || echo '[]')

  local count
  count=$(jq 'length' <<<"$learnings")

  printf '%s\n' "$_CONVENTIONS_MARKER_START"
  printf '<!-- This section is maintained by monozukuri. Manual edits inside these markers will be overwritten on next generate. -->\n'

  local build_cmd="${PROJECT_BUILD_CMD:-}"
  local test_cmd="${PROJECT_TEST_CMD:-}"

  if [[ -n "$build_cmd" ]]; then
    printf '\n## Build\n\nRun: `%s`\n' "$build_cmd"
  fi

  if [[ -n "$test_cmd" ]]; then
    printf '\n## Test\n\nRun: `%s`\n' "$test_cmd"
  fi

  if [[ "$count" -gt 0 ]]; then
    printf '\n## Conventions\n\n'
    jq -r '.[] | "- `" + .pattern + "` → " + .fix' <<<"$learnings"
  fi

  printf '\n%s\n' "$_CONVENTIONS_MARKER_END"
}

# ── Merge helpers ─────────────────────────────────────────────────────

# _conventions_backup_create REPO_ROOT
_conventions_backup_create() {
  local repo_root="$1"
  local agents_md="$repo_root/AGENTS.md"
  local backup_dir="$repo_root/$_CONVENTIONS_BACKUP_SUBDIR"
  mkdir -p "$backup_dir"
  local ts; ts=$(date +%Y%m%dT%H%M%S)
  local backup_file
  backup_file=$(mktemp "$backup_dir/AGENTS.md.${ts}.XXXXX")
  if [[ -f "$agents_md" ]]; then
    cp "$agents_md" "$backup_file"
  fi
  printf '%s' "$backup_file"
}

# _conventions_find_marker_line FILE MARKER
_conventions_find_marker_line() {
  local file="$1"
  local marker="$2"
  grep -n "^${marker}$" "$file" 2>/dev/null | head -1 | cut -d: -f1
}

# _merge_compute REPO_ROOT BLOCK_FILE OUTFILE
_merge_compute() {
  local repo_root="$1"
  local block_file="$2"
  local out_file="$3"
  local agents_md="$repo_root/AGENTS.md"

  if [[ ! -f "$agents_md" ]]; then
    cp "$block_file" "$out_file"
    return 0
  fi

  local start_line end_line total
  start_line=$(_conventions_find_marker_line "$agents_md" "$_CONVENTIONS_MARKER_START")
  end_line=$(_conventions_find_marker_line   "$agents_md" "$_CONVENTIONS_MARKER_END")

  if [[ -n "$start_line" && -z "$end_line" ]]; then
    printf 'Error: AGENTS.md has opening marker but no closing marker. Fix manually.\n' >&2
    return 1
  fi
  if [[ -z "$start_line" && -n "$end_line" ]]; then
    printf 'Error: AGENTS.md has closing marker but no opening marker. Fix manually.\n' >&2
    return 1
  fi

  if [[ -n "$start_line" && -n "$end_line" ]]; then
    total=$(wc -l < "$agents_md")
    local prefix_end=$(( start_line - 1 ))
    local suffix_start=$(( end_line + 1 ))
    {
      if [[ "$prefix_end" -gt 0 ]]; then
        head -n "$prefix_end" "$agents_md"
      fi
      cat "$block_file"
      if [[ "$suffix_start" -le "$total" ]]; then
        tail -n "+$suffix_start" "$agents_md"
      fi
    } > "$out_file"
  else
    cp "$agents_md" "$out_file"
    printf '\n' >> "$out_file"
    cat "$block_file" >> "$out_file"
  fi
}

# ── Public: merge ─────────────────────────────────────────────────────

# conventions_merge_diff REPO_ROOT BLOCK_FILE
conventions_merge_diff() {
  local repo_root="${1:?conventions_merge_diff: REPO_ROOT required}"
  local block_file="${2:?conventions_merge_diff: BLOCK_FILE required}"
  local agents_md="$repo_root/AGENTS.md"

  local tmpout; tmpout=$(mktemp)
  if ! _merge_compute "$repo_root" "$block_file" "$tmpout"; then
    rm -f "$tmpout"; return 1
  fi

  if [[ ! -f "$agents_md" ]]; then
    printf '--- /dev/null\n+++ AGENTS.md (new)\n'
    diff /dev/null "$tmpout" || true
  else
    diff -u "$agents_md" "$tmpout" || true
  fi

  rm -f "$tmpout"
}

# conventions_merge_write REPO_ROOT BLOCK_FILE
conventions_merge_write() {
  local repo_root="${1:?conventions_merge_write: REPO_ROOT required}"
  local block_file="${2:?conventions_merge_write: BLOCK_FILE required}"
  local agents_md="$repo_root/AGENTS.md"

  local backup_file
  backup_file=$(_conventions_backup_create "$repo_root")

  local tmpout; tmpout=$(mktemp)
  if ! _merge_compute "$repo_root" "$block_file" "$tmpout"; then
    rm -f "$tmpout" "$backup_file"
    return 1
  fi

  mv "$tmpout" "$agents_md"
  printf 'Written: %s  (backup: %s)\n' "$agents_md" "$(basename "$backup_file")"
}

# conventions_merge_insert_above_marker REPO_ROOT CONTENT_FILE
conventions_merge_insert_above_marker() {
  local repo_root="${1:?conventions_merge_insert_above_marker: REPO_ROOT required}"
  local content_file="${2:?conventions_merge_insert_above_marker: CONTENT_FILE required}"
  local agents_md="$repo_root/AGENTS.md"

  local backup_file
  backup_file=$(_conventions_backup_create "$repo_root")

  local tmpout; tmpout=$(mktemp)

  if [[ -f "$agents_md" ]]; then
    local start_line
    start_line=$(_conventions_find_marker_line "$agents_md" "$_CONVENTIONS_MARKER_START")
    if [[ -n "$start_line" ]]; then
      local prefix_end=$(( start_line - 1 ))
      {
        [[ "$prefix_end" -gt 0 ]] && head -n "$prefix_end" "$agents_md"
        cat "$content_file"
        tail -n "+${start_line}" "$agents_md"
      } > "$tmpout"
    else
      { cat "$agents_md"; cat "$content_file"; } > "$tmpout"
    fi
  else
    cat "$content_file" > "$tmpout"
  fi

  mv "$tmpout" "$agents_md"
  printf '%s' "$backup_file"
}

# conventions_restore REPO_ROOT [BACKUP]
conventions_restore() {
  local repo_root="${1:?conventions_restore: REPO_ROOT required}"
  local backup_file="${2:-}"
  local agents_md="$repo_root/AGENTS.md"
  local backup_dir="$repo_root/$_CONVENTIONS_BACKUP_SUBDIR"

  if [[ -z "$backup_file" ]]; then
    backup_file=$(ls -t "$backup_dir"/AGENTS.md.* 2>/dev/null | head -1)
    if [[ -z "$backup_file" ]]; then
      printf 'No backups found in: %s\n' "$backup_dir" >&2
      return 1
    fi
  fi

  if [[ ! -f "$backup_file" ]]; then
    printf 'Backup not found: %s\n' "$backup_file" >&2
    return 1
  fi

  if [[ ! -s "$backup_file" ]]; then
    rm -f "$agents_md"
    printf 'Restored: removed %s (it did not exist before generate)\n' "$agents_md"
  else
    cp "$backup_file" "$agents_md"
    printf 'Restored: %s  ← %s\n' "$agents_md" "$(basename "$backup_file")"
  fi
}

# conventions_restore_list REPO_ROOT
conventions_restore_list() {
  local repo_root="${1:?conventions_restore_list: REPO_ROOT required}"
  local backup_dir="$repo_root/$_CONVENTIONS_BACKUP_SUBDIR"

  if [[ ! -d "$backup_dir" ]]; then
    printf 'No backups directory: %s\n' "$backup_dir"
    return 0
  fi

  local files
  files=$(ls -t "$backup_dir"/AGENTS.md.* 2>/dev/null || true)

  if [[ -z "$files" ]]; then
    printf 'No backups in: %s\n' "$backup_dir"
    return 0
  fi

  printf 'Backups (newest first):\n'
  while IFS= read -r f; do
    local size; size=$(wc -c < "$f" | tr -d ' ')
    printf '  %s  (%s bytes)\n' "$(basename "$f")" "$size"
  done <<<"$files"
}

# ── Promote helpers ───────────────────────────────────────────────────

# _lentry_validate ENTRY_JSON
_lentry_validate() {
  local entry="$1"
  local result
  result=$(jq -r '
    . as $e |
    ["id","pattern","fix","tier","confidence","hits","archived","promotion_candidate"]
    | map(select($e[.] == null))
    | if length > 0 then "missing: " + join(", ") else "ok" end
  ' <<<"$entry" 2>/dev/null) || result="parse-error"
  if [[ "$result" != "ok" ]]; then
    printf 'Error: learning entry has invalid shape (%s)\n' "$result" >&2
    return 1
  fi
}

# _promote_candidate_to_record ENTRY_JSON
_promote_candidate_to_record() {
  local entry="$1"
  jq -c '
    . as $e |
    {
      tier:       ($e.tier // "project"),
      kind:       "convention",
      summary:    ($e.pattern | if length > 60 then .[:60] + "…" else . end),
      body:       ("Fix: " + $e.fix + "\n\nPattern: " + $e.pattern),
      source: {
        file:    ("learning-store:" + ($e.tier // "project")),
        section: $e.pattern,
        line:    0
      },
      confidence: ($e.confidence // 0.5)
    }
  ' <<<"$entry" 2>/dev/null
}

# ── Public: promote ───────────────────────────────────────────────────

# conventions_list_candidates REPO_ROOT
conventions_list_candidates() {
  local repo_root="${1:?conventions_list_candidates: REPO_ROOT required}"

  local project_path="$repo_root/.claude/feature-state/learned.json"
  local global_path="$HOME/.claude/monozukuri/learned/learned.json"

  local tmpjsonl
  tmpjsonl=$(mktemp 2>/dev/null) || { echo '[]'; return 0; }

  for tier_path in "$project_path" "$global_path"; do
    [[ -f "$tier_path" ]] || continue
    local candidates
    candidates=$(jq -c \
      '.[] | select(.archived != true and .promotion_candidate == true)' \
      "$tier_path" 2>/dev/null) || continue
    [[ -z "$candidates" ]] && continue
    while IFS= read -r entry; do
      [[ -z "$entry" ]] && continue
      _lentry_validate "$entry" 2>/dev/null || continue
      local record
      record=$(_promote_candidate_to_record "$entry")
      [[ -n "$record" ]] && printf '%s\n' "$record" >> "$tmpjsonl"
    done <<<"$candidates"
  done

  local result
  if [[ -s "$tmpjsonl" ]]; then
    result=$(jq -s 'unique_by(.summary | ascii_downcase)' "$tmpjsonl" 2>/dev/null) || result='[]'
  else
    result='[]'
  fi
  rm -f "$tmpjsonl"
  printf '%s\n' "$result"
}

# _promote_find_entry LEARN_ID REPO_ROOT
_promote_find_entry() {
  local learn_id="$1"
  local repo_root="$2"

  local project_path="$repo_root/.claude/feature-state/learned.json"
  local global_path="$HOME/.claude/monozukuri/learned/learned.json"

  for tier_path in "$project_path" "$global_path"; do
    [[ -f "$tier_path" ]] || continue
    local found
    found=$(jq -c --arg id "$learn_id" \
      '.[] | select(.id == $id and .archived != true)' \
      "$tier_path" 2>/dev/null)
    if [[ -n "$found" ]]; then
      _lentry_validate "$found" || return 1
      printf '%s\t%s' "$found" "$tier_path"
      return 0
    fi
  done
  return 1
}

# _promote_mark_handled LEARN_ID TIER_PATH
_promote_mark_handled() {
  local learn_id="$1"
  local tier_path="$2"

  local lock_dir="${tier_path%.json}.lock"
  local attempts=0
  while ! mkdir "$lock_dir" 2>/dev/null; do
    attempts=$((attempts + 1))
    if [[ "$attempts" -ge 100 ]]; then
      rmdir "$lock_dir" 2>/dev/null || true
      mkdir "$lock_dir" 2>/dev/null || true
      break
    fi
    sleep 0.1
  done

  node -e "
    const fs = require('fs');
    let entries;
    try { entries = JSON.parse(fs.readFileSync('$tier_path', 'utf-8')); } catch(e) { process.exit(0); }
    const e = entries.find(e => e.id === '$learn_id');
    if (e) {
      e.promotion_candidate = false;
      e.promoted_at = new Date().toISOString();
    }
    fs.writeFileSync('$tier_path', JSON.stringify(entries, null, 2));
  " 2>/dev/null || true

  rmdir "$lock_dir" 2>/dev/null || true
}

# conventions_write_promoted REPO_ROOT LEARN_ID
conventions_write_promoted() {
  local repo_root="${1:?conventions_write_promoted: REPO_ROOT required}"
  local learn_id="${2:?conventions_write_promoted: LEARN_ID required}"
  local agents_md="$repo_root/AGENTS.md"

  local found_line
  if ! found_line=$(_promote_find_entry "$learn_id" "$repo_root"); then
    printf 'Error: learning entry not found or already archived: %s\n' "$learn_id" >&2
    return 1
  fi

  local entry tier_path
  entry=$(printf '%s' "$found_line" | cut -f1)
  tier_path=$(printf '%s' "$found_line" | cut -f2)

  local is_candidate
  is_candidate=$(jq -r '.promotion_candidate' <<<"$entry" 2>/dev/null)
  if [[ "$is_candidate" != "true" ]]; then
    printf 'Error: %s is not flagged as a promotion candidate (confidence or hits threshold not met)\n' \
      "$learn_id" >&2
    return 1
  fi

  local pattern fix
  pattern=$(jq -r '.pattern' <<<"$entry" 2>/dev/null)
  fix=$(jq -r '.fix' <<<"$entry" 2>/dev/null)

  local heading
  heading=$(printf '%s' "$pattern" | cut -c1-60)

  local new_section
  new_section=$(printf '\n## %s\n\n%s\n<!-- promoted from learning-store:%s on %s -->\n' \
    "$heading" "$fix" "$learn_id" "$(date -u +%Y-%m-%dT%H:%M:%SZ)")

  local content_tmp; content_tmp=$(mktemp)
  printf '%s\n' "$new_section" > "$content_tmp"

  local backup_file
  backup_file=$(conventions_merge_insert_above_marker "$repo_root" "$content_tmp")
  rm -f "$content_tmp"

  printf 'Written convention "%s" to %s\n' "$heading" "$agents_md"
  printf 'Backup: %s\n' "$(basename "$backup_file")"

  _promote_mark_handled "$learn_id" "$tier_path"
  printf 'Marked %s as promoted (promotion_candidate=false)\n' "$learn_id"

  return 0
}
