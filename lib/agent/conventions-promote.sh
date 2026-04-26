#!/bin/bash
# lib/agent/conventions-promote.sh — Surface learning candidates as convention entries.
#
# Reads promotion_candidate=true entries from project and global learning tiers
# and returns them as convention records (same shape as read_project_conventions).
#
# Public:
#   conventions_list_candidates REPO_ROOT
#       Returns a JSON array of convention records for all active promotion
#       candidates across project and global tiers. Returns [] when none exist.
#
#   conventions_write_promoted REPO_ROOT LEARN_ID
#       Finds the learning entry by ID, writes it to AGENTS.md as a named
#       ## section above the monozukuri generated marker block (or appended
#       when no block exists), creates a timestamped backup, and marks the
#       entry's promotion_candidate=false.

# Source merge.sh once — provides _conventions_backup_create, _conventions_find_marker_line,
# and conventions_merge_insert_above_marker so file-I/O logic lives in one module.
_CONVENTIONS_PROMOTE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
[[ "$(type -t _conventions_backup_create 2>/dev/null)" == "function" ]] || \
  source "${_CONVENTIONS_PROMOTE_DIR}/conventions-merge.sh"

# _lentry_validate ENTRY_JSON
# Checks that all required learning entry fields are present and non-null.
# See schemas/learned.schema.json for the full contract.
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
# Maps a learning entry to a convention record.
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

# conventions_list_candidates REPO_ROOT
# Scans project and global tiers for active promotion candidates.
# Returns a JSON array of convention records.
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
# Prints the entry JSON and tier path separated by a tab, or returns 1 if not found.
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
# Sets promotion_candidate=false on the entry. Uses mkdir-based lock (same
# convention as lib/memory/learning.sh) to avoid concurrent write conflicts.
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
# Writes the learning entry as a named ## section in AGENTS.md.
# Inserts the section above the monozukuri generated marker block (or appends
# when no block exists). Creates a timestamped backup before writing.
# Marks the learning entry promotion_candidate=false on success.
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
