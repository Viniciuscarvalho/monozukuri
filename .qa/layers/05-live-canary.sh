#!/bin/bash
# .qa/layers/05-live-canary.sh — Layer 5: Live canary
#
# Makes one real claude invocation against a tiny prompt.
# Skipped on patch releases (no new AI behaviour to validate).
# Skipped when MONOZUKURI_SKIP_LIVE_CANARY=1 (CI default).
#
# Costs < $0.01. Runs < 60s. Requires `claude` CLI authenticated.
set -euo pipefail

LAYER_ID=5
LAYER_NAME="live-canary"

QA_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
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

  # Require claude CLI
  if ! command -v claude &>/dev/null; then
    _qa_fail "claude CLI not found — install with: npm install -g @anthropic-ai/claude-code" \
      || failures=$((failures + 1))
    return "$failures"
  fi

  # Require claude to be authenticated
  if ! claude auth status &>/dev/null 2>&1; then
    _qa_fail "claude not authenticated — run: claude auth login" \
      || failures=$((failures + 1))
    return "$failures"
  fi

  # Canary prompt: minimal, deterministic, cheap
  local prompt="Respond with exactly the string: CANARY_OK — nothing else."
  local canary_out
  local canary_exit=0

  canary_out=$(
    SKILL_TIMEOUT_SECONDS="${SKILL_TIMEOUT_SECONDS:-60}"
    if command -v timeout &>/dev/null; then
      timeout "$SKILL_TIMEOUT_SECONDS" claude --print "$prompt" 2>&1
    elif command -v gtimeout &>/dev/null; then
      gtimeout "$SKILL_TIMEOUT_SECONDS" claude --print "$prompt" 2>&1
    else
      perl -e "alarm $SKILL_TIMEOUT_SECONDS; exec @ARGV" -- claude --print "$prompt" 2>&1
    fi
  ) || canary_exit=$?

  if [ "$canary_exit" -ne 0 ]; then
    _qa_fail "claude --print exited $canary_exit" || failures=$((failures + 1))
    printf '  [canary output]\n'
    printf '%s\n' "$canary_out" | head -10 | sed 's/^/    /'
    return "$failures"
  fi

  if printf '%s' "$canary_out" | grep -q "CANARY_OK"; then
    _qa_pass "claude --print returned expected CANARY_OK marker"
  else
    _qa_fail "claude --print did not return CANARY_OK in output" \
      || failures=$((failures + 1))
    printf '  [canary output (first 10 lines)]\n'
    printf '%s\n' "$canary_out" | head -10 | sed 's/^/    /'
  fi

  return "$failures"
}
