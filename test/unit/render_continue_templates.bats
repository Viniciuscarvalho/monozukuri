#!/usr/bin/env bats
# test/unit/render_continue_templates.bats — ADR-017: .continue.tmpl.md selection in render.sh

setup() {
  REPO_ROOT="$(cd "$(dirname "$BATS_TEST_FILENAME")/../.." && pwd)"
  LIB_DIR="$REPO_ROOT/lib"
  FIXTURE_CTX="$REPO_ROOT/test/fixtures/contexts/simple.json"
  export LIB_DIR REPO_ROOT FIXTURE_CTX

  _RT_TEST_DIR=$(mktemp -d /tmp/render-continue-test-XXXXX)
  export _RT_TEST_DIR

  source "$LIB_DIR/prompt/render.sh"
}

teardown() {
  unset MONOZUKURI_MULTI_TURN_ACTIVE CONTEXT_JSON 2>/dev/null || true
  rm -rf "${_RT_TEST_DIR:-}" 2>/dev/null || true
}

@test "render_phase_prompt techspec: with MULTI_TURN_ACTIVE=0 uses standard template (has 'Inherits from')" {
  MONOZUKURI_MULTI_TURN_ACTIVE=0
  CONTEXT_JSON="$FIXTURE_CTX"

  local out
  out=$(render_phase_prompt techspec)

  [[ "$out" == *"Inherits from"* ]]
}

@test "render_phase_prompt techspec: with MULTI_TURN_ACTIVE=1 uses continue template (has 'do not re-read')" {
  MONOZUKURI_MULTI_TURN_ACTIVE=1
  CONTEXT_JSON="$FIXTURE_CTX"

  local out
  out=$(render_phase_prompt techspec)

  [[ "$out" == *"do not re-read"* ]]
}

@test "render_phase_prompt techspec: continue template output is smaller than standard template" {
  CONTEXT_JSON="$FIXTURE_CTX"

  MONOZUKURI_MULTI_TURN_ACTIVE=0
  local std_size
  std_size=$(render_phase_prompt techspec | wc -c)

  MONOZUKURI_MULTI_TURN_ACTIVE=1
  local cont_size
  cont_size=$(render_phase_prompt techspec | wc -c)

  [ "$cont_size" -lt "$std_size" ]
}

@test "render_phase_prompt prd: no .continue template exists — standard template used regardless of MULTI_TURN_ACTIVE" {
  MONOZUKURI_MULTI_TURN_ACTIVE=1
  CONTEXT_JSON="$FIXTURE_CTX"

  local out
  out=$(render_phase_prompt prd)

  # PRD standard template has "Original request" section
  [[ "$out" == *"Original request"* ]]
}

@test "render_phase_prompt techspec: override arg still wins over continue template" {
  MONOZUKURI_MULTI_TURN_ACTIVE=1
  CONTEXT_JSON="$FIXTURE_CTX"

  # Override with the standard techspec template explicitly
  local out
  out=$(render_phase_prompt techspec techspec)

  [[ "$out" == *"Inherits from"* ]]
}
