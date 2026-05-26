#!/usr/bin/env bats
# test/conformance/agent_memory_requests.bats — Memory escalation marker parsing

setup() {
  REPO_ROOT="$(cd "$(dirname "$BATS_TEST_FILENAME")/../.." && pwd)"
  LIB_DIR="$REPO_ROOT/lib"
  export LIB_DIR
}

_assert_parse_memory_requests() {
  local adapter="$1"
  source "$LIB_DIR/agent/adapter-${adapter}.sh"

  run parse_memory_requests $'<request-memory id="lrn-2026-05-25-001"/>\n<request-memory id="lrn-2026-05-25-002"/>\n\nContinuing with the answer.'

  [ "$status" -eq 0 ]
  [ "${lines[0]}" = "lrn-2026-05-25-001" ]
  [ "${lines[1]}" = "lrn-2026-05-25-002" ]
}

@test "claude-code parses leading memory request markers" {
  _assert_parse_memory_requests "claude-code"
}

@test "codex parses leading memory request markers" {
  _assert_parse_memory_requests "codex"
}

@test "gemini parses leading memory request markers" {
  _assert_parse_memory_requests "gemini"
}

@test "memory request parser ignores markers that are not at response start" {
  source "$LIB_DIR/agent/adapter-codex.sh"

  run parse_memory_requests $'Here is the answer.\n<request-memory id="lrn-2026-05-25-999"/>'

  [ "$status" -eq 0 ]
  [ "$output" = "" ]
}
