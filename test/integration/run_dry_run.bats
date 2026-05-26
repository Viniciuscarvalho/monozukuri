#!/usr/bin/env bats
# test/integration/run_dry_run.bats — smoke test for monozukuri run --dry-run

setup() {
  REPO_ROOT="$(cd "$(dirname "$BATS_TEST_FILENAME")/../.." && pwd)"
  ORCHESTRATE="$REPO_ROOT/scripts/orchestrate.sh"
  SAMPLE_PROJECT="$REPO_ROOT/test/fixtures/sample-project"
  PROJECT="$(mktemp -d)"

  # Give sample project a minimal .monozukuri config
  cp "$SAMPLE_PROJECT/features.md" "$PROJECT/features.md"
  mkdir -p "$PROJECT/.monozukuri"
  cat > "$PROJECT/.monozukuri/config.yaml" << 'EOCFG'
source:
  adapter: markdown
  markdown:
    file: features.md
autonomy: checkpoint
execution:
  base_branch: main
EOCFG

  git -C "$PROJECT" init -q -b main 2>/dev/null || git -C "$PROJECT" init -q
  git -C "$PROJECT" checkout -B main >/dev/null 2>&1 || true
  git -C "$PROJECT" \
    -c user.email=qa@test.local -c user.name=qa -c commit.gpgsign=false \
    add -A
  git -C "$PROJECT" \
    -c user.email=qa@test.local -c user.name=qa -c commit.gpgsign=false \
    commit -q -m init
  cd "$PROJECT"
}

teardown() {
  rm -rf "$PROJECT"
}

@test "run --dry-run exits 0 with features.md present" {
  run bash "$ORCHESTRATE" run --dry-run
  [ "$status" -eq 0 ]
}

@test "run --dry-run prints the plan" {
  run bash "$ORCHESTRATE" run --dry-run
  [[ "$output" == *"feat-001"* ]] || [[ "$output" == *"Dry Run"* ]]
}
