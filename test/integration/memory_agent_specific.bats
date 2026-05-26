#!/usr/bin/env bats
# test/integration/memory_agent_specific.bats - Memory v2 agent-specific filtering

REPO_ROOT="$(cd "$(dirname "$BATS_TEST_FILENAME")/../.." && pwd)"
ORCHESTRATE="$REPO_ROOT/orchestrate.sh"

setup() {
  TMPDIR_TEST="$(mktemp -d)"
  PROJ_DIR="$TMPDIR_TEST/project"
  mkdir -p "$PROJ_DIR/.monozukuri"
  git -C "$PROJ_DIR" init -b main -q 2>/dev/null \
    || git -C "$PROJ_DIR" init -q 2>/dev/null || true
  git -C "$PROJ_DIR" -c user.email="test@test.local" -c user.name="Test" \
    commit -q --allow-empty -m "init" 2>/dev/null || true
  write_memory_fixture
}

teardown() {
  rm -rf "$TMPDIR_TEST"
}

write_memory_fixture() {
  cat > "$PROJ_DIR/.monozukuri/memory-v2.json" <<'JSON'
[
  {
    "id": "lrn-2026-05-26-001",
    "scope": "project",
    "insight": "Universal learning applies to every adapter.",
    "source": {"feature_id": "MEM-11", "phase": "code", "run_id": "manual", "artifact": "features.md"},
    "applied_count": 4,
    "last_applied": null,
    "promoted_from": "manual",
    "agent_specific": null,
    "tags": ["memory"]
  },
  {
    "id": "lrn-2026-05-26-002",
    "scope": "project",
    "insight": "Claude-only learning should not be injected for Codex.",
    "source": {"feature_id": "MEM-11", "phase": "code", "run_id": "manual", "artifact": "features.md"},
    "applied_count": 3,
    "last_applied": null,
    "promoted_from": "manual",
    "agent_specific": "claude-code",
    "tags": ["memory"]
  },
  {
    "id": "lrn-2026-05-26-003",
    "scope": "project",
    "insight": "Codex-only learning should be injected for Codex.",
    "source": {"feature_id": "MEM-11", "phase": "code", "run_id": "manual", "artifact": "features.md"},
    "applied_count": 2,
    "last_applied": null,
    "promoted_from": "manual",
    "agent_specific": "codex",
    "tags": ["memory"]
  },
  {
    "id": "lrn-2026-05-26-004",
    "scope": "project",
    "insight": "Learning that repeatedly fails in Claude but works in Codex.",
    "source": {"feature_id": "MEM-11", "phase": "tests", "run_id": "manual", "artifact": "features.md"},
    "applied_count": 1,
    "last_applied": null,
    "promoted_from": "auto_detected",
    "agent_specific": null,
    "tags": ["agent-failure:claude-code:3", "agent-success:codex:1"]
  }
]
JSON
}

@test "memory list --agent codex shows universal and Codex-specific learnings" {
  cd "$PROJ_DIR"

  run bash "$ORCHESTRATE" memory list --agent codex

  [ "$status" -eq 0 ]
  [[ "$output" == *"lrn-2026-05-26-001"* ]]
  [[ "$output" == *"Universal learning applies to every adapter."* ]]
  [[ "$output" == *"lrn-2026-05-26-003"* ]]
  [[ "$output" == *"Codex-only learning should be injected for Codex."* ]]
  [[ "$output" != *"lrn-2026-05-26-002"* ]]
  [[ "$output" != *"Claude-only learning should not be injected for Codex."* ]]
}

@test "memory list suggests agent-specific promotion when Claude fails and Codex works" {
  cd "$PROJ_DIR"

  run bash "$ORCHESTRATE" memory list --agent codex

  [ "$status" -eq 0 ]
  [[ "$output" == *"Suggestion: lrn-2026-05-26-004 repeatedly failed in claude-code and worked in codex; consider setting agent_specific: codex"* ]]
}

@test "memory context injection excludes learnings for other agents" {
  cd "$PROJ_DIR"
  export ROOT_DIR="$PROJ_DIR"
  export CONFIG_DIR="$PROJ_DIR/.monozukuri"
  export MONOZUKURI_AGENT="codex"
  export MONOZUKURI_RUN_DIR="$PROJ_DIR/.monozukuri/runs"
  export MONOZUKURI_MEMORY_SUMMARY_TOKEN_CAP=300
  source "$REPO_ROOT/lib/memory/v2.sh"

  run memory_v2_context_entries MEM-11

  [ "$status" -eq 0 ]
  run jq -e '
    any(.[]; (.summary // "") | contains("lrn-2026-05-26-001")) and
    any(.[]; (.summary // "") | contains("lrn-2026-05-26-003")) and
    (all(.[]; ((.summary // "") | contains("lrn-2026-05-26-002")) | not))
  ' <<<"$output"
  [ "$status" -eq 0 ]
}
