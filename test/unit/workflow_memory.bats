#!/usr/bin/env bats
# test/unit/workflow_memory.bats — Tests for lib/memory/workflow.sh

REPO_ROOT="$(cd "${BATS_TEST_DIRNAME}/../../" && pwd)"

setup() {
  TMPDIR="$(mktemp -d /tmp/wfm-test-XXXXX)"
  RUN_DIR="$TMPDIR/runs"
  mkdir -p "$RUN_DIR"
  source "$REPO_ROOT/lib/memory/workflow.sh"
}

teardown() {
  rm -rf /tmp/wfm-test-*
}

# ── 1. workflow_memory_dir returns correct path ───────────────────────────────

@test "workflow_memory_dir returns correct path" {
  run workflow_memory_dir "feat-123" "$RUN_DIR"
  [ "$status" -eq 0 ]
  [ "$output" = "$RUN_DIR/feat-123/memory" ]
}

# ── 2. workflow_memory_prepare creates memory/ dir ───────────────────────────

@test "workflow_memory_prepare creates memory dir" {
  workflow_memory_prepare "feat-abc" "$RUN_DIR"
  [ -d "$RUN_DIR/feat-abc/memory" ]
}

# ── 3. workflow_memory_prepare creates MEMORY.md ─────────────────────────────

@test "workflow_memory_prepare creates MEMORY.md" {
  workflow_memory_prepare "feat-abc" "$RUN_DIR"
  [ -f "$RUN_DIR/feat-abc/memory/MEMORY.md" ]
}

# ── 4. MEMORY.md has # Workflow Memory heading ────────────────────────────────

@test "MEMORY.md content has Workflow Memory heading" {
  workflow_memory_prepare "feat-abc" "$RUN_DIR"
  grep -q "^# Workflow Memory" "$RUN_DIR/feat-abc/memory/MEMORY.md"
}

# ── 5. MEMORY.md has feature ID substituted ──────────────────────────────────

@test "MEMORY.md does not contain raw placeholder" {
  workflow_memory_prepare "feat-subst" "$RUN_DIR"
  ! grep -q "{{MONOZUKURI_FEATURE_ID}}" "$RUN_DIR/feat-subst/memory/MEMORY.md"
}

@test "MEMORY.md contains the feature ID" {
  workflow_memory_prepare "feat-subst" "$RUN_DIR"
  grep -q "feat-subst" "$RUN_DIR/feat-subst/memory/MEMORY.md"
}

# ── 6. First call creates task_01.md ─────────────────────────────────────────

@test "workflow_memory_prepare creates task_01.md on first call" {
  workflow_memory_prepare "feat-t1" "$RUN_DIR"
  [ -f "$RUN_DIR/feat-t1/memory/task_01.md" ]
}

# ── 7. Second call creates task_02.md when task_01.md already exists ─────────

@test "second call creates task_02.md" {
  local mem_dir="$RUN_DIR/feat-t2/memory"
  mkdir -p "$mem_dir"
  touch "$mem_dir/task_01.md"
  workflow_memory_prepare "feat-t2" "$RUN_DIR"
  [ -f "$mem_dir/task_02.md" ]
}

# ── 8. Bootstrap is idempotent ────────────────────────────────────────────────

@test "calling prepare twice does not overwrite existing MEMORY.md" {
  local mem_dir="$RUN_DIR/feat-idem/memory"
  mkdir -p "$mem_dir"
  printf "sentinel content\n" > "$mem_dir/MEMORY.md"
  workflow_memory_prepare "feat-idem" "$RUN_DIR"
  grep -q "sentinel content" "$mem_dir/MEMORY.md"
}

# ── 9. MONOZUKURI_MEMORY_DIR is exported correctly ───────────────────────────

@test "MONOZUKURI_MEMORY_DIR equals expected path" {
  workflow_memory_prepare "feat-env" "$RUN_DIR"
  [ "$MONOZUKURI_MEMORY_DIR" = "$RUN_DIR/feat-env/memory" ]
}

# ── 10. MONOZUKURI_WORKFLOW_MEMORY points to existing file ───────────────────

@test "MONOZUKURI_WORKFLOW_MEMORY points to existing file" {
  workflow_memory_prepare "feat-env" "$RUN_DIR"
  [ -f "$MONOZUKURI_WORKFLOW_MEMORY" ]
}

# ── 11. MONOZUKURI_TASK_MEMORY points to existing file ───────────────────────

@test "MONOZUKURI_TASK_MEMORY points to existing file" {
  workflow_memory_prepare "feat-env" "$RUN_DIR"
  [ -f "$MONOZUKURI_TASK_MEMORY" ]
}

# ── 12. MONOZUKURI_NEEDS_COMPACTION is none when under cap ───────────────────

