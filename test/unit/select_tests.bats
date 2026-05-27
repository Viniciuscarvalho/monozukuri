#!/usr/bin/env bats
# test/unit/select_tests.bats - risk-tiered test selection module

REPO_ROOT="$(cd "$(dirname "$BATS_TEST_FILENAME")/../.." && pwd)"
SELECT_TESTS="$REPO_ROOT/scripts/select-tests.sh"

setup() {
  TMPDIR_TEST="$(mktemp -d)"
  TEST_REPO="$TMPDIR_TEST/repo"
  mkdir -p "$TEST_REPO/scripts" "$TEST_REPO/test"
  cp "$SELECT_TESTS" "$TEST_REPO/scripts/select-tests.sh"
  cp "$REPO_ROOT/test/test-map.json" "$TEST_REPO/test/test-map.json"
  chmod +x "$TEST_REPO/scripts/select-tests.sh"

  (
    cd "$TEST_REPO"
    git init -b main -q 2>/dev/null || git init -q
    mkdir -p lib/config test/unit test/integration test/extended .github/workflows
    touch \
      lib/config/load.sh \
      test/unit/lib_config.bats \
      test/unit/select_tests.bats \
      test/integration/live_canary.bats \
      test/integration/vrf_verification.bats \
      test/integration/loop_command.bats \
      test/integration/resume_kill9.bats \
      test/extended/live_canary.bats \
      test/extended/vrf_verification.bats \
      .github/workflows/ci.yml
    git add .
    git -c user.email="test@test.local" -c user.name="Test" commit -q -m init
    git branch base
  )
}

teardown() {
  rm -rf "$TMPDIR_TEST"
}

change_file() {
  local path="$1"
  mkdir -p "$TEST_REPO/$(dirname "$path")"
  printf 'changed\n' >>"$TEST_REPO/$path"
}

@test "tier fallback for blast radius returns unit tests without ALL" {
  change_file "lib/config/load.sh"

  run "$TEST_REPO/scripts/select-tests.sh" --base base --tier unit

  [ "$status" -eq 0 ]
  [[ "$output" == *"test/unit/lib_config.bats"* ]]
  [[ "$output" != *"ALL"* ]]
}

@test "integration-fast tier excludes long loop and resume tests" {
  change_file "lib/config/load.sh"

  run "$TEST_REPO/scripts/select-tests.sh" --base base --tier integration-fast

  [ "$status" -eq 0 ]
  [[ "$output" == *"test/integration/live_canary.bats"* ]]
  [[ "$output" != *"test/integration/loop_command.bats"* ]]
  [[ "$output" != *"test/integration/resume_kill9.bats"* ]]
}

@test "integration-extended tier contains long harness tests" {
  change_file "lib/config/load.sh"

  run "$TEST_REPO/scripts/select-tests.sh" --base base --tier integration-extended

  [ "$status" -eq 0 ]
  [[ "$output" == *"test/integration/loop_command.bats"* ]]
  [[ "$output" == *"test/integration/resume_kill9.bats"* ]]
  [[ "$output" == *"test/extended/live_canary.bats"* ]]
}

@test "mapped workflow change selects fast wiring tests only" {
  change_file ".github/workflows/ci.yml"

  run "$TEST_REPO/scripts/select-tests.sh" --base base --tier integration-fast

  [ "$status" -eq 0 ]
  [[ "$output" == *"test/integration/live_canary.bats"* ]]
  [[ "$output" == *"test/integration/vrf_verification.bats"* ]]
  [[ "$output" != *"test/extended/live_canary.bats"* ]]
}

@test "scope reports fallback for unmapped files" {
  change_file "unknown/file.txt"

  run "$TEST_REPO/scripts/select-tests.sh" --base base --scope

  [ "$status" -eq 0 ]
  [[ "$output" == "fallback" ]]
}
