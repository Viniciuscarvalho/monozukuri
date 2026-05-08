#!/bin/bash
# lib/memory/workflow.sh — Workflow memory harness (PR5)
# Bootstrap, cap-inspect, and export env vars for MEMORY.md and task_NN.md.
# Bash 3.2 compatible (macOS default shell).

_WFM_WORKFLOW_LINE_CAP=150
_WFM_WORKFLOW_BYTE_CAP=$((12 * 1024))
_WFM_TASK_LINE_CAP=200
_WFM_TASK_BYTE_CAP=$((16 * 1024))

_WFM_SELF_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
_WFM_REPO_ROOT="$(cd "$_WFM_SELF_DIR/../.." && pwd)"
_WFM_SKILL_DIR="$_WFM_REPO_ROOT/skills/mz-workflow-memory"

_wfm_count_lines() {
  local file="$1"
  wc -l < "$file" | tr -d ' '
}

_wfm_byte_count() {
  local file="$1"
  wc -c < "$file" | tr -d ' '
}

_wfm_needs_compaction() {
  local file="$1" line_cap="$2" byte_cap="$3"
  local lines bytes
  lines=$(_wfm_count_lines "$file")
  bytes=$(_wfm_byte_count "$file")
  if [ "$lines" -gt "$line_cap" ] || [ "$bytes" -gt "$byte_cap" ]; then
    return 0
  fi
  return 1
}

_wfm_next_task_file() {
  local memory_dir="$1"
  local count
  count=$(find "$memory_dir" -maxdepth 1 -name "task_*.md" 2>/dev/null | wc -l | tr -d ' ')
  local next
  next=$((count + 1))
  printf "task_%02d.md" "$next"
}

_wfm_bootstrap_workflow() {
  local memory_dir="$1" feat_id="$2"
  local dest="$memory_dir/MEMORY.md"
  [ -f "$dest" ] && return 0

  local tmpl="$_WFM_SKILL_DIR/references/memory-template.md"
  if [ -f "$tmpl" ]; then
    sed "s/{{MONOZUKURI_FEATURE_ID}}/$feat_id/g" "$tmpl" > "$dest"
  else
    cat > "$dest" <<EOWORKFLOW
# Workflow Memory

_Feature: $feat_id — created by mz-workflow-memory on first task._
_Soft cap: 150 lines / 12 KiB. Compact when exceeded._

## Current State

## Shared Decisions

## Shared Learnings

## Open Risks

## Handoffs
EOWORKFLOW
  fi
}

_wfm_bootstrap_task() {
  local memory_dir="$1" task_file="$2" feat_id="$3"
  local dest="$memory_dir/$task_file"
  [ -f "$dest" ] && return 0

  local task_id
  task_id="${task_file%.md}"
  local tmpl="$_WFM_SKILL_DIR/references/task-template.md"
  if [ -f "$tmpl" ]; then
    sed \
      -e "s/{{TASK_ID}}/$task_id/g" \
      -e "s/{{MONOZUKURI_FEATURE_ID}}/$feat_id/g" \
      "$tmpl" > "$dest"
  else
    cat > "$dest" <<EOTASK
# Task Memory: $task_id

_Feature: $feat_id — created by mz-workflow-memory at task start._
_Soft cap: 200 lines / 16 KiB. Compact when exceeded._

## Objective Snapshot

## Important Decisions

## Learnings

## Files / Surfaces

## Errors / Corrections

## Ready for Next Run
EOTASK
  fi
}

workflow_memory_dir() {
  local feat_id="$1" run_dir="$2"
  printf "%s/%s/memory" "$run_dir" "$feat_id"
}

