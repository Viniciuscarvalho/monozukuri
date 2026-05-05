#!/usr/bin/env bats
# test/unit/lib_platform.bats — unit tests for lib/core/platform.sh

setup() {
  REPO_ROOT="$(cd "$(dirname "$BATS_TEST_FILENAME")/../.." && pwd)"
  LIB_DIR="$REPO_ROOT/lib"
  # platform.sh requires op_timeout from util.sh
  source "$LIB_DIR/core/util.sh"
  source "$LIB_DIR/core/platform.sh"
}

@test "platform.sh sources without error" {
  run bash -c "source '$LIB_DIR/core/util.sh' && source '$LIB_DIR/core/platform.sh' && echo ok"
  [ "$status" -eq 0 ]
  [[ "$output" == *"ok"* ]]
}

@test "platform_detect defaults to github" {
  # Source scripts with normal PATH first, then call platform_detect with a restricted
  # PATH (empty tmpdir) so command -v finds neither az nor glab regardless of what
  # is installed on the CI host (e.g. azure-cli pre-installed on ubuntu-latest).
  local mock_dir
  mock_dir="$(mktemp -d)"
  run bash -c "
    source '$LIB_DIR/core/util.sh'
    source '$LIB_DIR/core/platform.sh'
    _PLATFORM_GIT_HOST=''
    unset ADAPTER
    PATH='$mock_dir' platform_detect
    platform_host
  "
  rm -rf "$mock_dir"
  [ "$status" -eq 0 ]
  [[ "$output" == "github" ]]
}

@test "platform_detect uses ADAPTER=github" {
  run bash -c "
    source '$LIB_DIR/core/util.sh'
    source '$LIB_DIR/core/platform.sh'
    _PLATFORM_GIT_HOST=''
    ADAPTER=github platform_detect
    platform_host
  "
  [ "$status" -eq 0 ]
  [[ "$output" == "github" ]]
}

@test "platform_detect caches result (does not re-run)" {
  run bash -c "
    source '$LIB_DIR/core/util.sh'
    source '$LIB_DIR/core/platform.sh'
    _PLATFORM_GIT_HOST='cached-value'
    platform_detect
    platform_host
  "
  [ "$status" -eq 0 ]
  [[ "$output" == "cached-value" ]]
}

@test "platform_gh returns 1 when gh is not installed" {
  run bash -c "
    source '$LIB_DIR/core/util.sh'
    source '$LIB_DIR/core/platform.sh'
    info() { :; }
    PATH=/nonexistent platform_gh version
  "
  [ "$status" -eq 1 ]
}

@test "platform_claude returns 1 when claude is not installed" {
  run bash -c "
    source '$LIB_DIR/core/util.sh'
    source '$LIB_DIR/core/platform.sh'
    info() { :; }
    PATH=/nonexistent platform_claude 10 --version
  "
  [ "$status" -eq 1 ]
}
