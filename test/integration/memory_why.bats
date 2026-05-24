#!/usr/bin/env bats
# test/integration/memory_why.bats - public CLI tests for memory why

REPO_ROOT="$(cd "$(dirname "$BATS_TEST_FILENAME")/../.." && pwd)"
ORCHESTRATE="$REPO_ROOT/orchestrate.sh"

setup() {
  TMPDIR_TEST="$(mktemp -d)"
  PROJ_DIR="$TMPDIR_TEST/project"
  mkdir -p "$PROJ_DIR/.monozukuri/runs"
  git -C "$PROJ_DIR" init -b main -q 2>/dev/null \
    || git -C "$PROJ_DIR" init -q 2>/dev/null || true
  git -C "$PROJ_DIR" -c user.email="test@test.local" -c user.name="Test" \
    commit -q --allow-empty -m "init" 2>/dev/null || true
}

teardown() {
  rm -rf "$TMPDIR_TEST"
}

write_memory_fixture() {
  cat > "$PROJ_DIR/.monozukuri/memory-v2.json" <<'JSON'
[
  {
    "id": "lrn-2026-05-24-777",
    "scope": "project",
    "insight": "Trace injected learnings by id.",
    "rationale": "Maintainers need to answer why a learning was used.",
    "source": {
      "feature_id": "MEM-03",
      "phase": "code",
      "run_id": "loop-2026-05-24-a1b2c3",
      "artifact": "docs/schemas/memory-v2.md",
      "line_range": [12, 18]
    },
    "applied_count": 12,
    "last_applied": "2026-05-24T21:00:00.000Z",
    "promoted_from": "manual",
    "agent_specific": "codex",
    "tags": ["memory", "debug"]
  },
  {
    "id": "lrn-2026-05-24-001",
    "scope": "project",
    "insight": "Suggestion fixture 1.",
    "source": {"feature_id": "SEL-01", "phase": "tests", "run_id": "manual", "artifact": "features.md"},
    "applied_count": 1,
    "last_applied": null,
    "promoted_from": "manual",
    "agent_specific": null,
    "tags": ["suggestion"]
  },
  {
    "id": "lrn-2026-05-24-002",
    "scope": "project",
    "insight": "Suggestion fixture 2.",
    "source": {"feature_id": "SEL-02", "phase": "tests", "run_id": "manual", "artifact": "features.md"},
    "applied_count": 2,
    "last_applied": null,
    "promoted_from": "manual",
    "agent_specific": null,
    "tags": ["suggestion"]
  },
  {
    "id": "lrn-2026-05-24-003",
    "scope": "project",
    "insight": "Suggestion fixture 3.",
    "source": {"feature_id": "SEL-03", "phase": "tests", "run_id": "manual", "artifact": "features.md"},
    "applied_count": 3,
    "last_applied": null,
    "promoted_from": "manual",
    "agent_specific": null,
    "tags": ["suggestion"]
  },
  {
    "id": "lrn-2026-05-24-004",
    "scope": "project",
    "insight": "Suggestion fixture 4.",
    "source": {"feature_id": "SEL-04", "phase": "tests", "run_id": "manual", "artifact": "features.md"},
    "applied_count": 4,
    "last_applied": null,
    "promoted_from": "manual",
    "agent_specific": null,
    "tags": ["suggestion"]
  },
  {
    "id": "lrn-2026-05-24-005",
    "scope": "project",
    "insight": "Suggestion fixture 5.",
    "source": {"feature_id": "SEL-05", "phase": "tests", "run_id": "manual", "artifact": "features.md"},
    "applied_count": 5,
    "last_applied": null,
    "promoted_from": "manual",
    "agent_specific": null,
    "tags": ["suggestion"]
  },
  {
    "id": "lrn-2026-05-24-006",
    "scope": "project",
    "insight": "Suggestion fixture 6.",
    "source": {"feature_id": "SEL-06", "phase": "tests", "run_id": "manual", "artifact": "features.md"},
    "applied_count": 6,
    "last_applied": null,
    "promoted_from": "manual",
    "agent_specific": null,
    "tags": ["suggestion"]
  },
  {
    "id": "lrn-2026-05-24-007",
    "scope": "project",
    "insight": "Suggestion fixture 7.",
    "source": {"feature_id": "SEL-07", "phase": "tests", "run_id": "manual", "artifact": "features.md"},
    "applied_count": 7,
    "last_applied": null,
    "promoted_from": "manual",
    "agent_specific": null,
    "tags": ["suggestion"]
  },
  {
    "id": "lrn-2026-05-24-008",
    "scope": "project",
    "insight": "Suggestion fixture 8.",
    "source": {"feature_id": "SEL-08", "phase": "tests", "run_id": "manual", "artifact": "features.md"},
    "applied_count": 8,
    "last_applied": null,
    "promoted_from": "manual",
    "agent_specific": null,
    "tags": ["suggestion"]
  },
  {
    "id": "lrn-2026-05-24-009",
    "scope": "project",
    "insight": "Suggestion fixture 9.",
    "source": {"feature_id": "LOOP-01", "phase": "tests", "run_id": "manual", "artifact": "features.md"},
    "applied_count": 9,
    "last_applied": null,
    "promoted_from": "manual",
    "agent_specific": null,
    "tags": ["suggestion"]
  },
  {
    "id": "lrn-2026-05-24-010",
    "scope": "project",
    "insight": "Suggestion fixture 10.",
    "source": {"feature_id": "LOOP-02", "phase": "tests", "run_id": "manual", "artifact": "features.md"},
    "applied_count": 10,
    "last_applied": null,
    "promoted_from": "manual",
    "agent_specific": null,
    "tags": ["suggestion"]
  }
]
JSON

  mkdir -p "$PROJ_DIR/.monozukuri/runs/feat-memory-001" "$PROJ_DIR/.monozukuri/runs/feat-memory-002"
  cat > "$PROJ_DIR/.monozukuri/runs/feat-memory-001/memory-injections.jsonl" <<'JSONL'
{"phase":"prd","run_id":"run-001","feature_id":"feat-memory-001","learnings":["lrn-2026-05-24-777"],"tokens":347,"timestamp":"2026-05-24T19:00:00.000Z"}
{"phase":"code","run_id":"run-001","feature_id":"feat-memory-001","learnings":["lrn-2026-05-24-777","lrn-2026-05-24-009"],"tokens":512,"timestamp":"2026-05-24T20:00:00.000Z"}
JSONL
  cat > "$PROJ_DIR/.monozukuri/runs/feat-memory-002/memory-injections.jsonl" <<'JSONL'
{"phase":"tests","run_id":"run-002","feature_id":"feat-memory-002","learnings":["lrn-2026-05-24-777"],"tokens":224,"timestamp":"2026-05-24T21:00:00.000Z"}
JSONL
}

