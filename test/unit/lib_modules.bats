#!/usr/bin/env bats
# test/unit/lib_modules.bats — unit tests for lib/core/modules.sh

setup() {
  REPO_ROOT="$(cd "$(dirname "$BATS_TEST_FILENAME")/../.." && pwd)"
  LIB_DIR="$REPO_ROOT/lib"
  source "$LIB_DIR/core/modules.sh"
  modules_init "$LIB_DIR"
}

@test "modules.sh sources without error" {
  run bash -c "source '$LIB_DIR/core/modules.sh' && modules_init '$LIB_DIR' && echo ok"
  [ "$status" -eq 0 ]
  [[ "$output" == *"ok"* ]]
}

@test "module_require loads a present module" {
  run bash -c "
    source '$LIB_DIR/core/modules.sh'
    modules_init '$LIB_DIR'
    module_require core/util
    declare -f op_timeout >/dev/null && echo loaded
  "
  [ "$status" -eq 0 ]
  [[ "$output" == *"loaded"* ]]
}

@test "module_require exits 1 for missing module" {
  run bash -c "
    source '$LIB_DIR/core/modules.sh'
    modules_init '$LIB_DIR'
    module_require core/does-not-exist
  "
  [ "$status" -eq 1 ]
}

@test "module_require is idempotent (double-source safe)" {
  run bash -c "
    source '$LIB_DIR/core/modules.sh'
    modules_init '$LIB_DIR'
    module_require core/util
    module_require core/util
    echo ok
  "
  [ "$status" -eq 0 ]
  [[ "$output" == *"ok"* ]]
}

@test "module_optional registers stubs when module absent" {
  run bash -c "
    source '$LIB_DIR/core/modules.sh'
    modules_init '$LIB_DIR'
    module_optional core/does-not-exist fake_fn_alpha
    declare -f fake_fn_alpha >/dev/null && echo stub_exists
  "
  [ "$status" -eq 0 ]
  [[ "$output" == *"stub_exists"* ]]
}

@test "module_loaded returns 0 after module_require" {
  run bash -c "
    source '$LIB_DIR/core/modules.sh'
    modules_init '$LIB_DIR'
    module_require core/util
    module_loaded core/util && echo yes
  "
  [ "$status" -eq 0 ]
  [[ "$output" == *"yes"* ]]
}

@test "module_loaded returns 1 for unloaded module" {
  run bash -c "
    source '$LIB_DIR/core/modules.sh'
    modules_init '$LIB_DIR'
    module_loaded core/util && echo yes || echo no
  "
  [ "$status" -eq 0 ]
  [[ "$output" == *"no"* ]]
}
