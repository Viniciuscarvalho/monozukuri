#!/usr/bin/env bats
# test/integration/memory_trace.bats - public CLI tests for memory trace

REPO_ROOT="$(cd "$(dirname "$BATS_TEST_FILENAME")/../.." && pwd)"
ORCHESTRATE="$REPO_ROOT/orchestrate.sh"

setup() {
  TMPDIR_TEST="$(mktemp -d)"
  PROJ_DIR="$TMPDIR_TEST/project"
  mkdir -p "$PROJ_DIR/.monozukuri/runs/run-memory-trace"
  git -C "$PROJ_DIR" init -q
}

teardown() {
  rm -rf "$TMPDIR_TEST"
}

write_trace_fixture() {
  cat > "$PROJ_DIR/.monozukuri/runs/run-memory-trace/memory-trace.jsonl" <<'JSONL'
{"event":"summarize","phase":"prd","feature_id":"feat-memory-trace","included":["lrn-2026-05-25-001","lrn-2026-05-25-002"],"omitted":["lrn-2026-05-25-003"],"tokens":118,"timestamp":"2026-05-25T12:00:00.000Z"}
{"event":"escalation_requested","phase":"prd","feature_id":"feat-memory-trace","learning_id":"lrn-2026-05-25-003","attempt":1,"timestamp":"2026-05-25T12:01:00.000Z"}
{"event":"escalation_granted","phase":"prd","feature_id":"feat-memory-trace","learning_id":"lrn-2026-05-25-003","tokens":42,"attempt":1,"timestamp":"2026-05-25T12:01:01.000Z"}
{"event":"escalation_denied","phase":"techspec","feature_id":"feat-memory-trace","learning_id":"lrn-2026-05-25-999","reason":"cap_reached","attempt":4,"timestamp":"2026-05-25T12:02:00.000Z"}
JSONL
}

@test "memory trace prints a human-readable summary from memory-trace.jsonl" {
  write_trace_fixture
  cd "$PROJ_DIR"

  run bash "$ORCHESTRATE" memory trace run-memory-trace

  [ "$status" -eq 0 ]
  [ "$output" = "$(cat <<'EOF'
Memory trace: run-memory-trace
Summaries:
  - prd feat-memory-trace: included=2 omitted=1 tokens=118
    included: lrn-2026-05-25-001, lrn-2026-05-25-002
    omitted: lrn-2026-05-25-003
Escalations:
  - requested prd attempt=1 id=lrn-2026-05-25-003
  - granted prd attempt=1 id=lrn-2026-05-25-003 tokens=42
  - denied techspec attempt=4 id=lrn-2026-05-25-999 reason=cap_reached
EOF
)" ]
}

@test "memory trace exits non-zero when run trace is missing" {
  cd "$PROJ_DIR"

  run bash "$ORCHESTRATE" memory trace missing-run

  [ "$status" -ne 0 ]
  [[ "$output" == *"memory trace not found: missing-run"* ]]
}
