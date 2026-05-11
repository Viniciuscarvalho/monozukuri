#!/usr/bin/env bats
# test/unit/stream_parse_tokens.bats — unit tests for the token-telemetry
# extensions to lib/cli/stream-parse.sh added in the Day 1 TUI PR.
#
# Fixtures live in test/fixtures/stream-events/ and reproduce the upstream
# claude stream-json wire format byte-for-byte — no live API calls.

setup() {
  REPO_ROOT="$(cd "$(dirname "$BATS_TEST_FILENAME")/../.." && pwd)"
  LIB_DIR="$REPO_ROOT/lib"
  FIXTURES="$REPO_ROOT/test/fixtures/stream-events"
  export REPO_ROOT LIB_DIR FIXTURES MONOZUKURI_RUN_ID="run-test-xyz"
  source "$LIB_DIR/cli/stream-parse.sh"
}

# Run the parser against a fixture and return events as a JSON array string.
_parse() {
  local fixture="$1" feat_id="${2:-feat-001}" phase="${3:-code}"
  stream_parse_emit_file "$feat_id" "$phase" "$FIXTURES/$fixture" \
    | jq -s '.'
}

# ── existing behaviour: tool / file events (regression checks) ────────────────

@test "tool.invoked + tool.completed emitted for every tool_use" {
  result=$(_parse full-phase.jsonl)
  jq -e '[.[] | select(.type == "tool.invoked")] | length == 2' <<<"$result"
  jq -e '[.[] | select(.type == "tool.completed")] | length == 2' <<<"$result"
}

@test "file.touched emitted for Read/Edit tools with correct op" {
  result=$(_parse full-phase.jsonl)
  jq -e '
    [.[] | select(.type == "file.touched")] as $f
    | $f | length == 2
    and ($f[0].path == "src/api.ts" and $f[0].op == "read")
    and ($f[1].path == "src/api.ts" and $f[1].op == "edit")
  ' <<<"$result"
}

# ── new: phase.token_update events ────────────────────────────────────────────

@test "phase.token_update fires once per increase in output_tokens" {
  result=$(_parse full-phase.jsonl)
  jq -e '[.[] | select(.type == "phase.token_update")] | length == 3' <<<"$result"
}

@test "phase.token_update sequence is monotonically increasing" {
  result=$(_parse full-phase.jsonl)
  jq -e '
    [.[] | select(.type == "phase.token_update") | .tokens_out] as $seq
    | $seq == ($seq | sort)
    and ($seq | unique | length) == ($seq | length)
  ' <<<"$result"
}

@test "phase.token_update carries tokens_in from message_start" {
  result=$(_parse full-phase.jsonl)
  jq -e '
    [.[] | select(.type == "phase.token_update") | .tokens_in]
    | all(. == 1234)
  ' <<<"$result"
}

@test "decreasing output_tokens is ignored (no shrink, no spurious update)" {
  result=$(_parse decreasing-tokens.jsonl)
  jq -e '
    [.[] | select(.type == "phase.token_update")] as $u
    | $u | length == 1                  # only the 0→500 transition fires
    and $u[0].tokens_out == 500
  ' <<<"$result"
}

# ── new: phase.completed summary ──────────────────────────────────────────────

@test "phase.completed fires exactly once at message_stop" {
  result=$(_parse full-phase.jsonl)
  jq -e '[.[] | select(.type == "phase.completed")] | length == 1' <<<"$result"
}

@test "phase.completed carries final tokens_in/out/total" {
  result=$(_parse full-phase.jsonl)
  jq -e '
    [.[] | select(.type == "phase.completed")][0] as $c
    | $c.tokens_in == 1234
    and $c.tokens_out == 180
    and $c.tokens_total == 1414
    and $c.had_token_telemetry == true
  ' <<<"$result"
}

@test "phase.completed preserves cache_creation/cache_read counts" {
  result=$(_parse full-phase.jsonl)
  jq -e '
    [.[] | select(.type == "phase.completed")][0] as $c
    | $c.cache_creation_input_tokens == 500
    and $c.cache_read_input_tokens == 2000
  ' <<<"$result"
}

@test "phase.completed fires on result event (CLI variant) as well as message_stop" {
  result=$(_parse result-variant.jsonl)
  jq -e '
    [.[] | select(.type == "phase.completed")][0] as $c
    | $c.tokens_in == 100
    and $c.tokens_out == 42
  ' <<<"$result"
}

@test "phase.completed had_token_telemetry=false when upstream omits usage" {
  result=$(_parse legacy-no-usage.jsonl)
  jq -e '
    [.[] | select(.type == "phase.completed")][0] as $c
    | $c.had_token_telemetry == false
    and $c.tokens_out == 0
  ' <<<"$result"
}

# ── envelope correctness ──────────────────────────────────────────────────────

@test "every emitted event carries run_id, agent, feature_id, phase, ts" {
  result=$(_parse full-phase.jsonl feat-XYZ techspec)
  jq -e '
    all(.[]?;
      .run_id == "run-test-xyz"
      and .agent == "claude-code"
      and .feature_id == "feat-XYZ"
      and .phase == "techspec"
      and (.ts | test("^[0-9]{4}-[0-9]{2}-[0-9]{2}T")))
  ' <<<"$result"
}

@test "no-op when MONOZUKURI_RUN_ID is unset" {
  unset MONOZUKURI_RUN_ID
  result=$(stream_parse_emit_file feat-001 code "$FIXTURES/full-phase.jsonl")
  [[ -z "$result" ]]
}

@test "no-op when stream file is missing" {
  result=$(stream_parse_emit_file feat-001 code /nonexistent/path.jsonl)
  [[ -z "$result" ]]
}
