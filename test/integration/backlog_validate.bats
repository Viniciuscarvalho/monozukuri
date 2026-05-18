#!/usr/bin/env bats
# test/integration/backlog_validate.bats — end-to-end backlog validate command tests

bats_require_minimum_version 1.5.0

setup() {
  REPO_ROOT="$(cd "$(dirname "$BATS_TEST_FILENAME")/../.." && pwd)"
  ORCHESTRATE="$REPO_ROOT/orchestrate.sh"
  TMP_PROJECT="$(mktemp -d)"
  export MONOZUKURI_HOME="$REPO_ROOT"

  cd "$TMP_PROJECT"
  git init -b main -q 2>/dev/null || git init -q
  git config user.email test@example.com
  git config user.name "Test"
  mkdir -p .monozukuri
  cat > .monozukuri/config.yaml <<'YAML'
source:
  adapter: markdown
  markdown:
    file: features.md
  output: orchestration-backlog.json
autonomy: checkpoint
execution:
  base_branch: main
YAML
}

teardown() {
  rm -rf "$TMP_PROJECT"
}

_write_valid_features() {
  cat > features.md <<'EOF'
# Backlog

## [DONE] feat-001: Foundation
- priority: high

Body.

## [FEAT] feat-002: API
- priority: medium
- depends_on: feat-001

Body.

## [FEAT] feat-003: UI
- priority: medium
- depends_on: feat-002

Body.
EOF
}

_write_missing_dep_features() {
  cat > features.md <<'EOF'
# Backlog

## [FEAT] feat-001: Foundation
- priority: high

Body.

## [FEAT] feat-002: API
- priority: medium
- depends_on: feat-001

Body.

## [FEAT] feat-003: Ghost dependency
- priority: medium
- depends_on: feat-999

Body.
EOF
}

_write_cycle_features() {
  cat > features.md <<'EOF'
# Backlog

## [FEAT] feat-001: First
- priority: high
- depends_on: feat-003

Body.

## [FEAT] feat-002: Second
- priority: medium
- depends_on: feat-001

Body.

## [FEAT] feat-003: Third
- priority: medium
- depends_on: feat-002

Body.
EOF
}

@test "monozukuri backlog validate passes for selected deps that are done or selected" {
  _write_valid_features
  run --separate-stderr bash "$ORCHESTRATE" backlog validate feat-002 feat-003
  [ "$status" -eq 0 ]
  [ "$output" = "" ]
}

@test "monozukuri backlog validate warns for unresolved dep outside selection" {
  _write_missing_dep_features
  run --separate-stderr bash "$ORCHESTRATE" backlog validate feat-002
  [ "$status" -eq 2 ]
  [ "$output" = "" ]
  [[ "$stderr" == *"warning:"* ]]
  [[ "$stderr" == *"feature feat-002"* ]]
  [[ "$stderr" == *"feat-001"* ]]
  [[ "$stderr" == *"include feat-001 or mark as done"* ]]
}

@test "monozukuri backlog validate warns for missing declared dep" {
  _write_missing_dep_features
  run --separate-stderr bash "$ORCHESTRATE" backlog validate feat-003
  [ "$status" -eq 2 ]
  [ "$output" = "" ]
  [[ "$stderr" == *"feature feat-003"* ]]
  [[ "$stderr" == *"missing feat-999"* ]]
  [[ "$stderr" == *"suggestion:"* ]]
}

@test "monozukuri backlog validate detects cycles in selected set" {
  _write_cycle_features
  run --separate-stderr bash "$ORCHESTRATE" backlog validate feat-001 feat-002 feat-003
  [ "$status" -eq 2 ]
  [ "$output" = "" ]
  [[ "$stderr" == *"cycle"* ]]
  [[ "$stderr" == *"feat-001"* ]]
}

@test "monozukuri backlog validate strict returns exit 1" {
  _write_missing_dep_features
  run --separate-stderr bash "$ORCHESTRATE" backlog validate --strict feat-002
  [ "$status" -eq 1 ]
  [ "$output" = "" ]
  [[ "$stderr" == *"error:"* ]]
  [[ "$stderr" == *"include feat-001 or mark as done"* ]]
}
