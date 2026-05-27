#!/usr/bin/env bats
# test/integration/memory_migrate.bats — public CLI tests for Memory v1 -> v2 migration

REPO_ROOT="$(cd "$(dirname "$BATS_TEST_FILENAME")/../.." && pwd)"
ORCHESTRATE="$REPO_ROOT/orchestrate.sh"
FIXTURES="$REPO_ROOT/test/fixtures/memory-v1"

setup() {
  TMPDIR_TEST="$(mktemp -d)"
  PROJ_DIR="$TMPDIR_TEST/project"
  HOME_DIR="$TMPDIR_TEST/home"
  mkdir -p "$PROJ_DIR" "$HOME_DIR"
  export HOME="$HOME_DIR"
  git -C "$PROJ_DIR" init -b main -q 2>/dev/null \
    || git -C "$PROJ_DIR" init -q 2>/dev/null || true
  git -C "$PROJ_DIR" -c user.email="test@test.local" -c user.name="Test" \
    commit -q --allow-empty -m "init" 2>/dev/null || true
}

teardown() {
  rm -rf "$TMPDIR_TEST"
}

install_project_fixture() {
  local fixture="$1"
  mkdir -p "$PROJ_DIR/.claude/feature-state"
  cp "$FIXTURES/$fixture/learned.json" "$PROJ_DIR/.claude/feature-state/learned.json"
}

assert_roundtrip_preserves_essential_fields() {
  local original="$1"
  local roundtrip="$2"
  run node - "$original" "$roundtrip" <<'JSEOF'
const fs = require('fs');
const original = JSON.parse(fs.readFileSync(process.argv[2], 'utf8'));
const roundtrip = JSON.parse(fs.readFileSync(process.argv[3], 'utf8'));
const fields = [
  'id',
  'pattern',
  'fix',
  'tier',
  'created_at',
  'last_seen',
  'hits',
  'success_count',
  'failure_count',
  'confidence',
  'ttl_days',
  'archived',
  'promotion_candidate'
];
function essential(entry) {
  const out = {};
  for (const field of fields) {
    if (entry[field] !== undefined) out[field] = entry[field];
  }
  return out;
}
const left = original.map(essential).sort((a, b) => a.id.localeCompare(b.id));
const right = roundtrip.map(essential).sort((a, b) => a.id.localeCompare(b.id));
if (JSON.stringify(left) !== JSON.stringify(right)) {
  console.error(JSON.stringify({left, right}, null, 2));
  process.exit(1);
}
JSEOF
  [ "$status" -eq 0 ]
}

@test "memory migrate --dry-run reports planned work without writing files" {
  install_project_fixture small
  cd "$PROJ_DIR"

  run bash "$ORCHESTRATE" memory migrate --dry-run

  [ "$status" -eq 0 ]
  [[ "$output" == *"Would migrate 2 v1 learning entries"* ]]
  [[ "$output" == *".monozukuri/memory-v2.json"* ]]
  [ ! -f "$PROJ_DIR/.monozukuri/memory-v2.json" ]
  [ ! -d "$PROJ_DIR/.monozukuri/memory.v1.bak" ]
}

@test "memory migrate writes v2 store and automatic v1 backup" {
  install_project_fixture small
  cd "$PROJ_DIR"

  run bash "$ORCHESTRATE" memory migrate

  [ "$status" -eq 0 ]
  [[ "$output" == *"Migrated 2 v1 learning entries"* ]]
  [ -f "$PROJ_DIR/.monozukuri/memory-v2.json" ]
  [ -f "$PROJ_DIR/.monozukuri/memory.v1.bak/project.learned.json" ]

  run bash "$ORCHESTRATE" memory lint "$PROJ_DIR/.monozukuri/memory-v2.json"
  [ "$status" -eq 0 ]

  run jq -e '
    length == 2 and
    all(.last_applied == null) and
    all(.applied_count == 0) and
    all(.source.run_id == "migrated-from-v1") and
    all(.promoted_from == "manual")
  ' "$PROJ_DIR/.monozukuri/memory-v2.json"
  [ "$status" -eq 0 ]
}

@test "memory migrate reads project, global, and feature v1 stores" {
  install_project_fixture small
  mkdir -p "$HOME/.claude/monozukuri/learned"
  cp "$FIXTURES/global/learned.json" "$HOME/.claude/monozukuri/learned/learned.json"
  mkdir -p "$PROJ_DIR/.monozukuri/state/feat-900"
  cp "$FIXTURES/feature/learned.json" "$PROJ_DIR/.monozukuri/state/feat-900/learned.json"
  cd "$PROJ_DIR"

  run bash "$ORCHESTRATE" memory migrate

  [ "$status" -eq 0 ]
  run jq -e '
    length == 4 and
    ([.[].scope] | sort == ["feature", "global", "project", "project"]) and
    ([.[].source.feature_id] | any(. == "feat-900"))
  ' "$PROJ_DIR/.monozukuri/memory-v2.json"
  [ "$status" -eq 0 ]
  [ -f "$PROJ_DIR/.monozukuri/memory.v1.bak/project.learned.json" ]
  [ -f "$PROJ_DIR/.monozukuri/memory.v1.bak/global.learned.json" ]
  [ -f "$PROJ_DIR/.monozukuri/memory.v1.bak/feature-feat-900.learned.json" ]
}

@test "memory migrate roundtrips small v1 fixture without losing essential data" {
  install_project_fixture small
  cd "$PROJ_DIR"

  run bash "$ORCHESTRATE" memory migrate
  [ "$status" -eq 0 ]
  run bash "$ORCHESTRATE" memory migrate --reverse
  [ "$status" -eq 0 ]

  assert_roundtrip_preserves_essential_fields \
    "$PROJ_DIR/.claude/feature-state/learned.json" \
    "$PROJ_DIR/.monozukuri/memory-v1.roundtrip.json"
}

@test "memory migrate roundtrips medium v1 fixture without losing essential data" {
  install_project_fixture medium
  cd "$PROJ_DIR"

  run bash "$ORCHESTRATE" memory migrate
  [ "$status" -eq 0 ]
  run bash "$ORCHESTRATE" memory migrate --reverse
  [ "$status" -eq 0 ]

  assert_roundtrip_preserves_essential_fields \
    "$PROJ_DIR/.claude/feature-state/learned.json" \
    "$PROJ_DIR/.monozukuri/memory-v1.roundtrip.json"
}

@test "memory migrate roundtrips large v1 fixture without losing essential data" {
  install_project_fixture large
  cd "$PROJ_DIR"

  run bash "$ORCHESTRATE" memory migrate
  [ "$status" -eq 0 ]
  run bash "$ORCHESTRATE" memory migrate --reverse
  [ "$status" -eq 0 ]

  assert_roundtrip_preserves_essential_fields \
    "$PROJ_DIR/.claude/feature-state/learned.json" \
    "$PROJ_DIR/.monozukuri/memory-v1.roundtrip.json"
}
