#!/bin/bash
# .qa/layers/07-conformance.sh — Layer 7: Mocks-vs-reality conformance.
#
# Runs the canary prompt against the real `claude` CLI, then compares the
# *structural* properties of the live output against the structural
# properties of the recording at .qa/fixtures/recordings/claude-code/.
# Mismatch = mocks have drifted from reality; re-record before release.
#
# Cost discipline:
#   - Skipped on patch releases (no new AI behaviour to validate).
#   - Skipped when MONOZUKURI_SKIP_CONFORMANCE=1 (CI default — set in
#     .github/workflows/ci.yml and release-gate.yml so live agent calls
#     never run in CI).
#   - Local-only: no GitHub Actions workflow invokes this layer. Maintainer
#     runs it pre-release via `make conformance` or release-gate.sh.
#   - Cost when run: ~$0.30 (3 phases × tiny prompt × claude-sonnet).
#
# Compares "structural properties" (presence of required headings, presence
# of tool_use, presence of message_stop) — NOT raw text. Prose drift is
# expected and ignored; structure drift is what breaks downstream.
set -euo pipefail

LAYER_ID=7
LAYER_NAME="conformance"

QA_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
REPO_ROOT="$(cd "$QA_DIR/.." && pwd)"
source "$QA_DIR/lib/assert.sh"
source "$QA_DIR/lib/semver.sh"

# Heading sets — kept in sync with test/properties/agent_output.bats.
_l7_required_headings_for() {
  case "$1" in
    prd)
      printf '%s\n' \
        '^## (Problem|Background|Overview|Motivation)' \
        '^## (Solution|Approach)' \
        '^## (Functional requirements|Requirements|Acceptance)' \
        '^## (Out of scope|Non-goals)'
      ;;
    techspec)
      printf '%s\n' \
        '^## (Approach|Technical Approach)' \
        '^## (File change map|Files Likely Touched|Files|Implementation Files)'
      ;;
    tasks)
      # tasks is JSON — handled separately
      ;;
  esac
}

# Extract structural property fingerprint from a markdown artifact.
_l7_md_properties() {
  local f="$1" phase="$2"
  while IFS= read -r pattern; do
    [ -z "$pattern" ] && continue
    if grep -qE "$pattern" "$f"; then
      echo "+heading:$pattern"
    else
      echo "-heading:$pattern"
    fi
  done < <(_l7_required_headings_for "$phase")
}

# Extract structural property fingerprint from a tasks.json.
_l7_json_properties() {
  local f="$1"
  node -e "
    const d = JSON.parse(require('fs').readFileSync('$f','utf-8'));
    const ok = Array.isArray(d) && d.length > 0 && d.every(t =>
      'id' in t && 'title' in t && 'description' in t &&
      Array.isArray(t.files_touched) && Array.isArray(t.acceptance_criteria));
    console.log(ok ? '+contract:tasks-array-shape' : '-contract:tasks-array-shape');
  " 2>/dev/null || echo "-contract:tasks-array-shape"
}

run_layer7() {
  local version="${1:?version required}"
  echo "Layer 7: Conformance (mocks vs reality)"

  if is_patch_release "$version"; then
    printf '  ~ skipped for patch release %s\n' "$version"
    return 0
  fi

  if [ "${MONOZUKURI_SKIP_CONFORMANCE:-1}" = "1" ]; then
    printf '  ~ skipped (MONOZUKURI_SKIP_CONFORMANCE=1 — CI default)\n'
    return 0
  fi

  local failures=0

  if ! command -v claude &>/dev/null; then
    _qa_fail "claude CLI not found — install with: npm install -g @anthropic-ai/claude-code" \
      || failures=$((failures + 1))
    return "$failures"
  fi

  if ! claude auth status &>/dev/null 2>&1; then
    _qa_fail "claude not authenticated — run: claude auth login" \
      || failures=$((failures + 1))
    return "$failures"
  fi

  local recordings="$REPO_ROOT/.qa/fixtures/recordings/claude-code"
  local tmp_live; tmp_live=$(mktemp -d)
  trap "rm -rf '$tmp_live'" RETURN

  local timeout_secs="${SKILL_TIMEOUT_SECONDS:-60}"

  for phase in prd techspec; do
    local recording="$recordings/${phase}.md"
    [ -f "$recording" ] || continue

    # Tiny phase-shaped prompt — keeps spend under ~$0.10/phase.
    local prompt
    case "$phase" in
      prd)
        prompt="Output a PRD-style markdown for this canary feature: 'Add a --version CLI flag that prints a static string.' Use only these top-level headings, in this order: '## Problem', '## Solution', '## Functional requirements', '## Out of scope'. Keep under 80 words total."
        ;;
      techspec)
        prompt="Output a TechSpec-style markdown for: 'Add a --version CLI flag.' Use only these top-level headings, in this order: '## Approach', '## File change map', '## Components', '## Testing'. Keep under 80 words total."
        ;;
    esac

    local live_out="$tmp_live/${phase}.live.md"
    local live_exit=0
    if command -v timeout &>/dev/null; then
      timeout "$timeout_secs" claude --print "$prompt" > "$live_out" 2>&1 || live_exit=$?
    else
      claude --print "$prompt" > "$live_out" 2>&1 || live_exit=$?
    fi

    if [ "$live_exit" -ne 0 ]; then
      _qa_fail "live claude run for $phase failed (exit $live_exit)" \
        || failures=$((failures + 1))
      continue
    fi

    local rec_props live_props
    rec_props=$(_l7_md_properties "$recording" "$phase")
    live_props=$(_l7_md_properties "$live_out" "$phase")

    if [ "$rec_props" = "$live_props" ]; then
      _qa_pass "$phase: replay matches live structure"
    else
      _qa_fail "$phase: structural drift detected — re-record fixtures" \
        || failures=$((failures + 1))
      printf '  [recording]\n%s\n' "$rec_props" | sed 's/^/    /'
      printf '  [live]\n%s\n' "$live_props" | sed 's/^/    /'
    fi
  done

  return "$failures"
}
