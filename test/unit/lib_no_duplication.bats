#!/usr/bin/env bats
# test/unit/lib_no_duplication.bats — enforces scripts/lib/ does not exist.
# If this test fails, someone re-introduced the legacy duplicate tree.

@test "scripts/lib/ directory does not exist" {
  REPO_ROOT="$(cd "$(dirname "$BATS_TEST_FILENAME")/../.." && pwd)"
  [ ! -d "$REPO_ROOT/scripts/lib" ]
}

@test "lib/ canonical tree has expected subdirectories" {
  REPO_ROOT="$(cd "$(dirname "$BATS_TEST_FILENAME")/../.." && pwd)"
  [ -d "$REPO_ROOT/lib/cli" ]
  [ -d "$REPO_ROOT/lib/config" ]
  [ -d "$REPO_ROOT/lib/core" ]
  [ -d "$REPO_ROOT/lib/memory" ]
  [ -d "$REPO_ROOT/lib/plan" ]
  [ -d "$REPO_ROOT/lib/prompt" ]
  [ -d "$REPO_ROOT/lib/run" ]
}
