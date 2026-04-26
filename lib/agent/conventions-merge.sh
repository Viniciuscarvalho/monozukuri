#!/bin/bash
# lib/agent/conventions-merge.sh — Marker-based merge for AGENTS.md.
#
# Safety contract (enforced before any write):
#   1. Content outside markers is never modified (head/tail splice).
#   2. Conflicting markers (start without end, or end without start) → abort.
#   3. Backup written to .monozukuri/conventions-backups/AGENTS.md.<timestamp>
#      before every write.
#   4. conventions_restore returns the file to its pre-write state.
#
# Usage:
#   source "$LIB_DIR/agent/conventions-merge.sh"
#   conventions_merge_diff                REPO_ROOT BLOCK_FILE  # show unified diff (no write)
#   conventions_merge_write               REPO_ROOT BLOCK_FILE  # write with backup
#   conventions_merge_insert_above_marker REPO_ROOT CONTENT_FILE  # insert section above generated block
#   conventions_restore                   REPO_ROOT [BACKUP]    # restore latest (or named) backup
#   conventions_restore_list              REPO_ROOT             # list available backups
#
# BLOCK_FILE / CONTENT_FILE: path to a file containing content to merge.

_MERGE_MARKER_START='<!-- monozukuri:generated-start v1 -->'
_MERGE_MARKER_END='<!-- monozukuri:generated-end -->'
_MERGE_BACKUP_SUBDIR=".monozukuri/conventions-backups"

# _conventions_backup_create REPO_ROOT
# Creates a timestamped backup of AGENTS.md in the backups subdir.
# Uses a zero-byte sentinel when AGENTS.md does not yet exist (restore removes it).
# Prints the backup file path.
_conventions_backup_create() {
  local repo_root="$1"
  local agents_md="$repo_root/AGENTS.md"
  local backup_dir="$repo_root/$_MERGE_BACKUP_SUBDIR"
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
# Prints the 1-based line number of MARKER in FILE, or empty string if absent.
_conventions_find_marker_line() {
  local file="$1"
  local marker="$2"
  grep -n "^${marker}$" "$file" 2>/dev/null | head -1 | cut -d: -f1
}

# _merge_compute REPO_ROOT BLOCK_FILE OUTFILE
# Computes the merged content and writes it to OUTFILE. Returns 1 on conflict.
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
  start_line=$(_conventions_find_marker_line "$agents_md" "$_MERGE_MARKER_START")
  end_line=$(_conventions_find_marker_line   "$agents_md" "$_MERGE_MARKER_END")

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
    # No markers: append at end with a blank line separator.
    cp "$agents_md" "$out_file"
    printf '\n' >> "$out_file"
    cat "$block_file" >> "$out_file"
  fi
}

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
# Inserts CONTENT_FILE above the generated-start marker in AGENTS.md
# (or appends if no markers exist; writes CONTENT_FILE as the whole file
# if AGENTS.md doesn't exist). Creates a timestamped backup before writing.
# Prints the backup file path.
conventions_merge_insert_above_marker() {
  local repo_root="${1:?conventions_merge_insert_above_marker: REPO_ROOT required}"
  local content_file="${2:?conventions_merge_insert_above_marker: CONTENT_FILE required}"
  local agents_md="$repo_root/AGENTS.md"

  local backup_file
  backup_file=$(_conventions_backup_create "$repo_root")

  local tmpout; tmpout=$(mktemp)

  if [[ -f "$agents_md" ]]; then
    local start_line
    start_line=$(_conventions_find_marker_line "$agents_md" "$_MERGE_MARKER_START")
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

conventions_restore() {
  local repo_root="${1:?conventions_restore: REPO_ROOT required}"
  local backup_file="${2:-}"
  local agents_md="$repo_root/AGENTS.md"
  local backup_dir="$repo_root/$_MERGE_BACKUP_SUBDIR"

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

  # Zero-byte sentinel means the file did not exist before the write.
  if [[ ! -s "$backup_file" ]]; then
    rm -f "$agents_md"
    printf 'Restored: removed %s (it did not exist before generate)\n' "$agents_md"
  else
    cp "$backup_file" "$agents_md"
    printf 'Restored: %s  ← %s\n' "$agents_md" "$(basename "$backup_file")"
  fi
}

conventions_restore_list() {
  local repo_root="${1:?conventions_restore_list: REPO_ROOT required}"
  local backup_dir="$repo_root/$_MERGE_BACKUP_SUBDIR"

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
