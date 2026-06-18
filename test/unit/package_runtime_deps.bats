#!/usr/bin/env bats
# test/unit/package_runtime_deps.bats — package manifest checks

setup() {
  REPO_ROOT="$(cd "$(dirname "$BATS_TEST_FILENAME")/../.." && pwd)"
}

@test "published package declares UI dist runtime dependencies" {
  run node "$REPO_ROOT/scripts/verify-package-runtime-deps.js" "$REPO_ROOT"
  [ "$status" -eq 0 ]
}