workflow_memory_prepare() {
  local feat_id="$1" run_dir="$2"

  local memory_dir
  memory_dir=$(workflow_memory_dir "$feat_id" "$run_dir")
  mkdir -p "$memory_dir"

  _wfm_bootstrap_workflow "$memory_dir" "$feat_id"

  local task_file
  task_file=$(_wfm_next_task_file "$memory_dir")
  _wfm_bootstrap_task "$memory_dir" "$task_file" "$feat_id"

  local workflow_path="$memory_dir/MEMORY.md"
  local task_path="$memory_dir/$task_file"

  local wf_over=0 task_over=0
  _wfm_needs_compaction "$workflow_path" "$_WFM_WORKFLOW_LINE_CAP" "$_WFM_WORKFLOW_BYTE_CAP" && wf_over=1

  if _wfm_needs_compaction "$task_path" "$_WFM_TASK_LINE_CAP" "$_WFM_TASK_BYTE_CAP"; then
    task_over=1
  else
    local _tf
    while IFS= read -r _tf; do
      [ -z "$_tf" ] && continue
      [ "$_tf" = "$task_path" ] && continue
      if _wfm_needs_compaction "$_tf" "$_WFM_TASK_LINE_CAP" "$_WFM_TASK_BYTE_CAP"; then
        task_over=1
        break
      fi
    done < <(find "$memory_dir" -maxdepth 1 -name "task_*.md" 2>/dev/null | sort)
  fi

  local compaction="none"
  if [ "$wf_over" -eq 1 ] && [ "$task_over" -eq 1 ]; then
    compaction="both"
  elif [ "$wf_over" -eq 1 ]; then
    compaction="workflow"
  elif [ "$task_over" -eq 1 ]; then
    compaction="task"
  fi

  export MONOZUKURI_MEMORY_DIR="$memory_dir"
  export MONOZUKURI_WORKFLOW_MEMORY="$workflow_path"
  export MONOZUKURI_TASK_MEMORY="$task_path"
  export MONOZUKURI_TASK_FILE="$task_file"
  export MONOZUKURI_NEEDS_COMPACTION="$compaction"
}

workflow_memory_inspect() {
  local feat_id="$1" run_dir="$2"

  local memory_dir
  memory_dir=$(workflow_memory_dir "$feat_id" "$run_dir")

  local workflow_path="$memory_dir/MEMORY.md"
  if [ -f "$workflow_path" ]; then
    local wf_lines wf_bytes
    wf_lines=$(_wfm_count_lines "$workflow_path")
    wf_bytes=$(_wfm_byte_count "$workflow_path")
    local wf_flag=""
    if _wfm_needs_compaction "$workflow_path" "$_WFM_WORKFLOW_LINE_CAP" "$_WFM_WORKFLOW_BYTE_CAP"; then
      wf_flag=" [NEEDS COMPACTION]"
    fi
    printf "MEMORY.md: %d lines, %d bytes (cap: %d lines / %d bytes)%s\n" \
      "$wf_lines" "$wf_bytes" "$_WFM_WORKFLOW_LINE_CAP" "$_WFM_WORKFLOW_BYTE_CAP" "$wf_flag"
  else
    printf "MEMORY.md: not found\n"
  fi

  local task_file
  task_file=$(_wfm_next_task_file "$memory_dir")
  local count
  count=$(find "$memory_dir" -maxdepth 1 -name "task_*.md" 2>/dev/null | wc -l | tr -d ' ')
  if [ "$count" -gt 0 ]; then
    local prev_n prev_file prev_path
    prev_n=$((count))
    prev_file=$(printf "task_%02d.md" "$prev_n")
    prev_path="$memory_dir/$prev_file"
    if [ -f "$prev_path" ]; then
      local t_lines t_bytes
      t_lines=$(_wfm_count_lines "$prev_path")
      t_bytes=$(_wfm_byte_count "$prev_path")
      local t_flag=""
      if _wfm_needs_compaction "$prev_path" "$_WFM_TASK_LINE_CAP" "$_WFM_TASK_BYTE_CAP"; then
        t_flag=" [NEEDS COMPACTION]"
      fi
      printf "%s: %d lines, %d bytes (cap: %d lines / %d bytes)%s\n" \
        "$prev_file" "$t_lines" "$t_bytes" "$_WFM_TASK_LINE_CAP" "$_WFM_TASK_BYTE_CAP" "$t_flag"
    fi
  else
    printf "task files: none\n"
  fi
}
