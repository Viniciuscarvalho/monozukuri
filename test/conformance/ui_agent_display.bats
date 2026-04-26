#!/usr/bin/env bats
# test/conformance/ui_agent_display.bats
# Pipes canned JSONL fixture streams through the UI in non-TTY mode and
# verifies each adapter's name appears in the output.

setup() {
  REPO_ROOT="$(cd "$(dirname "$BATS_TEST_FILENAME")/../.." && pwd)"
  UI_DIST="$REPO_ROOT/ui/dist/index.js"
  FIXTURES="$REPO_ROOT/ui/__tests__/fixtures/events"

  if [ ! -f "$UI_DIST" ]; then
    skip "ui/dist/index.js not built — run 'npm run build --prefix ui' first"
  fi
}

_pipe_agent() {
  local agent="$1"
  local fixture="$FIXTURES/${agent}.jsonl"
  [ -f "$fixture" ] || { echo "missing fixture: $fixture" >&2; return 1; }
  # Non-TTY mode: UI passes JSONL through unchanged
  node "$UI_DIST" < "$fixture"
}

@test "claude-code fixture streams agent field through UI" {
  run _pipe_agent claude-code
  [ "$status" -eq 0 ]
  [[ "$output" == *'"agent":"claude-code"'* ]]
}

@test "codex fixture streams agent field through UI" {
  run _pipe_agent codex
  [ "$status" -eq 0 ]
  [[ "$output" == *'"agent":"codex"'* ]]
}

@test "gemini fixture streams agent field through UI" {
  run _pipe_agent gemini
  [ "$status" -eq 0 ]
  [[ "$output" == *'"agent":"gemini"'* ]]
}

@test "kiro fixture streams agent field through UI" {
  run _pipe_agent kiro
  [ "$status" -eq 0 ]
  [[ "$output" == *'"agent":"kiro"'* ]]
}