@test "MONOZUKURI_NEEDS_COMPACTION is none when files are under cap" {
  workflow_memory_prepare "feat-cap" "$RUN_DIR"
  [ "$MONOZUKURI_NEEDS_COMPACTION" = "none" ]
}

# ── 13. MONOZUKURI_NEEDS_COMPACTION is workflow when MEMORY.md exceeds line cap

@test "MONOZUKURI_NEEDS_COMPACTION is workflow when MEMORY.md exceeds line cap" {
  local mem_dir="$RUN_DIR/feat-wfcap/memory"
  mkdir -p "$mem_dir"
  local i=0
  while [ "$i" -lt 151 ]; do
    printf "line %d\n" "$i" >> "$mem_dir/MEMORY.md"
    i=$((i + 1))
  done
  touch "$mem_dir/task_01.md"
  workflow_memory_prepare "feat-wfcap" "$RUN_DIR"
  [ "$MONOZUKURI_NEEDS_COMPACTION" = "workflow" ]
}

# ── 14. MONOZUKURI_NEEDS_COMPACTION is task when task file exceeds byte cap ──

@test "MONOZUKURI_NEEDS_COMPACTION is task when task file exceeds byte cap" {
  local mem_dir="$RUN_DIR/feat-taskcap/memory"
  mkdir -p "$mem_dir"
  printf "# Workflow Memory\n" > "$mem_dir/MEMORY.md"
  local i=0
  while [ "$i" -lt 17000 ]; do
    printf "x" >> "$mem_dir/task_01.md"
    i=$((i + 1))
  done
  workflow_memory_prepare "feat-taskcap" "$RUN_DIR"
  [ "$MONOZUKURI_NEEDS_COMPACTION" = "task" ]
}

# ── 15. MONOZUKURI_NEEDS_COMPACTION is both when both exceed caps ─────────────

@test "MONOZUKURI_NEEDS_COMPACTION is both when both files exceed caps" {
  local mem_dir="$RUN_DIR/feat-bothcap/memory"
  mkdir -p "$mem_dir"
  local i=0
  while [ "$i" -lt 151 ]; do
    printf "line %d\n" "$i" >> "$mem_dir/MEMORY.md"
    i=$((i + 1))
  done
  i=0
  while [ "$i" -lt 17000 ]; do
    printf "x" >> "$mem_dir/task_01.md"
    i=$((i + 1))
  done
  workflow_memory_prepare "feat-bothcap" "$RUN_DIR"
  [ "$MONOZUKURI_NEEDS_COMPACTION" = "both" ]
}

# ── 16. workflow_memory_inspect prints MEMORY.md line count ──────────────────

@test "workflow_memory_inspect prints MEMORY.md line count" {
  workflow_memory_prepare "feat-inspect" "$RUN_DIR"
  run workflow_memory_inspect "feat-inspect" "$RUN_DIR"
  [ "$status" -eq 0 ]
  [[ "$output" == *"MEMORY.md:"* ]]
  [[ "$output" == *"lines"* ]]
}

# ── 17. workflow_memory_inspect prints [NEEDS COMPACTION] when over cap ───────

@test "workflow_memory_inspect prints NEEDS COMPACTION when MEMORY.md is over cap" {
  local mem_dir="$RUN_DIR/feat-insp2/memory"
  mkdir -p "$mem_dir"
  local i=0
  while [ "$i" -lt 151 ]; do
    printf "line %d\n" "$i" >> "$mem_dir/MEMORY.md"
    i=$((i + 1))
  done
  touch "$mem_dir/task_01.md"
  workflow_memory_prepare "feat-insp2" "$RUN_DIR"
  run workflow_memory_inspect "feat-insp2" "$RUN_DIR"
  [ "$status" -eq 0 ]
  [[ "$output" == *"[NEEDS COMPACTION]"* ]]
}

# ── 18. _wfm_next_task_file returns task_01.md when no task files exist ───────

@test "_wfm_next_task_file returns task_01.md when no task files exist" {
  local mem_dir="$TMPDIR/empty-mem"
  mkdir -p "$mem_dir"
  run _wfm_next_task_file "$mem_dir"
  [ "$status" -eq 0 ]
  [ "$output" = "task_01.md" ]
}

# ── 19. _wfm_next_task_file returns task_03.md when task_01 and task_02 exist ─

@test "_wfm_next_task_file returns task_03.md when task_01 and task_02 exist" {
  local mem_dir="$TMPDIR/two-tasks"
  mkdir -p "$mem_dir"
  touch "$mem_dir/task_01.md"
  touch "$mem_dir/task_02.md"
  run _wfm_next_task_file "$mem_dir"
  [ "$status" -eq 0 ]
  [ "$output" = "task_03.md" ]
}
