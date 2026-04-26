#!/usr/bin/env bats
# test/unit/lib_config.bats — unit tests for lib/config/load.sh and related modules

setup() {
  REPO_ROOT="$(cd "$(dirname "$BATS_TEST_FILENAME")/../.." && pwd)"
  LIB_DIR="$REPO_ROOT/lib"
}

@test "config/load.sh sources without error" {
  run bash -c "source '$LIB_DIR/config/load.sh' && echo ok"
  [ "$status" -eq 0 ]
  [[ "$output" == *"ok"* ]]
}

@test "core/exit-codes.sh defines EXIT_OK=0" {
  source "$LIB_DIR/core/exit-codes.sh"
  [ "$EXIT_OK" -eq 0 ]
}

@test "core/exit-codes.sh defines EXIT_DEPENDENCY_MISSING=11" {
  source "$LIB_DIR/core/exit-codes.sh"
  [ "$EXIT_DEPENDENCY_MISSING" -eq 11 ]
}

@test "cli/errors.sh defines monozukuri_error function" {
  source "$LIB_DIR/cli/errors.sh"
  declare -f monozukuri_error >/dev/null
}

@test "cli/colors.sh exports color variables" {
  source "$LIB_DIR/cli/colors.sh"
  [ -n "${C_NC+x}" ]
}
