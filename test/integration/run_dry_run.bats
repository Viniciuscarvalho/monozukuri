#!/usr/bin/env bats
# test/integration/run_dry_run.bats — smoke test for monozukuri run --dry-run

setup() {
  REPO_ROOT="$(cd "$(dirname "$BATS_TEST_FILENAME")/../.." && pwd)"
  ORCHESTRATE="$REPO_ROOT/scripts/orchestrate.sh"
  SAMPLE_PROJECT="$REPO_ROOT/test/fixtures/sample-project"

  # Give sample project a minimal .monozukuri config
  mkdir -p "$SAMPLE_PROJECT/.monozukuri"
  cat > "$SAMPLE_PROJECT/.monozukuri/config.yaml" << 'EOCFG'
source:
  adapter: markdown
  markdown:
    file: features.md
autonomy: checkpoint
execution:
  base_branch: main
skill:
  command: feature-marker
EOCFG

  cd "$SAMPLE_PROJECT"
  # Ensure sample project is on main branch
  git checkout -b main 2>/dev/null || git checkout main 2>/dev/null || true
}

teardown() {
  rm -f "$SAMPLE_PROJECT/.monozukuri/config.yaml" \
        "$SAMPLE_PROJECT/orchestration-backlog.json"
}

@test "run --dry-run exits 0 with features.md present" {
  run bash "$ORCHESTRATE" run --dry-run
  [ "$status" -eq 0 ]
}

@test "run --dry-run prints the plan" {
  run bash "$ORCHESTRATE" run --dry-run
  [[ "$output" == *"feat-001"* ]] || [[ "$output" == *"Dry Run"* ]]
}
