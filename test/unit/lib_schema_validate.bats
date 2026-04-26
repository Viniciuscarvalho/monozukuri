#!/usr/bin/env bats
# test/unit/lib_schema_validate.bats — unit tests for lib/schema/validate.sh

setup() {
  REPO_ROOT="$(cd "$(dirname "$BATS_TEST_FILENAME")/../.." && pwd)"
  LIB_DIR="$REPO_ROOT/lib"
  export LIB_DIR

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

# ── helpers ───────────────────────────────────────────────────────────────────

_make_valid_prd() {
  cat >"$TMPDIR_TEST/prd.md" <<'EOF'
# Feature: Add login page

## Problem Statement
Users cannot log in to the application. We need an authentication flow.

## Success Criteria
- [ ] User can log in with email and password
- [ ] Invalid credentials show an error message
EOF
}

_make_valid_techspec() {
  cat >"$TMPDIR_TEST/techspec.md" <<'EOF'
# Technical Specification

## Technical Approach
Add a JWT-based authentication system using the existing Express middleware.
The login endpoint will validate credentials against the users table.

## Files Likely Touched
- src/routes/auth.js
- src/middleware/authenticate.js
- test/unit/auth.test.js

## Risks
- Session invalidation on token rotation needs care
EOF
}

_make_valid_tasks() {
  cat >"$TMPDIR_TEST/tasks.md" <<'EOF'
# Tasks

## Task 1: Create auth route
- [ ] Add POST /auth/login endpoint
- [ ] Validate request body schema

## Task 2: Add middleware
- [ ] Create authenticate middleware
EOF
}

# ── schema_validate: file presence ───────────────────────────────────────────

@test "schema_validate: returns 1 for missing file" {
  local rc=0
  schema_validate "prd" "$TMPDIR_TEST/nonexistent.md" || rc=$?
  [ "$rc" -eq 1 ]
  [[ "$SCHEMA_VALIDATE_ERROR" == *"not found"* ]]
}

@test "schema_validate: returns 1 for empty file" {
  touch "$TMPDIR_TEST/empty.md"
  local rc=0
  schema_validate "prd" "$TMPDIR_TEST/empty.md" || rc=$?
  [ "$rc" -eq 1 ]
  [[ "$SCHEMA_VALIDATE_ERROR" == *"too short"* ]]
}

@test "schema_validate: returns 1 for unknown artifact type" {
  echo "some content here that is long enough to pass the size check pad pad pad" >"$TMPDIR_TEST/x.md"
  local rc=0
  schema_validate "unknown-type" "$TMPDIR_TEST/x.md" || rc=$?
  [ "$rc" -eq 1 ]
  [[ "$SCHEMA_VALIDATE_ERROR" == *"unknown artifact type"* ]]
}

@test "schema_validate: commit-summary always passes (even for missing file)" {
  local rc=0
  schema_validate "commit-summary" "$TMPDIR_TEST/nonexistent.json" || rc=$?
  [ "$rc" -eq 0 ]
}

# ── schema_validate: prd ─────────────────────────────────────────────────────

@test "schema_validate prd: returns 0 for valid prd.md" {
  _make_valid_prd
  local rc=0
  schema_validate "prd" "$TMPDIR_TEST/prd.md" || rc=$?
  [ "$rc" -eq 0 ]
}

@test "schema_validate prd: returns 1 when problem section is missing" {
  cat >"$TMPDIR_TEST/prd.md" <<'EOF'
# Feature: Add login page

## Success Criteria
- [ ] User can log in with email and password
EOF
  local rc=0
  schema_validate "prd" "$TMPDIR_TEST/prd.md" || rc=$?
  [ "$rc" -eq 1 ]
  [[ "$SCHEMA_VALIDATE_ERROR" == *"problem"* ]] || [[ "$SCHEMA_VALIDATE_ERROR" == *"overview"* ]]
}

@test "schema_validate prd: returns 1 when success criteria section is missing" {
  cat >"$TMPDIR_TEST/prd.md" <<'EOF'
# Feature: Add login page

## Problem Statement
Users cannot log in to the application. We need an authentication flow.

## Background
This is a new feature request from the product team.
EOF
  local rc=0
  schema_validate "prd" "$TMPDIR_TEST/prd.md" || rc=$?
  [ "$rc" -eq 1 ]
  [[ "$SCHEMA_VALIDATE_ERROR" == *"success"* ]] || [[ "$SCHEMA_VALIDATE_ERROR" == *"criteria"* ]]
}

@test "schema_validate prd: accepts 'Overview' and 'Acceptance Criteria' headings" {
  cat >"$TMPDIR_TEST/prd.md" <<'EOF'
# Feature

## Overview
The problem we are solving in this feature right here with enough text.

## Acceptance Criteria
- [ ] It works correctly
- [ ] Edge cases are handled
EOF
  local rc=0
  schema_validate "prd" "$TMPDIR_TEST/prd.md" || rc=$?
  [ "$rc" -eq 0 ]
}

# ── schema_validate: techspec ─────────────────────────────────────────────────

@test "schema_validate techspec: returns 0 for valid techspec.md" {
  _make_valid_techspec
  local rc=0
  schema_validate "techspec" "$TMPDIR_TEST/techspec.md" || rc=$?
  [ "$rc" -eq 0 ]
}

@test "schema_validate techspec: returns 1 when technical approach is missing" {
  cat >"$TMPDIR_TEST/techspec.md" <<'EOF'
# Technical Specification

## Files Likely Touched
- src/routes/auth.js
- src/middleware/authenticate.js
EOF
  local rc=0
  schema_validate "techspec" "$TMPDIR_TEST/techspec.md" || rc=$?
  [ "$rc" -eq 1 ]
  [[ "$SCHEMA_VALIDATE_ERROR" == *"technical"* ]]
}

@test "schema_validate techspec: returns 1 when files_likely_touched section is missing" {
  cat >"$TMPDIR_TEST/techspec.md" <<'EOF'
# Technical Specification

## Technical Approach
Add a JWT-based authentication system using the existing Express middleware.

## Risks
- Token rotation could be tricky to handle properly
EOF
  local rc=0
  schema_validate "techspec" "$TMPDIR_TEST/techspec.md" || rc=$?
  [ "$rc" -eq 1 ]
  [[ "$SCHEMA_VALIDATE_ERROR" == *"files_likely_touched"* ]]
}

@test "schema_validate techspec: returns 1 when files_likely_touched has no list entries" {
  cat >"$TMPDIR_TEST/techspec.md" <<'EOF'
# Technical Specification

## Technical Approach
Add a JWT-based authentication system using the existing Express middleware.

## Files Likely Touched

## Risks
- Token rotation could be tricky to handle properly
EOF
  local rc=0
  schema_validate "techspec" "$TMPDIR_TEST/techspec.md" || rc=$?
  [ "$rc" -eq 1 ]
  [[ "$SCHEMA_VALIDATE_ERROR" == *"files_likely_touched"* ]]
}

@test "schema_validate techspec: accepts inline files_likely_touched field" {
  cat >"$TMPDIR_TEST/techspec.md" <<'EOF'
# Technical Specification

## Implementation
Implement the feature using the standard approach with enough text here.

files_likely_touched:
- src/lib/auth.sh
- test/unit/auth_test.sh
EOF
  local rc=0
  schema_validate "techspec" "$TMPDIR_TEST/techspec.md" || rc=$?
  [ "$rc" -eq 0 ]
}

# ── schema_validate: tasks ────────────────────────────────────────────────────

@test "schema_validate tasks: returns 0 for valid tasks.md" {
  _make_valid_tasks
  local rc=0
  schema_validate "tasks" "$TMPDIR_TEST/tasks.md" || rc=$?
  [ "$rc" -eq 0 ]
}

@test "schema_validate tasks: returns 1 when no checkboxes present" {
  cat >"$TMPDIR_TEST/tasks.md" <<'EOF'
# Tasks

1. Create auth route
2. Add middleware
3. Write tests for the implementation
EOF
  local rc=0
  schema_validate "tasks" "$TMPDIR_TEST/tasks.md" || rc=$?
  [ "$rc" -eq 1 ]
  [[ "$SCHEMA_VALIDATE_ERROR" == *"checkbox"* ]]
}

@test "schema_validate tasks: accepts checked [x] and [X] items" {
  cat >"$TMPDIR_TEST/tasks.md" <<'EOF'
# Tasks
- [x] Implement the feature
- [X] Write tests
EOF
  local rc=0
  schema_validate "tasks" "$TMPDIR_TEST/tasks.md" || rc=$?
  [ "$rc" -eq 0 ]
}

# ── schema_humanize_error ─────────────────────────────────────────────────────

@test "schema_humanize_error: returns non-empty output" {
  run schema_humanize_error "prd" "missing success criteria section"
  [ "$status" -eq 0 ]
  [ -n "$output" ]
}

@test "schema_humanize_error: output contains artifact type" {
  run schema_humanize_error "techspec" "missing files_likely_touched"
  [ "$status" -eq 0 ]
  [[ "$output" == *"techspec"* ]]
}

@test "schema_humanize_error: output contains the error message" {
  run schema_humanize_error "tasks" "must contain at least one task checkbox"
  [ "$status" -eq 0 ]
  [[ "$output" == *"must contain at least one task checkbox"* ]]
}

# ── schema_validate_with_reprompt ─────────────────────────────────────────────

@test "schema_validate_with_reprompt: returns 0 when all artifacts are valid" {
  _make_valid_prd
  _make_valid_techspec
  _make_valid_tasks

  platform_claude() { echo "UNEXPECTED call" >&2; return 1; }
  export -f platform_claude

  local rc=0
  schema_validate_with_reprompt "feat-001" "$TMPDIR_TEST" "$TMPDIR_TEST" || rc=$?
  [ "$rc" -eq 0 ]
}

@test "schema_validate_with_reprompt: returns 1 when prd invalid and reprompt does not fix it" {
  echo "too short" >"$TMPDIR_TEST/prd.md"
  _make_valid_techspec
  _make_valid_tasks

  platform_claude() { :; }
  export -f platform_claude

  local rc=0
  schema_validate_with_reprompt "feat-001" "$TMPDIR_TEST" "$TMPDIR_TEST" || rc=$?
  [ "$rc" -eq 1 ]
}

@test "schema_validate_with_reprompt: returns 0 when reprompt fixes the artifact" {
  echo "too short" >"$TMPDIR_TEST/prd.md"
  _make_valid_techspec
  _make_valid_tasks

  local _prd_fixture="$TMPDIR_TEST/prd.md"
  platform_claude() {
    cat >"$_prd_fixture" <<'EOF'
# Feature

## Problem Statement
Users cannot authenticate. We need a login flow to solve this problem properly.

## Success Criteria
- [ ] Login endpoint works
- [ ] Invalid credentials are rejected with an error
EOF
  }
  export -f platform_claude
  export _prd_fixture

  local rc=0
  schema_validate_with_reprompt "feat-001" "$TMPDIR_TEST" "$TMPDIR_TEST" || rc=$?
  [ "$rc" -eq 0 ]
}
