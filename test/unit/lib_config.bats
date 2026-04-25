#!/usr/bin/env bats
# test/unit/lib_config.bats — unit tests for scripts/lib/config.sh

setup() {
  REPO_ROOT="$(cd "$(dirname "$BATS_TEST_FILENAME")/../.." && pwd)"
  SCRIPT_DIR="$REPO_ROOT/scripts"
  LIB_DIR="$SCRIPT_DIR/lib"
  TEMPLATES_DIR="$SCRIPT_DIR/templates"
  source "$LIB_DIR/ui.sh"
}

@test "config.sh sources without error" {
  run bash -c "source '$LIB_DIR/config.sh' && echo ok"
  [ "$status" -eq 0 ]
  [[ "$output" == *"ok"* ]]
}

@test "exit-codes.sh defines EXIT_OK=0" {
  source "$LIB_DIR/exit-codes.sh"
  [ "$EXIT_OK" -eq 0 ]
}

@test "exit-codes.sh defines EXIT_DEPENDENCY_MISSING=11" {
  source "$LIB_DIR/exit-codes.sh"
  [ "$EXIT_DEPENDENCY_MISSING" -eq 11 ]
}

@test "errors.sh defines monozukuri_error function" {
  source "$LIB_DIR/errors.sh"
  declare -f monozukuri_error >/dev/null
}

@test "ui.sh exports color variables" {
  source "$LIB_DIR/ui.sh"
  [ -n "${C_NC+x}" ]
}
