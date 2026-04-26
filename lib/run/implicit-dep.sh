#!/bin/bash
# lib/run/implicit-dep.sh — File-overlap detection for parallel feature runs (ADR-015, Gap 7)
#
# Detects file-set overlap between in-flight features to prevent merge conflicts.
# Captures actual files touched post-Code for prediction accuracy learning.
#
# Public functions:
#   overlap_check <feat_id> <files_json_array>  — returns space-separated overlapping feat IDs
#   capture_actual_files <feat_id> <base_sha>   — stores files_actually_touched in state.json

# overlap_check <feat_id> <files_json_array>
# Scans all in_progress worktrees for file-set overlap.
# Returns: space-separated list of overlapping feature IDs (empty if none)
overlap_check() {
  local feat_id="$1"
  local files_json="$2"

  if [ -z "$files_json" ] || [ "$files_json" = "null" ] || [ "$files_json" = "[]" ]; then
    # No files to check, no overlap possible
    return 0
  fi

  # Parse JSON array into bash array
  local files=()
  while IFS= read -r file; do
    [ -n "$file" ] && files+=("$file")
  done < <(echo "$files_json" | node -e "
    const data = JSON.parse(require('fs').readFileSync('/dev/stdin', 'utf-8'));
    if (Array.isArray(data)) {
      data.forEach(f => console.log(f));
    }
  " 2>/dev/null || echo "")

  if [ ${#files[@]} -eq 0 ]; then
    return 0
  fi

  # Find all worktrees with in_progress status (exclude current feature)
  local worktree_dir="${ROOT_DIR:-.}/.monozukuri/worktrees"
  if [ ! -d "$worktree_dir" ]; then
    return 0
  fi

  local overlaps=()

  for wt in "$worktree_dir"/*/; do
    [ ! -d "$wt" ] && continue

    local other_feat
    other_feat=$(basename "$wt")
    [ "$other_feat" = "$feat_id" ] && continue

    local state_file="$wt/state.json"
    [ ! -f "$state_file" ] && continue

    # Check if feature is in_progress
    local status
    status=$(node -e "
      try {
        const state = JSON.parse(require('fs').readFileSync('$state_file', 'utf-8'));
        console.log(state.status || '');
      } catch(e) { console.log(''); }
    " 2>/dev/null || echo "")

    [ "$status" != "in_progress" ] && continue

    # Read files_likely_touched from other feature
    local other_files
    other_files=$(node -e "
      try {
        const state = JSON.parse(require('fs').readFileSync('$state_file', 'utf-8'));
        const files = state.files_likely_touched || [];
        if (Array.isArray(files)) {
          files.forEach(f => console.log(f));
        }
      } catch(e) {}
    " 2>/dev/null || echo "")

    [ -z "$other_files" ] && continue

    # Check for intersection
    local has_overlap=0
    for file in "${files[@]}"; do
      if echo "$other_files" | grep -qxF "$file"; then
        has_overlap=1
        break
      fi
    done

    if [ $has_overlap -eq 1 ]; then
      overlaps+=("$other_feat")
    fi
  done

  # Return space-separated list
  if [ ${#overlaps[@]} -gt 0 ]; then
    echo "${overlaps[*]}"
  fi
}

# capture_actual_files <feat_id> <base_sha>
# Captures actual files touched via git diff and stores in state.json.
# Compares with files_likely_touched to compute prediction accuracy stats.
capture_actual_files() {
  local feat_id="$1"
  local base_sha="$2"

  local worktree_dir="${ROOT_DIR:-.}/.monozukuri/worktrees/$feat_id"
  local state_file="$worktree_dir/state.json"

  if [ ! -d "$worktree_dir" ]; then
    echo "warning: worktree not found for $feat_id" >&2
    return 1
  fi

  if [ ! -f "$state_file" ]; then
    echo "warning: state.json not found for $feat_id" >&2
    return 1
  fi

  # Get actual files touched
  local actual_files
  actual_files=$(cd "$worktree_dir" && git diff --name-only "$base_sha" HEAD 2>/dev/null || echo "")

  if [ -z "$actual_files" ]; then
    echo "warning: no files changed in $feat_id (empty git diff)" >&2
    # Still update state with empty array
    actual_files=""
  fi

  # Convert to JSON array
  local actual_json
  actual_json=$(echo "$actual_files" | node -e "
    const lines = require('fs').readFileSync('/dev/stdin', 'utf-8').trim().split('\n').filter(l => l);
    console.log(JSON.stringify(lines));
  " 2>/dev/null || echo "[]")

  # Read files_likely_touched from state
  local likely_files
  likely_files=$(node -e "
    try {
      const state = JSON.parse(require('fs').readFileSync('$state_file', 'utf-8'));
      const files = state.files_likely_touched || [];
      if (Array.isArray(files)) {
        files.forEach(f => console.log(f));
      }
    } catch(e) {}
  " 2>/dev/null || echo "")

  # Compute overlap stats
  local predicted=0 actual=0 confirmed=0 false_positives=0 false_negatives=0

  if [ -n "$likely_files" ]; then
    predicted=$(echo "$likely_files" | wc -l | tr -d ' ')
  fi

  if [ -n "$actual_files" ]; then
    actual=$(echo "$actual_files" | wc -l | tr -d ' ')
  fi

  # Count confirmed (files in both sets)
  if [ -n "$likely_files" ] && [ -n "$actual_files" ]; then
    while IFS= read -r file; do
      if echo "$actual_files" | grep -qxF "$file"; then
        confirmed=$((confirmed + 1))
      fi
    done <<< "$likely_files"
  fi

  # False positives: predicted but not actually touched
  false_positives=$((predicted - confirmed))
  [ $false_positives -lt 0 ] && false_positives=0

  # False negatives: actually touched but not predicted
  false_negatives=$((actual - confirmed))
  [ $false_negatives -lt 0 ] && false_negatives=0

  # Update state.json with actual files and stats
  node -e "
    const fs = require('fs');
    const statePath = '$state_file';
    let state;
    try {
      state = JSON.parse(fs.readFileSync(statePath, 'utf-8'));
    } catch(e) {
      state = {};
    }

    const actualFiles = $actual_json;
    state.files_actually_touched = actualFiles;
    state.overlap_stats = {
      predicted: $predicted,
      actual: $actual,
      confirmed: $confirmed,
      false_positives: $false_positives,
      false_negatives: $false_negatives
    };

    fs.writeFileSync(statePath, JSON.stringify(state, null, 2));
  " 2>/dev/null || {
    echo "error: failed to update state.json for $feat_id" >&2
    return 1
  }

  return 0
}
