#!/usr/bin/env bats
# test/integration/workflow_memory_e2e.bats — Integration tests for lib/memory/workflow.sh
#
# Sources workflow.sh directly and exercises workflow_memory_prepare /
# workflow_memory_inspect without spinning up the full pipeline.

REPO_ROOT="$(cd "$(dirname "$BATS_TEST_FILENAME")/../.." && pwd)"
LIB_DIR="$REPO_ROOT/lib"

setup() {
  export REPO_ROOT LIB_DIR
  TMPDIR_TEST="$(mktemp -d)"
  export TMPDIR_TEST
  source "$LIB_DIR/memory/workflow.sh"
}

teardown() {
  rm -rf "$TMPDIR_TEST"
}

# ── 1. workflow_memory_prepare sets MONOZUKURI_MEMORY_DIR and creates the dir ──

@test "workflow_memory_prepare: MONOZUKURI_MEMORY_DIR is set and directory exists" {
  local runs_dir="$TMPDIR_TEST/runs"
  workflow_memory_prepare "feat-e2e-001" "$runs_dir"
  [ -n "$MONOZUKURI_MEMORY_DIR" ]
  [ -d "$MONOZUKURI_MEMORY_DIR" ]
}

# ── 2. MEMORY.md is created ────────────────────────────────────────────────────

@test "workflow_memory_prepare: MEMORY.md is created" {
  local runs_dir="$TMPDIR_TEST/runs"
  workflow_memory_prepare "feat-e2e-001" "$runs_dir"
  [ -f "$TMPDIR_TEST/runs/feat-e2e-001/memory/MEMORY.md" ]
}

# ── 3. task_01.md is created on fresh run ─────────────────────────────────────

@test "workflow_memory_prepare: task_01.md exists after first call" {
  local runs_dir="$TMPDIR_TEST/runs"
  workflow_memory_prepare "feat-e2e-001" "$runs_dir"
  [ -f "$TMPDIR_TEST/runs/feat-e2e-001/memory/task_01.md" ]
}

# ── 4. MONOZUKURI_NEEDS_COMPACTION is none for a fresh run ────────────────────

@test "workflow_memory_prepare: MONOZUKURI_NEEDS_COMPACTION is none for fresh run" {
  local runs_dir="$TMPDIR_TEST/runs"
  workflow_memory_prepare "feat-e2e-001" "$runs_dir"
  [ "$MONOZUKURI_NEEDS_COMPACTION" = "none" ]
}

# ── 5. workflow_memory_inspect produces output containing the memory dir path ──

@test "workflow_memory_inspect: output contains memory dir path reference" {
  local runs_dir="$TMPDIR_TEST/runs"
  workflow_memory_prepare "feat-e2e-001" "$runs_dir"
  run workflow_memory_inspect "feat-e2e-001" "$runs_dir"
  [ "$status" -eq 0 ]
  [ -n "$output" ]
  # inspect always prints MEMORY.md stats
  [[ "$output" == *"MEMORY.md"* ]]
}

# ── 6. workflow_memory_inspect produces output after prepare ──────────────────

@test "workflow_memory_inspect: reports line counts and bytes" {
  local runs_dir="$TMPDIR_TEST/runs"
  workflow_memory_prepare "feat-e2e-001" "$runs_dir"
  run workflow_memory_inspect "feat-e2e-001" "$runs_dir"
  [ "$status" -eq 0 ]
  [[ "$output" == *"lines"* ]]
  [[ "$output" == *"bytes"* ]]
}

# ── 7. Idempotency: second prepare does not overwrite MEMORY.md ───────────────

@test "idempotency: second workflow_memory_prepare does not overwrite MEMORY.md" {
  local runs_dir="$TMPDIR_TEST/runs"
  local mem_dir="$runs_dir/feat-e2e-idem/memory"
  mkdir -p "$mem_dir"
  printf "sentinel idempotency content\n" > "$mem_dir/MEMORY.md"

  workflow_memory_prepare "feat-e2e-idem" "$runs_dir"
  grep -q "sentinel idempotency content" "$mem_dir/MEMORY.md"
}

# ── 8. Idempotency: MEMORY.md exists after two consecutive prepare calls ──────

@test "idempotency: MEMORY.md still present after two prepare calls" {
  local runs_dir="$TMPDIR_TEST/runs"
  workflow_memory_prepare "feat-e2e-001" "$runs_dir"
  workflow_memory_prepare "feat-e2e-001" "$runs_dir"
  [ -f "$TMPDIR_TEST/runs/feat-e2e-001/memory/MEMORY.md" ]
}

# ── 9. MONOZUKURI_TASK_MEMORY and MONOZUKURI_WORKFLOW_MEMORY point to files ───

@test "workflow_memory_prepare: MONOZUKURI_WORKFLOW_MEMORY points to existing file" {
  local runs_dir="$TMPDIR_TEST/runs"
  workflow_memory_prepare "feat-e2e-001" "$runs_dir"
  [ -f "$MONOZUKURI_WORKFLOW_MEMORY" ]
}

@test "workflow_memory_prepare: MONOZUKURI_TASK_MEMORY points to existing file" {
  local runs_dir="$TMPDIR_TEST/runs"
  workflow_memory_prepare "feat-e2e-001" "$runs_dir"
  [ -f "$MONOZUKURI_TASK_MEMORY" ]
}
