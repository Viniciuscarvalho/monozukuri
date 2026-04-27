#!/usr/bin/env bats
# test/unit/validator_aliases.bats — regression tests for PR2 alias expansion
#
# Verifies that heading aliases from the validation.md files are accepted by
# the validator. These test cases represent the ~40% failure rate identified
# in MONOZUKURI_SKILLS_PLAN.md: agents write valid headings that the old
# hardcoded regexes didn't cover.

setup() {
  REPO_ROOT="$(cd "$(dirname "$BATS_TEST_FILENAME")/../.." && pwd)"
  LIB_DIR="$REPO_ROOT/lib"
  SKILLS_DIR="$REPO_ROOT/skills"
  export LIB_DIR SKILLS_DIR MONOZUKURI_HOME="$REPO_ROOT"

  warn() { echo "WARN: $*" >&2; }
  info() { echo "INFO: $*" >&2; }
  platform_claude() { :; }
  export -f warn info platform_claude

  source "$LIB_DIR/schema/validate.sh"

  TMPDIR_TEST="$(mktemp -d)"
}

teardown() {
  rm -rf "$TMPDIR_TEST"
}

# ── _validation_aliases: parser unit tests ────────────────────────────────────

@test "_validation_aliases: returns empty string for missing file" {
  local result
  result=$(_validation_aliases "/nonexistent/path.md" "Problem framing")
  [ -z "$result" ]
}

@test "_validation_aliases: extracts problem framing aliases from prd-validation.md" {
  local vfile="$SKILLS_DIR/mz-create-prd/references/prd-validation.md"
  local pattern
  pattern=$(_validation_aliases "$vfile" "Problem framing")
  [[ "$pattern" == *"motivation"* ]]
  [[ "$pattern" == *"background"* ]]
  [[ "$pattern" == *"problem"* ]]
}

@test "_validation_aliases: includes background/motivation alias" {
  local vfile="$SKILLS_DIR/mz-create-prd/references/prd-validation.md"
  local pattern
  pattern=$(_validation_aliases "$vfile" "Problem framing")
  [[ "$pattern" == *"background/motivation"* ]]
}

@test "_validation_aliases: extracts success criteria aliases from prd-validation.md" {
  local vfile="$SKILLS_DIR/mz-create-prd/references/prd-validation.md"
  local pattern
  pattern=$(_validation_aliases "$vfile" "Success criteria")
  [[ "$pattern" == *"success"* ]]
  [[ "$pattern" == *"acceptance"* ]]
}

@test "_validation_aliases: extracts technical approach aliases from techspec-validation.md" {
  local vfile="$SKILLS_DIR/mz-create-techspec/references/techspec-validation.md"
  local pattern
  pattern=$(_validation_aliases "$vfile" "Technical approach")
  [[ "$pattern" == *"approach"* ]]
  [[ "$pattern" == *"implementation"* ]]
}

@test "_validation_aliases: strips yaml key annotation from files pattern" {
  local vfile="$SKILLS_DIR/mz-create-techspec/references/techspec-validation.md"
  local pattern
  pattern=$(_validation_aliases "$vfile" "Files likely touched")
  # Should NOT contain the annotation text
  [[ "$pattern" != *"yaml key"* ]]
  # But should still contain the key name itself
  [[ "$pattern" == *"files_likely_touched"* ]]
}

# ── PRD: alias regression tests ───────────────────────────────────────────────

@test "prd: '## Motivation' passes validation (was failing before PR2)" {
  cat >"$TMPDIR_TEST/prd.md" <<'EOF'
# Feature: Add login page

## Motivation
Users need a way to authenticate. This is missing from the current system.

## Success criteria
- Users can log in with email and password
- Invalid credentials return an error
EOF
  local rc=0
  schema_validate "prd" "$TMPDIR_TEST/prd.md" || rc=$?
  [ "$rc" -eq 0 ]
}

@test "prd: '## Background/Motivation' passes validation" {
  cat >"$TMPDIR_TEST/prd.md" <<'EOF'
# Feature: Add login page

## Background/Motivation
Users cannot authenticate. This feature adds a login flow.

## Success criteria
- Users can log in
- Errors are shown for invalid credentials
EOF
  local rc=0
  schema_validate "prd" "$TMPDIR_TEST/prd.md" || rc=$?
  [ "$rc" -eq 0 ]
}

@test "prd: '## Problem Statement' passes validation" {
  cat >"$TMPDIR_TEST/prd.md" <<'EOF'
# Feature: Add login page

## Problem Statement
Users have no way to authenticate with the system today.

## Acceptance criteria
- Login endpoint accepts valid credentials
- Unauthorized requests are rejected
EOF
  local rc=0
  schema_validate "prd" "$TMPDIR_TEST/prd.md" || rc=$?
  [ "$rc" -eq 0 ]
}

