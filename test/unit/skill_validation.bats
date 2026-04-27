#!/usr/bin/env bats

# Verifies that the three artifact-producing skills have their references/
# validation files with required content.
# Rules (from MONOZUKURI_SKILLS_PLAN.md PR1 acceptance criteria):
#   - mz-create-prd, mz-create-techspec, mz-create-tasks must have validation docs
#   - Each validation doc must list at least one accepted heading alias

SKILLS_DIR="$(cd "$(dirname "$BATS_TEST_FILENAME")/../.." && pwd)/skills"

@test "mz-create-prd has references/prd-validation.md" {
  [[ -f "$SKILLS_DIR/mz-create-prd/references/prd-validation.md" ]]
}

@test "mz-create-techspec has references/techspec-validation.md" {
  [[ -f "$SKILLS_DIR/mz-create-techspec/references/techspec-validation.md" ]]
}

@test "mz-create-tasks has references/tasks-validation.md" {
  [[ -f "$SKILLS_DIR/mz-create-tasks/references/tasks-validation.md" ]]
}

@test "prd-validation.md documents heading aliases for problem section" {
  local vfile="$SKILLS_DIR/mz-create-prd/references/prd-validation.md"
  # Must mention at least two of the known aliases
  grep -qiE "Background/Motivation|Problem Statement|Motivation" "$vfile"
}

@test "prd-validation.md documents the success criteria section" {
  local vfile="$SKILLS_DIR/mz-create-prd/references/prd-validation.md"
  grep -qiE "success criteria|acceptance criteria" "$vfile"
}

@test "techspec-validation.md documents files_likely_touched requirement" {
  local vfile="$SKILLS_DIR/mz-create-techspec/references/techspec-validation.md"
  grep -qi "files_likely_touched" "$vfile"
}

@test "techspec-validation.md documents the technical approach section" {
  local vfile="$SKILLS_DIR/mz-create-techspec/references/techspec-validation.md"
  grep -qiE "approach|architecture|implementation" "$vfile"
}

@test "tasks-validation.md references the JSON schema" {
  local vfile="$SKILLS_DIR/mz-create-tasks/references/tasks-validation.md"
  grep -qi "tasks.schema.json\|tasks-schema" "$vfile"
}

@test "tasks-validation.md documents per-task invariants (60 min, 5 files)" {
  local vfile="$SKILLS_DIR/mz-create-tasks/references/tasks-validation.md"
  grep -qE "60|five|5 files" "$vfile"
}

@test "mz-create-prd has a good-prd.md example" {
  [[ -f "$SKILLS_DIR/mz-create-prd/references/good-prd.md" ]]
}

@test "mz-create-techspec has a good-techspec.md example" {
  [[ -f "$SKILLS_DIR/mz-create-techspec/references/good-techspec.md" ]]
}

@test "mz-create-tasks has a good-tasks.md example" {
  [[ -f "$SKILLS_DIR/mz-create-tasks/references/good-tasks.md" ]]
}

@test "mz-workflow-memory has both memory and task templates" {
  [[ -f "$SKILLS_DIR/mz-workflow-memory/references/memory-template.md" ]]
  [[ -f "$SKILLS_DIR/mz-workflow-memory/references/task-template.md" ]]
}

@test "memory-template.md contains required section headings" {
  local tmpl="$SKILLS_DIR/mz-workflow-memory/references/memory-template.md"
  grep -q "## Current State" "$tmpl"
  grep -q "## Shared Decisions" "$tmpl"
  grep -q "## Open Risks" "$tmpl"
  grep -q "## Handoffs" "$tmpl"
}

@test "task-template.md contains required section headings" {
  local tmpl="$SKILLS_DIR/mz-workflow-memory/references/task-template.md"
  grep -q "## Objective Snapshot" "$tmpl"
  grep -q "## Errors / Corrections" "$tmpl"
  grep -q "## Ready for Next Run" "$tmpl"
}
