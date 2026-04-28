#!/bin/bash
# .qa/layers/04-backwards-compat.sh — Layer 4: Backwards compatibility (stub — implemented in PR 3)
# Validates that state from prior versions can be resumed and that the learning store
# remains readable across version bumps.
set -euo pipefail

LAYER_ID=4
LAYER_NAME="backwards-compat"

run_layer4() {
  echo "Layer 4: Backwards compatibility"
  printf '  ~ not yet implemented (lands in PR 3)\n'
  return 0
}
