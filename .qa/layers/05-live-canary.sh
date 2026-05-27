#!/bin/bash
# .qa/layers/05-live-canary.sh — Layer 5: Live canary
#
# Runs a real monozukuri loop canary against the dedicated sandbox repo.
# Skipped on patch releases (no new AI behaviour to validate).
# Skipped when MONOZUKURI_SKIP_LIVE_CANARY=1 (CI default).
#
# Cost cap: $5 total. Requires gh plus authenticated agent CLIs.
set -euo pipefail

LAYER_ID=5
LAYER_NAME="live-canary"

QA_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
REPO_ROOT="$(cd "$QA_DIR/.." && pwd)"
source "$QA_DIR/lib/assert.sh"
source "$QA_DIR/lib/semver.sh"

run_layer5() {
  local version="${1:?version required}"
  echo "Layer 5: Live canary"

  if is_patch_release "$version"; then
    printf '  ~ skipped for patch release %s\n' "$version"
    return 0
  fi

  if [ "${MONOZUKURI_SKIP_LIVE_CANARY:-0}" = "1" ]; then
    printf '  ~ skipped (MONOZUKURI_SKIP_LIVE_CANARY=1)\n'
    return 0
  fi

  local failures=0

  local canary_out canary_exit=0
  # Release Layer 5 delegates to: scripts/verification/live-canary.sh --live --max-cost 5
  canary_out=$(
    bash "$REPO_ROOT/scripts/verification/live-canary.sh" --live \
      --tasks 2 \
      --max-cost 5 \
      --sandbox-repo "${MONOZUKURI_CANARY_SANDBOX_REPO:-monozukuri/test-sandbox}" \
      --out-dir "$QA_DIR/reports/live-canary" 2>&1
  ) || canary_exit=$?

  if [ "$canary_exit" -eq 0 ]; then
    _qa_pass "live loop canary opened two green sandbox PRs per agent"
  else
    _qa_fail "live loop canary failed — release blocked pending investigation" \
      || failures=$((failures + 1))
    printf '  [canary output]\n'
    printf '%s\n' "$canary_out" | head -40 | sed 's/^/    /'
  fi

  return "$failures"
}
