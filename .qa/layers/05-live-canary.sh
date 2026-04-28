#!/bin/bash
# .qa/layers/05-live-canary.sh — Layer 5: Live canary (stub — implemented in PR 4)
# Makes one real claude invocation against a fixture project; skipped on patch releases.
# Costs <$1, runs <120s. Only wires in for minor/major releases.
set -euo pipefail

LAYER_ID=5
LAYER_NAME="live-canary"

QA_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
# shellcheck source=../lib/semver.sh
source "$QA_DIR/lib/semver.sh"

run_layer5() {
  local version="${1:?version required}"
  echo "Layer 5: Live canary"

  if is_patch_release "$version"; then
    printf '  ~ skipped for patch release %s\n' "$version"
    return 0
  fi

  printf '  ~ not yet implemented (lands in PR 4)\n'
  return 0
}
