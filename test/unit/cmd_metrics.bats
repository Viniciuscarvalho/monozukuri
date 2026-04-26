#!/usr/bin/env bats
# test/unit/cmd_metrics.bats — Tests for cmd/metrics.sh

setup() {
  # Create temp directory for test fixtures
  TEST_TMP_DIR="$(mktemp -d /tmp/monozukuri-test-cmd-metrics.XXXXXX)"
  TEST_PROJECT_ROOT="$TEST_TMP_DIR/project"
  mkdir -p "$TEST_PROJECT_ROOT/docs"

  # Set up environment
  export PROJECT_ROOT="$TEST_PROJECT_ROOT"
  export LIB_DIR="${BATS_TEST_DIRNAME}/../../lib"
  export CMD_DIR="${BATS_TEST_DIRNAME}/../../cmd"
  export SCRIPT_DIR="${BATS_TEST_DIRNAME}/../.."

  TEST_HISTORY_FILE="$PROJECT_ROOT/docs/canary-history.md"
}

teardown() {
  # Clean up temp files
  rm -rf "$TEST_TMP_DIR"
}

# ── Command Behavior Tests ────────────────────────────────────────────────

@test "metrics command exits 1 when history missing" {
  rm -f "$TEST_HISTORY_FILE"

  run bash -c "source '$CMD_DIR/metrics.sh'; sub_metrics"
  [ "$status" -eq 1 ]
  [[ "$output" == *"No canary history found"* ]]
}

@test "metrics command exits 0 with valid history" {
  cat > "$TEST_HISTORY_FILE" <<'EOF'
date | run_id | headline_% | tokens_avg | completion_% | stack_breakdown_json
-----|--------|------------|------------|--------------|---------------------
2026-04-26 | run-001 | 85 | 45000 | 92 | {"backend":90}
EOF

  run bash -c "source '$CMD_DIR/metrics.sh'; sub_metrics"
  [ "$status" -eq 0 ]
}

@test "metrics command displays formatted output" {
  cat > "$TEST_HISTORY_FILE" <<'EOF'
date | run_id | headline_% | tokens_avg | completion_% | stack_breakdown_json
-----|--------|------------|------------|--------------|---------------------
2026-04-26 | run-001 | 85 | 45000 | 92 | {"backend":90}
2026-04-19 | run-002 | 80 | 48000 | 88 | {"backend":85}
EOF

  run bash -c "source '$CMD_DIR/metrics.sh'; sub_metrics"
  [ "$status" -eq 0 ]
  [[ "$output" == *"Date"* ]]
  [[ "$output" == *"Run ID"* ]]
  [[ "$output" == *"4-week trailing average"* ]]
}

@test "metrics command shows error for missing file" {
  rm -f "$TEST_HISTORY_FILE"

  run bash -c "source '$CMD_DIR/metrics.sh'; sub_metrics"
  [ "$status" -eq 1 ]
  [[ "$output" == *"No canary history found"* ]]
}

@test "metrics command handles empty history" {
  cat > "$TEST_HISTORY_FILE" <<'EOF'
date | run_id | headline_% | tokens_avg | completion_% | stack_breakdown_json
-----|--------|------------|------------|--------------|---------------------
EOF

  run bash -c "source '$CMD_DIR/metrics.sh'; sub_metrics"
  [ "$status" -eq 0 ]
  [[ "$output" == *"No canary runs recorded yet"* ]]
}
