#!/usr/bin/env bats
# test/unit/lib_run_dep_check.bats — unit tests for lib/run/dep-check.sh

setup() {
  REPO_ROOT="$(cd "$(dirname "$BATS_TEST_FILENAME")/../.." && pwd)"
  LIB_DIR="$REPO_ROOT/lib"
  export LIB_DIR

  TMPDIR_TEST="$(mktemp -d)"
  export TMPDIR_TEST

  # Source the module under test
  source "$LIB_DIR/run/dep-check.sh"
}

teardown() {
  rm -rf "$TMPDIR_TEST"
}

# ── valid backlogs ────────────────────────────────────────────────────────────

@test "dep_check_explicit: valid markdown backlog passes" {
  local backlog="$TMPDIR_TEST/features.md"
  cat > "$backlog" <<'EOF'
# Feature Backlog

## [HIGH] feat-001: First feature
**Why:** Initial implementation
**depends_on:**

## [MEDIUM] feat-002: Second feature
**Why:** Builds on first
**depends_on:** feat-001

## [LOW] feat-003: Third feature
**Why:** Independent
**depends_on:**
EOF

  run dep_check_explicit "$backlog"
  [ "$status" -eq 0 ]
}

@test "dep_check_explicit: valid JSON backlog passes" {
  local backlog="$TMPDIR_TEST/features.json"
  cat > "$backlog" <<'EOF'
[
  {
    "id": "feat-001",
    "title": "First feature",
    "depends_on": []
  },
  {
    "id": "feat-002",
    "title": "Second feature",
    "depends_on": ["feat-001"]
  },
  {
    "id": "feat-003",
    "title": "Third feature",
    "depends_on": ["feat-001", "feat-002"]
  }
]
EOF

  run dep_check_explicit "$backlog"
  [ "$status" -eq 0 ]
}

@test "dep_check_explicit: empty depends_on passes" {
  local backlog="$TMPDIR_TEST/features.md"
  cat > "$backlog" <<'EOF'
## [HIGH] feat-001: First feature
**depends_on:**
EOF

  run dep_check_explicit "$backlog"
  [ "$status" -eq 0 ]
}

# ── invalid references ────────────────────────────────────────────────────────

@test "dep_check_explicit: unknown feature reference fails" {
  local backlog="$TMPDIR_TEST/features.md"
  cat > "$backlog" <<'EOF'
## [HIGH] feat-001: First feature
**depends_on:**

## [MEDIUM] feat-002: Second feature
**depends_on:** feat-999
EOF

  run dep_check_explicit "$backlog"
  [ "$status" -eq 1 ]
  [[ "$output" == *"feat-999"* ]]
  [[ "$output" == *"unknown feature"* ]]
  [[ "$output" == *"features.md:5"* ]]
}

@test "dep_check_explicit: multiple unknown refs reported" {
  local backlog="$TMPDIR_TEST/features.md"
  cat > "$backlog" <<'EOF'
## [HIGH] feat-001: First feature
**depends_on:**

## [MEDIUM] feat-002: Second feature
**depends_on:** feat-999, feat-888

## [LOW] feat-003: Third feature
**depends_on:** feat-777
EOF

  run dep_check_explicit "$backlog"
  [ "$status" -eq 1 ]
  [[ "$output" == *"feat-999"* ]]
  [[ "$output" == *"feat-888"* ]]
  [[ "$output" == *"feat-777"* ]]
}

@test "dep_check_explicit: self-reference fails" {
  local backlog="$TMPDIR_TEST/features.md"
  cat > "$backlog" <<'EOF'
## [HIGH] feat-001: First feature
**depends_on:** feat-001
EOF

  run dep_check_explicit "$backlog"
  [ "$status" -eq 1 ]
  [[ "$output" == *"cannot depend on itself"* ]]
}

@test "dep_check_explicit: error includes line number" {
  local backlog="$TMPDIR_TEST/features.md"
  cat > "$backlog" <<'EOF'
# Feature Backlog

## [HIGH] feat-001: First feature
**depends_on:** feat-999
EOF

  run dep_check_explicit "$backlog"
  [ "$status" -eq 1 ]
  [[ "$output" == *":4:"* ]]  # Line 4 has the depends_on
}

@test "dep_check_explicit: error lists known features" {
  local backlog="$TMPDIR_TEST/features.md"
  cat > "$backlog" <<'EOF'
## [HIGH] feat-001: First feature
**depends_on:**

## [MEDIUM] feat-002: Second feature
**depends_on:** feat-999
EOF

  run dep_check_explicit "$backlog"
  [ "$status" -eq 1 ]
  [[ "$output" == *"known features:"* ]]
  [[ "$output" == *"feat-001"* ]]
  [[ "$output" == *"feat-002"* ]]
}

# ── edge cases ────────────────────────────────────────────────────────────────

@test "dep_check_explicit: missing file fails" {
  run dep_check_explicit "/nonexistent/file.md"
  [ "$status" -eq 1 ]
  [[ "$output" == *"not found"* ]]
}

@test "dep_check_explicit: no features in backlog warns but passes" {
  local backlog="$TMPDIR_TEST/empty.md"
  echo "# Empty backlog" > "$backlog"

  run dep_check_explicit "$backlog"
  [ "$status" -eq 0 ]
  [[ "$output" == *"no features found"* ]]
}

@test "dep_check_explicit: mixed valid and invalid refs fails" {
  local backlog="$TMPDIR_TEST/features.md"
  cat > "$backlog" <<'EOF'
## [HIGH] feat-001: First feature
**depends_on:**

## [MEDIUM] feat-002: Second feature
**depends_on:** feat-001, feat-999

## [LOW] feat-003: Third feature
**depends_on:** feat-001
EOF

  run dep_check_explicit "$backlog"
  [ "$status" -eq 1 ]
  [[ "$output" == *"feat-999"* ]]
  # Should still validate even with some valid refs
}
