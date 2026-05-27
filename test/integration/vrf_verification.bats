#!/usr/bin/env bats
# test/integration/vrf_verification.bats - fast PR wiring checks for v2 verification

REPO_ROOT="$(cd "$(dirname "$BATS_TEST_FILENAME")/../.." && pwd)"

@test "v2 verification workflow runs MRP nightly and loop conformance in mock mode" {
  workflow="$REPO_ROOT/.github/workflows/v2-verification.yml"

  [ -f "$workflow" ]
  grep -q "cron:" "$workflow"
  grep -q "scripts/verification/mrp-matrix.js --mock" "$workflow"
  grep -q "scripts/verification/loop-conformance.sh --tasks 3" "$workflow"
}