@test "memory why prints provenance, artifact link, counters, and last applications" {
  write_memory_fixture
  cd "$PROJ_DIR"

  run bash "$ORCHESTRATE" memory why lrn-2026-05-24-777

  [ "$status" -eq 0 ]
  [[ "$output" == *"ID: lrn-2026-05-24-777"* ]]
  [[ "$output" == *"Insight: Trace injected learnings by id."* ]]
  [[ "$output" == *"Scope: project"* ]]
  [[ "$output" == *"Source: docs/schemas/memory-v2.md"* ]]
  [[ "$output" == *"Applied count: 12"* ]]
  [[ "$output" == *"Last applied: 2026-05-24T21:00:00.000Z"* ]]
  [[ "$output" == *"Applications"* ]]
  [[ "$output" == *"run-001"* ]]
  [[ "$output" == *"feat-memory-001"* ]]
  [[ "$output" == *"run-002"* ]]
  [[ "$output" == *"feat-memory-002"* ]]
}

@test "memory why --format json emits machine-readable provenance and applications" {
  write_memory_fixture
  cd "$PROJ_DIR"

  run bash "$ORCHESTRATE" memory why lrn-2026-05-24-777 --format json

  [ "$status" -eq 0 ]
  run jq -e '
    .id == "lrn-2026-05-24-777" and
    .source.artifact == "docs/schemas/memory-v2.md" and
    (.applications | length == 3) and
    any(.applications[]; .feature_id == "feat-memory-002" and .run_id == "run-002")
  ' <<<"$output"
  [ "$status" -eq 0 ]
}

@test "memory why without id suggests the 10 most-applied learnings" {
  write_memory_fixture
  cd "$PROJ_DIR"

  run bash "$ORCHESTRATE" memory why

  [ "$status" -eq 0 ]
  [[ "$output" == *"Most applied learnings"* ]]
  [[ "$output" == *"lrn-2026-05-24-010"* ]]
  [[ "$output" == *"lrn-2026-05-24-009"* ]]
  [[ "$output" != *"lrn-2026-05-24-001"* ]]
}
