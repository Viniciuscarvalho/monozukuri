#!/usr/bin/env bats
# test/integration/memory_auto_compact.bats - loop trigger tests for Memory v2 compaction

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

  cat > "$PROJ_DIR/features.md" <<'EOFEAT'
## [FEAT] feat-existing: Existing feature
- priority: high

Used only so the markdown adapter can parse a valid backlog.
EOFEAT
}

teardown() {
  rm -rf "$TMPDIR_TEST"
}

write_config() {
  local enabled="$1"
  cat > "$PROJ_DIR/.monozukuri/config.yaml" <<EOCFG
source:
  adapter: markdown
  markdown:
    file: features.md
autonomy: full_auto
agent: claude-code
pr_creation:
  strategy: none
memory:
  auto_compact:
    enabled: $enabled
    max_entries: 5
    max_size_bytes: 2048
EOCFG
}

write_memory_store() {
  node - "$PROJ_DIR/.monozukuri/memory-v2.json" <<'JSEOF'
const fs = require('fs');
const [,, outFile] = process.argv;
function entry(id, insight, appliedCount) {
  return {
    id,
    scope: 'project',
    insight,
    rationale: `Rationale for ${id}`,
    source: {
      feature_id: 'MEM-10',
      phase: 'tests',
      run_id: 'run-memory-auto-compact',
      artifact: 'test/integration/memory_auto_compact.bats'
    },
    applied_count: appliedCount,
    last_applied: null,
    promoted_from: 'manual',
    agent_specific: null,
    tags: ['memory', 'auto-compact']
  };
}
const entries = [
  entry('lrn-2026-05-20-001', 'Prefer automatic memory compaction before loop execution.', 4),
  entry('lrn-2026-05-20-002', 'Prefer automatic memory compaction before loop execution.', 2),
  entry('lrn-2020-01-01-001', 'Never applied stale auto compact learning should be dropped.', 0),
  entry('lrn-2026-05-21-001', 'Keep billing threshold learning distinct from memory compaction.', 1),
  entry('lrn-2026-05-21-002', 'Keep backlog ranking learning distinct from memory compaction.', 1),
  entry('lrn-2026-05-21-003', 'Keep agent routing learning distinct from memory compaction.', 1)
];
fs.writeFileSync(outFile, JSON.stringify(entries, null, 2) + '\n');
JSEOF
}

@test "loop auto-compacts memory when configured thresholds are exceeded" {
  write_config true
  write_memory_store
  cd "$PROJ_DIR"

  run bash "$ORCHESTRATE" loop missing-feature --max-cost 2 --on-failure continue

  [ "$status" -ne 0 ]
  [[ "$output" == *"Memory auto-compact: compacted before loop"* ]]
  run jq -e '
    length == 4 and
    (.[] | select(.id == "lrn-2026-05-20-001") | .applied_count == 6) and
    (map(select(.id == "lrn-2020-01-01-001")) | length == 0)
  ' "$PROJ_DIR/.monozukuri/memory-v2.json"
  [ "$status" -eq 0 ]
}

@test "loop does not auto-compact when memory auto_compact is disabled" {
  write_config false
  write_memory_store
  cd "$PROJ_DIR"

  run bash "$ORCHESTRATE" loop missing-feature --max-cost 2 --on-failure continue

  [ "$status" -ne 0 ]
  [[ "$output" != *"Memory auto-compact: compacted before loop"* ]]
  run jq -e 'length == 6 and any(.[]; .id == "lrn-2020-01-01-001")' "$PROJ_DIR/.monozukuri/memory-v2.json"
  [ "$status" -eq 0 ]
}

@test "loop skips auto-compaction when max-cost leaves less than one dollar" {
  write_config true
  write_memory_store
  cd "$PROJ_DIR"

  run bash "$ORCHESTRATE" loop missing-feature --max-cost 0.50 --on-failure continue

  [ "$status" -ne 0 ]
  [[ "$output" == *'Memory auto-compact: skipped because loop budget is below $1'* ]]
  run jq -e 'length == 6 and any(.[]; .id == "lrn-2020-01-01-001")' "$PROJ_DIR/.monozukuri/memory-v2.json"
  [ "$status" -eq 0 ]
}