@test "prd: '## Definition of done' passes as success criteria" {
  cat >"$TMPDIR_TEST/prd.md" <<'EOF'
# Feature: Refactor auth

## Problem
The existing auth module uses deprecated APIs that need replacing.

## Definition of done
- All tests pass
- No deprecated API calls remain
EOF
  local rc=0
  schema_validate "prd" "$TMPDIR_TEST/prd.md" || rc=$?
  [ "$rc" -eq 0 ]
}

# ── TechSpec: alias regression tests ─────────────────────────────────────────

@test "techspec: '## Approach' passes validation (short alias)" {
  cat >"$TMPDIR_TEST/techspec.md" <<'EOF'
# TechSpec

## Approach
Use JWT-based authentication with an Express middleware layer.

## Files likely touched
- src/routes/auth.js
- src/middleware/authenticate.js
EOF
  local rc=0
  schema_validate "techspec" "$TMPDIR_TEST/techspec.md" || rc=$?
  [ "$rc" -eq 0 ]
}

@test "techspec: '## Architecture' passes validation" {
  cat >"$TMPDIR_TEST/techspec.md" <<'EOF'
# TechSpec

## Architecture
Event-driven pipeline with Redis pub/sub for async processing.

## Files likely touched
- lib/pipeline.sh
- lib/queue.sh
EOF
  local rc=0
  schema_validate "techspec" "$TMPDIR_TEST/techspec.md" || rc=$?
  [ "$rc" -eq 0 ]
}

@test "techspec: '## File change map' passes as files section" {
  cat >"$TMPDIR_TEST/techspec.md" <<'EOF'
# TechSpec

## Implementation
Standard middleware pattern for request validation.

## File change map
- src/middleware/validate.js
- test/middleware.test.js
EOF
  local rc=0
  schema_validate "techspec" "$TMPDIR_TEST/techspec.md" || rc=$?
  [ "$rc" -eq 0 ]
}

@test "techspec: '## Files to Modify' passes as files section" {
  cat >"$TMPDIR_TEST/techspec.md" <<'EOF'
# TechSpec

## Design
Standard component design approach used across the project.

## Files to Modify
- src/components/Button.tsx
- src/styles/theme.css
EOF
  local rc=0
  schema_validate "techspec" "$TMPDIR_TEST/techspec.md" || rc=$?
  [ "$rc" -eq 0 ]
}

# ── Tasks: JSON validation tests ──────────────────────────────────────────────

@test "tasks: valid tasks.json passes validation" {
  cat >"$TMPDIR_TEST/tasks.json" <<'EOF'
[
  {
    "id": "task-001",
    "title": "Implement login endpoint",
    "description": "Add POST /auth/login with credential validation",
    "files_touched": ["src/routes/auth.js", "src/middleware/authenticate.js"],
    "acceptance_criteria": ["Returns 200 for valid credentials", "Returns 401 for invalid credentials"]
  }
]
EOF
  local rc=0
  schema_validate "tasks" "$TMPDIR_TEST/tasks.json" || rc=$?
  [ "$rc" -eq 0 ]
}

@test "tasks: empty JSON array fails validation" {
  # Pad to exceed the 50-byte minimum so the size check doesn't mask this failure
  printf '[                                                        ]' >"$TMPDIR_TEST/tasks.json"
  local rc=0
  schema_validate "tasks" "$TMPDIR_TEST/tasks.json" || rc=$?
  [ "$rc" -eq 1 ]
  [[ "$SCHEMA_VALIDATE_ERROR" == *"tasks.json"* ]]
}

@test "tasks: task missing 'description' field fails validation" {
  cat >"$TMPDIR_TEST/tasks.json" <<'EOF'
[
  {
    "id": "task-001",
    "title": "Some task without description here",
    "files_touched": ["src/foo.js"],
    "acceptance_criteria": ["it works"]
  }
]
EOF
  local rc=0
  schema_validate "tasks" "$TMPDIR_TEST/tasks.json" || rc=$?
  [ "$rc" -eq 1 ]
  [[ "$SCHEMA_VALIDATE_ERROR" == *"tasks.json"* ]]
}

@test "tasks: task with empty acceptance_criteria array fails validation" {
  cat >"$TMPDIR_TEST/tasks.json" <<'EOF'
[
  {
    "id": "task-001",
    "title": "A task",
    "description": "Do something useful and specific here",
    "files_touched": ["src/foo.js"],
    "acceptance_criteria": []
  }
]
EOF
  local rc=0
  schema_validate "tasks" "$TMPDIR_TEST/tasks.json" || rc=$?
  [ "$rc" -eq 1 ]
  [[ "$SCHEMA_VALIDATE_ERROR" == *"tasks.json"* ]]
}
