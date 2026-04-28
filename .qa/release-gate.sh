#!/bin/bash
# .qa/release-gate.sh — Monozukuri release gate
#
# Usage: .qa/release-gate.sh <version>
#   version: semver string with optional leading v (e.g. "v1.20.0" or "1.20.0")
#
# Exit codes:
#   0  all layers passed — artifact cleared for release
#   1  one or more layers failed — release BLOCKED
#
# Layers run in sequence; report written to .qa/reports/<YYYY-MM-DD>-release-gate.json.
set -euo pipefail

VERSION="${1:-}"
if [ -z "$VERSION" ]; then
  echo "Usage: $0 <version>" >&2
  exit 1
fi

QA_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "$QA_DIR/.." && pwd)"
REPORT_DIR="$QA_DIR/reports"

source "$QA_DIR/lib/assert.sh"
source "$QA_DIR/lib/semver.sh"
source "$QA_DIR/lib/report.sh"
source "$QA_DIR/layers/01-build-integrity.sh"
source "$QA_DIR/layers/02-loop-integrity.sh"
source "$QA_DIR/layers/03-schema-integrity.sh"
source "$QA_DIR/layers/04-backwards-compat.sh"
source "$QA_DIR/layers/05-live-canary.sh"

cd "$REPO_ROOT"
GATE_START=$(date +%s)
report_init "$VERSION" "$REPORT_DIR"

verdict="PASS"

_run_layer() {
  local id="$1" name="$2" fn="$3"; shift 3
  local t0 t1 duration rc=0
  t0=$(date +%s)
  "$fn" "$@" || rc=$?
  t1=$(date +%s)
  duration=$((t1 - t0))
  if [ "$rc" -ne 0 ]; then
    report_layer "$id" "$name" "FAIL" "$duration"
    verdict="FAIL"
  else
    report_layer "$id" "$name" "PASS" "$duration"
  fi
}

echo ""
echo "Release gate: $VERSION"
echo "────────────────────────────────────────"

_run_layer 1 "build-integrity"   run_layer1 "$VERSION"
_run_layer 2 "loop-integrity"    run_layer2
_run_layer 3 "schema-integrity"  run_layer3 "$QA_DIR/fixtures"
_run_layer 4 "backwards-compat"  run_layer4
_run_layer 5 "live-canary"       run_layer5 "$VERSION"

GATE_END=$(date +%s)
GATE_TOTAL=$((GATE_END - GATE_START))
REPORT_PATH=$(report_write "$verdict" "$GATE_TOTAL")

echo ""
echo "════════════════════════════════════════"
if [ "$verdict" = "PASS" ]; then
  printf '  Release gate: PASS  ·  %s cleared for release\n' "$VERSION"
else
  printf '  Release gate: FAIL  ·  %s BLOCKED\n' "$VERSION"
fi
printf '  Total time: %ds  ·  Report: %s\n' "$GATE_TOTAL" "$REPORT_PATH"
echo "════════════════════════════════════════"
echo ""

[ "$verdict" = "PASS" ]
