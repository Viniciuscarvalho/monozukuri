#!/usr/bin/env bats
# test/unit/event_emit.bats — Unit tests for lib/cli/emit.sh

REPO_ROOT="$(cd "${BATS_TEST_DIRNAME}/../../" && pwd)"

setup() {
  source "$REPO_ROOT/lib/cli/emit.sh"
  # Unset RUN_ID so each test can set its own
  unset MONOZUKURI_RUN_ID
}

teardown() {
  unset MONOZUKURI_RUN_ID MONOZUKURI_AGENT
}

# ── 1. skill.invoked emits valid JSON with expected fields ─────────────────────

@test "skill.invoked emits valid JSON with correct type and feature_id" {
  run env MONOZUKURI_RUN_ID="test-run-id" \
    bash -c "
      source '$REPO_ROOT/lib/cli/emit.sh'
      monozukuri_emit skill.invoked feature_id 'feat-001' phase 'prd' tier '1' skill 'mz-create-prd'
    "
  [ "$status" -eq 0 ]
  # Output must be non-empty
  [ -n "$output" ]
  # Must be valid JSON
  echo "$output" | jq . >/dev/null 2>&1
  # type field must be skill.invoked
  local type
  type=$(echo "$output" | jq -r '.type')
  [ "$type" = "skill.invoked" ]
  # feature_id field must be feat-001
  local fid
  fid=$(echo "$output" | jq -r '.feature_id')
  [ "$fid" = "feat-001" ]
}

# ── 2. memory.bootstrap emits valid JSON ──────────────────────────────────────

@test "memory.bootstrap emits valid JSON with correct type" {
  run env MONOZUKURI_RUN_ID="test-run-id" \
    bash -c "
      source '$REPO_ROOT/lib/cli/emit.sh'
      monozukuri_emit memory.bootstrap feature_id 'feat-002' memory_dir '/tmp/runs/feat-002/memory' task_file 'task_01.md' compaction 'none'
    "
  [ "$status" -eq 0 ]
  [ -n "$output" ]
  echo "$output" | jq . >/dev/null 2>&1
  local type
  type=$(echo "$output" | jq -r '.type')
  [ "$type" = "memory.bootstrap" ]
  local fid
  fid=$(echo "$output" | jq -r '.feature_id')
  [ "$fid" = "feat-002" ]
}

# ── 3. empty MONOZUKURI_RUN_ID produces no output ─────────────────────────────

@test "no emission when MONOZUKURI_RUN_ID is empty" {
  run env MONOZUKURI_RUN_ID="" \
    bash -c "
      source '$REPO_ROOT/lib/cli/emit.sh'
      monozukuri_emit skill.invoked feature_id 'feat-003' phase 'prd' tier '1' skill 'mz-create-prd'
    "
  [ "$status" -eq 0 ]
  [ -z "$output" ]
}

@test "no emission when MONOZUKURI_RUN_ID is unset" {
  run bash -c "
    unset MONOZUKURI_RUN_ID
    source '$REPO_ROOT/lib/cli/emit.sh'
    monozukuri_emit skill.invoked feature_id 'feat-003' phase 'prd' tier '1' skill 'mz-create-prd'
  "
  [ "$status" -eq 0 ]
  [ -z "$output" ]
}

# ── 4. extra fields test: exit_code present in skill.failed ───────────────────

@test "skill.failed includes exit_code field" {
  run env MONOZUKURI_RUN_ID="test-run-id" \
    bash -c "
      source '$REPO_ROOT/lib/cli/emit.sh'
      monozukuri_emit skill.failed feature_id 'feat-004' phase 'code' tier '2' exit_code '1'
    "
  [ "$status" -eq 0 ]
  [ -n "$output" ]
  echo "$output" | jq . >/dev/null 2>&1
  local ec
  ec=$(echo "$output" | jq -r '.exit_code')
  [ "$ec" = "1" ]
  local type
  type=$(echo "$output" | jq -r '.type')
  [ "$type" = "skill.failed" ]
}
