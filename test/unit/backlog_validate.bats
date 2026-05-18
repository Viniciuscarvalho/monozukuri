#!/usr/bin/env bats
# test/unit/backlog_validate.bats — unit tests for lib/backlog/validate.js

bats_require_minimum_version 1.5.0

setup() {
  REPO_ROOT="$(cd "$(dirname "$BATS_TEST_FILENAME")/../.." && pwd)"
  VALIDATE_JS="$REPO_ROOT/lib/backlog/validate.js"
  TMP_DIR="$(mktemp -d)"
  BACKLOG="$TMP_DIR/backlog.json"
}

teardown() {
  rm -rf "$TMP_DIR"
}

_write_valid_backlog() {
  cat > "$BACKLOG" <<'JSON'
[
  { "id": "feat-001", "status": "done", "dependencies": [] },
  { "id": "feat-002", "status": "ready", "dependencies": ["feat-001"] },
  { "id": "feat-003", "status": "ready", "dependencies": ["feat-002"] }
]
JSON
}

_write_missing_dep_backlog() {
  cat > "$BACKLOG" <<'JSON'
[
  { "id": "feat-001", "status": "ready", "dependencies": [] },
  { "id": "feat-002", "status": "ready", "dependencies": ["feat-001"] },
  { "id": "feat-003", "status": "ready", "dependencies": ["feat-999"] }
]
JSON
}

_write_cycle_backlog() {
  cat > "$BACKLOG" <<'JSON'
[
  { "id": "feat-001", "status": "ready", "dependencies": ["feat-003"] },
  { "id": "feat-002", "status": "ready", "dependencies": ["feat-001"] },
  { "id": "feat-003", "status": "ready", "dependencies": ["feat-002"] }
]
JSON
}

@test "backlog validate passes when deps are done or selected" {
  _write_valid_backlog
  run --separate-stderr node "$VALIDATE_JS" --file "$BACKLOG" --ids feat-002,feat-003
  [ "$status" -eq 0 ]
  [ "$output" = "" ]
}

@test "backlog validate warns when dep is not done or selected" {
  _write_missing_dep_backlog
  run --separate-stderr node "$VALIDATE_JS" --file "$BACKLOG" --ids feat-002
  [ "$status" -eq 2 ]
  [ "$output" = "" ]
  [[ "$stderr" == *"warning:"* ]]
  [[ "$stderr" == *"feature feat-002"* ]]
  [[ "$stderr" == *"feat-001"* ]]
  [[ "$stderr" == *"include feat-001 or mark as done"* ]]
}

@test "backlog validate warns when declared dep does not exist" {
  _write_missing_dep_backlog
  run --separate-stderr node "$VALIDATE_JS" --file "$BACKLOG" --ids feat-003
  [ "$status" -eq 2 ]
  [ "$output" = "" ]
  [[ "$stderr" == *"feature feat-003"* ]]
  [[ "$stderr" == *"missing feat-999"* ]]
  [[ "$stderr" == *"suggestion:"* ]]
}

@test "backlog validate detects selected dependency cycles" {
  _write_cycle_backlog
  run --separate-stderr node "$VALIDATE_JS" --file "$BACKLOG" --ids feat-001,feat-002,feat-003
  [ "$status" -eq 2 ]
  [ "$output" = "" ]
  [[ "$stderr" == *"cycle"* ]]
  [[ "$stderr" == *"feat-001"* ]]
}

@test "backlog validate strict turns warnings into errors" {
  _write_missing_dep_backlog
  run --separate-stderr node "$VALIDATE_JS" --file "$BACKLOG" --ids feat-002 --strict
  [ "$status" -eq 1 ]
  [ "$output" = "" ]
  [[ "$stderr" == *"error:"* ]]
  [[ "$stderr" == *"include feat-001 or mark as done"* ]]
}
