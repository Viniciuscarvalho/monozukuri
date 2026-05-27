#!/usr/bin/env bats
# test/unit/verification_timeout.bats - verification timeout wrapper

REPO_ROOT="$(cd "$(dirname "$BATS_TEST_FILENAME")/../.." && pwd)"
WITH_TIMEOUT="$REPO_ROOT/scripts/verification/with-timeout.sh"

@test "with-timeout passes through successful command output" {
  run "$WITH_TIMEOUT" --seconds 2 --label quick -- bash -c 'printf ok'

  [ "$status" -eq 0 ]
  [ "$output" = "ok" ]
}

@test "with-timeout exits 124 and names timed out label" {
  run "$WITH_TIMEOUT" --seconds 1 --label slow-check -- bash -c 'sleep 2'

  [ "$status" -eq 124 ]
  [[ "$output" == *"with-timeout: slow-check exceeded 1s"* ]]
}

@test "with-timeout rejects invalid timeout budgets" {
  run "$WITH_TIMEOUT" --seconds 0 --label bad -- true

  [ "$status" -eq 2 ]
  [[ "$output" == *"--seconds must be a positive integer"* ]]
}
