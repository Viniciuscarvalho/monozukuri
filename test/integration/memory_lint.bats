#!/usr/bin/env bats
# test/integration/memory_lint.bats — public CLI tests for memory v2 lint

REPO_ROOT="$(cd "$(dirname "$BATS_TEST_FILENAME")/../.." && pwd)"
ORCHESTRATE="$REPO_ROOT/orchestrate.sh"
FIXTURES="$REPO_ROOT/test/fixtures/memory-v2"

setup() {
  TMPDIR_TEST="$(mktemp -d)"
  PROJ_DIR="$TMPDIR_TEST/project"
  mkdir -p "$PROJ_DIR"
  git -C "$PROJ_DIR" init -b main -q 2>/dev/null \
    || git -C "$PROJ_DIR" init -q 2>/dev/null || true
  git -C "$PROJ_DIR" -c user.email="test@test.local" -c user.name="Test" \
    commit -q --allow-empty -m "init" 2>/dev/null || true
}

teardown() {
  rm -rf "$TMPDIR_TEST"
}

@test "memory lint accepts a valid memory v2 learning fixture" {
  cd "$PROJ_DIR"
  run bash "$ORCHESTRATE" memory lint "$FIXTURES/valid-minimal.json"

  [ "$status" -eq 0 ]
  [[ "$output" == *"valid-minimal.json: ok"* ]]
}

@test "memory lint validates the memory v2 fixture suite" {
  cd "$PROJ_DIR"

  for fixture in \
    valid-minimal.json \
    valid-array.json \
    valid-yaml.yaml; do
    run bash "$ORCHESTRATE" memory lint "$FIXTURES/$fixture"
    [ "$status" -eq 0 ]
    [[ "$output" == *"$fixture: ok"* ]]
  done

  for fixture in \
    invalid-agent.json \
    invalid-id.json \
    invalid-insight-too-long.json \
    invalid-line-range.json \
    invalid-missing-source.json \
    invalid-phase.json \
    invalid-relative-artifact.json; do
    run bash "$ORCHESTRATE" memory lint "$FIXTURES/$fixture"
    [ "$status" -eq 1 ]
    [[ "$output" == *"$fixture:"* ]]
  done
}

@test "memory lint with no stores exits zero with a helpful message" {
  cd "$PROJ_DIR"
  run bash "$ORCHESTRATE" memory lint

  [ "$status" -eq 0 ]
  [[ "$output" == *"No Memory v2 stores found"* ]]
  [[ "$output" == *".monozukuri/memory-v2.json"* ]]
}

@test "learning v2 JSON schema is parseable and documents required provenance fields" {
  run node - "$REPO_ROOT/schemas/learning-v2.schema.json" <<'JSEOF'
const fs = require('fs');
const schema = JSON.parse(fs.readFileSync(process.argv[2], 'utf8'));
const learning = schema.definitions.learning;
for (const field of ['id', 'scope', 'insight', 'source', 'applied_count', 'last_applied', 'promoted_from', 'agent_specific', 'tags']) {
  if (!learning.required.includes(field)) throw new Error(`missing required field ${field}`);
}
for (const field of ['feature_id', 'phase', 'run_id', 'artifact']) {
  if (!learning.properties.source.required.includes(field)) throw new Error(`missing source field ${field}`);
}
if (!learning.properties.source.properties.line_range) throw new Error('missing optional line_range');
JSEOF

  [ "$status" -eq 0 ]
}
