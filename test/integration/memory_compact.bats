#!/usr/bin/env bats
# test/integration/memory_compact.bats - public CLI tests for Memory v2 compaction

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
}

teardown() {
  rm -rf "$TMPDIR_TEST"
}

write_compaction_fixture() {
  node - "$PROJ_DIR/.monozukuri/memory-v2.json" <<'JSEOF'
const fs = require('fs');
const [,, outFile] = process.argv;

function entry(id, insight, appliedCount, extra = {}) {
  return {
    id,
    scope: extra.scope || 'project',
    insight,
    rationale: extra.rationale || `Rationale for ${id}`,
    source: {
      feature_id: extra.featureId || 'MEM-09',
      phase: extra.phase || 'tests',
      run_id: extra.runId || 'run-memory-compact-fixture',
      artifact: extra.artifact || 'test/integration/memory_compact.bats'
    },
    applied_count: appliedCount,
    last_applied: extra.lastApplied === undefined ? null : extra.lastApplied,
    promoted_from: extra.promotedFrom || 'manual',
    agent_specific: null,
    tags: extra.tags || ['memory', 'compact']
  };
}

const entries = [];
entries.push(entry(
  'lrn-2026-05-20-001',
  'Prefer direct Bats tests for memory compaction command behavior.',
  7,
  {tags: ['memory', 'compact', 'canonical']}
));

for (let index = 1; index <= 10; index += 1) {
  entries.push(entry(
    `lrn-2026-05-20-${String(index + 1).padStart(3, '0')}`,
    'Prefer direct Bats tests for memory compaction command behavior.',
    index,
    {tags: ['memory', 'compact', 'duplicate']}
  ));
}

for (let index = 1; index <= 20; index += 1) {
  entries.push(entry(
    `lrn-2020-01-01-${String(index).padStart(3, '0')}`,
    `Obsolete never-applied learning ${index} should be dropped by age.`,
    0,
    {tags: ['memory', 'stale']}
  ));
}

const themes = [
  'authentication refresh token rotation',
  'billing invoice pagination',
  'calendar timezone conversion',
  'deployment rollback metadata',
  'editor cursor persistence',
  'feature flag rollout ordering',
  'git worktree cleanup safety',
  'http retry backoff policy',
  'import job checkpointing',
  'json schema validation aliasing',
  'keyboard navigation focus trap',
  'linear issue sync cursor',
  'markdown backlog frontmatter',
  'notification delivery batching',
  'oauth device flow polling',
  'pricing table calibration',
  'queue worker visibility timeout',
  'release note grouping',
  'snapshot fixture normalization',
  'terminal color detection',
  'upload chunk checksum',
  'validator error humanization',
  'workspace path escaping'
];
for (let index = 0; index < 69; index += 1) {
  const theme = themes[index % themes.length];
  entries.push(entry(
    `lrn-2026-05-21-${String(index + 1).padStart(3, '0')}`,
    `Keep ${theme} learning ${index + 1} separate during deterministic compaction.`,
    1 + (index % 4),
    {tags: ['memory', `unique-${index + 1}`]}
  ));
}

if (entries.length !== 100) throw new Error(`fixture size mismatch: ${entries.length}`);
fs.writeFileSync(outFile, JSON.stringify(entries, null, 2) + '\n');
JSEOF
}

@test "memory compact dry-run reports duplicate merges and stale drops without writing" {
  write_compaction_fixture
  cd "$PROJ_DIR"
  before_checksum="$(shasum -a 256 .monozukuri/memory-v2.json | awk '{print $1}')"

  run bash "$ORCHESTRATE" memory compact --dry-run

  [ "$status" -eq 0 ]
  [[ "$output" == *"Would compact 100 Memory v2 learning entries"* ]]
  [[ "$output" == *"merge 10 duplicate learning(s)"* ]]
  [[ "$output" == *"drop 20 stale learning(s)"* ]]
  [[ "$output" == *"result: 70 entries"* ]]
  after_checksum="$(shasum -a 256 .monozukuri/memory-v2.json | awk '{print $1}')"
  [ "$before_checksum" = "$after_checksum" ]
  [ ! -d "$PROJ_DIR/.monozukuri/memory.compact.bak" ]
}

@test "memory compact applies deterministic dedup drop backup and is idempotent" {
  write_compaction_fixture
  cd "$PROJ_DIR"

  run bash "$ORCHESTRATE" memory compact

  [ "$status" -eq 0 ]
  [[ "$output" == *"Compacted 100 Memory v2 learning entries"* ]]
  [[ "$output" == *"merged 10 duplicate learning(s)"* ]]
  [[ "$output" == *"dropped 20 stale learning(s)"* ]]
  [[ "$output" == *"result: 70 entries"* ]]
  [ "$(find "$PROJ_DIR/.monozukuri/memory.compact.bak" -type f -name memory-v2.json | wc -l | tr -d ' ')" -eq 1 ]

  run jq -e '
    length == 70 and
    (map(select(.id | startswith("lrn-2020-01-01-"))) | length == 0) and
    (map(select(.tags | index("duplicate"))) | length == 0) and
    (.[] | select(.id == "lrn-2026-05-20-001") | .applied_count == 62)
  ' "$PROJ_DIR/.monozukuri/memory-v2.json"
  [ "$status" -eq 0 ]

  after_first="$(shasum -a 256 .monozukuri/memory-v2.json | awk '{print $1}')"
  backup_count="$(find "$PROJ_DIR/.monozukuri/memory.compact.bak" -type f -name memory-v2.json | wc -l | tr -d ' ')"
  run bash "$ORCHESTRATE" memory compact

  [ "$status" -eq 0 ]
  [[ "$output" == *"Memory compact: no changes"* ]]
  after_second="$(shasum -a 256 .monozukuri/memory-v2.json | awk '{print $1}')"
  [ "$after_first" = "$after_second" ]
  [ "$(find "$PROJ_DIR/.monozukuri/memory.compact.bak" -type f -name memory-v2.json | wc -l | tr -d ' ')" -eq "$backup_count" ]
}
