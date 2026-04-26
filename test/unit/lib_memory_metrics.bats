#!/usr/bin/env bats
# test/unit/lib_memory_metrics.bats — Tests for lib/memory/metrics.sh

setup() {
  # Create temp directory for test fixtures
  TEST_TMP_DIR="$(mktemp -d /tmp/monozukuri-test-metrics.XXXXXX)"
  TEST_HISTORY_FILE="$TEST_TMP_DIR/canary-history.md"

  # Source the metrics module
  LIB_DIR="${BATS_TEST_DIRNAME}/../../lib"
  source "$LIB_DIR/memory/metrics.sh"
}

teardown() {
  # Clean up temp files
  rm -rf "$TEST_TMP_DIR"
}

# ── Schema Validation Tests ────────────────────────────────────────────────

@test "schema validation passes for valid history" {
  cat > "$TEST_HISTORY_FILE" <<'EOF'
# Canary Run History

## History

date | run_id | headline_% | tokens_avg | completion_% | stack_breakdown_json
-----|--------|------------|------------|--------------|---------------------
2026-04-26 | run-001 | 85 | 45000 | 92 | {"backend":90,"frontend":80}
EOF

  run _metrics_validate_schema "$TEST_HISTORY_FILE"
  [ "$status" -eq 0 ]
}

@test "schema validation fails for invalid column count" {
  cat > "$TEST_HISTORY_FILE" <<'EOF'
date | run_id | headline_%
-----|--------|------------
2026-04-26 | run-001 | 85
EOF

  run _metrics_validate_schema "$TEST_HISTORY_FILE"
  [ "$status" -eq 2 ]
  [[ "$output" == *"expected 6 columns"* ]]
}

@test "schema validation fails for invalid date format" {
  cat > "$TEST_HISTORY_FILE" <<'EOF'
date | run_id | headline_% | tokens_avg | completion_% | stack_breakdown_json
-----|--------|------------|------------|--------------|---------------------
04/26/2026 | run-001 | 85 | 45000 | 92 | {}
EOF

  run _metrics_validate_schema "$TEST_HISTORY_FILE"
  [ "$status" -eq 2 ]
  [[ "$output" == *"invalid date format"* ]]
}

@test "schema validation passes for empty history (header only)" {
  cat > "$TEST_HISTORY_FILE" <<'EOF'
date | run_id | headline_% | tokens_avg | completion_% | stack_breakdown_json
-----|--------|------------|------------|--------------|---------------------
EOF

  run _metrics_validate_schema "$TEST_HISTORY_FILE"
  [ "$status" -eq 0 ]
}

# ── Trailing Average Calculation Tests ────────────────────────────────────

@test "trailing average calculation for 4 weeks" {
  local rows="2026-04-26 | run-001 | 85 | 45000 | 92 | {}
2026-04-19 | run-002 | 82 | 48000 | 88 | {}
2026-04-12 | run-003 | 88 | 46000 | 90 | {}
2026-04-05 | run-004 | 90 | 47000 | 95 | {}"

  run _metrics_calculate_trailing_average "$rows"
  [ "$status" -eq 0 ]
  # Average of 85, 82, 88, 90 = 86.25
  [[ "$output" == "86.2" ]] || [[ "$output" == "86.3" ]]
}

@test "trailing average calculation for fewer than 4 weeks" {
  local rows="2026-04-26 | run-001 | 85 | 45000 | 92 | {}
2026-04-19 | run-002 | 80 | 48000 | 88 | {}"

  run _metrics_calculate_trailing_average "$rows"
  [ "$status" -eq 0 ]
  # Average of 85, 80 = 82.5
  [[ "$output" == "82.5" ]]
}

@test "trailing average handles empty input" {
  run _metrics_calculate_trailing_average ""
  [ "$status" -eq 0 ]
  [[ "$output" == "0.0" ]]
}

# ── metrics_append Tests ──────────────────────────────────────────────────

@test "metrics_append creates file if missing" {
  rm -f "$TEST_HISTORY_FILE"

  run metrics_append "$TEST_HISTORY_FILE" "run-001" 85 45000 92 '{"backend":90}'
  [ "$status" -eq 0 ]
  [ -f "$TEST_HISTORY_FILE" ]
}

@test "metrics_append adds row to existing file" {
  cat > "$TEST_HISTORY_FILE" <<'EOF'
date | run_id | headline_% | tokens_avg | completion_% | stack_breakdown_json
-----|--------|------------|------------|--------------|---------------------
2026-04-19 | run-001 | 82 | 48000 | 88 | {"backend":85}
EOF

  run metrics_append "$TEST_HISTORY_FILE" "run-002" 85 45000 92 '{"backend":90}'
  [ "$status" -eq 0 ]

  # Verify row was appended
  row_count=$(grep -c '^[0-9]' "$TEST_HISTORY_FILE")
  [ "$row_count" -eq 2 ]
}

@test "appended row has 6 columns" {
  run metrics_append "$TEST_HISTORY_FILE" "run-001" 85 45000 92 '{"backend":90}'
  [ "$status" -eq 0 ]

  # Count pipes in last row (should be 5 pipes for 6 columns)
  last_row=$(grep '^[0-9]' "$TEST_HISTORY_FILE" | tail -1)
  pipe_count=$(echo "$last_row" | grep -o '|' | wc -l | tr -d ' ')
  [ "$pipe_count" -eq 5 ]
}

@test "appended date is current date" {
  run metrics_append "$TEST_HISTORY_FILE" "run-001" 85 45000 92 '{}'
  [ "$status" -eq 0 ]

  # Extract date from last row
  last_row=$(grep '^[0-9]' "$TEST_HISTORY_FILE" | tail -1)
  date_field=$(echo "$last_row" | cut -d'|' -f1 | xargs)

  # Verify it matches today's date (YYYY-MM-DD)
  expected_date=$(date -u +%Y-%m-%d)
  [[ "$date_field" == "$expected_date" ]]
}

# ── metrics_display Tests ─────────────────────────────────────────────────

@test "metrics_display shows table for valid history" {
  cat > "$TEST_HISTORY_FILE" <<'EOF'
date | run_id | headline_% | tokens_avg | completion_% | stack_breakdown_json
-----|--------|------------|------------|--------------|---------------------
2026-04-26 | run-001 | 85 | 45000 | 92 | {"backend":90}
EOF

  run metrics_display "$TEST_HISTORY_FILE"
  [ "$status" -eq 0 ]
  [[ "$output" == *"Date"* ]]
  [[ "$output" == *"Run ID"* ]]
  [[ "$output" == *"Headline %"* ]]
}

@test "metrics_display shows 4-week trailing average" {
  cat > "$TEST_HISTORY_FILE" <<'EOF'
date | run_id | headline_% | tokens_avg | completion_% | stack_breakdown_json
-----|--------|------------|------------|--------------|---------------------
2026-04-26 | run-001 | 85 | 45000 | 92 | {}
2026-04-19 | run-002 | 80 | 48000 | 88 | {}
EOF

  run metrics_display "$TEST_HISTORY_FILE"
  [ "$status" -eq 0 ]
  [[ "$output" == *"4-week trailing average"* ]]
  [[ "$output" == *"82.5"* ]]
}

@test "metrics_display handles empty history gracefully" {
  cat > "$TEST_HISTORY_FILE" <<'EOF'
date | run_id | headline_% | tokens_avg | completion_% | stack_breakdown_json
-----|--------|------------|------------|--------------|---------------------
EOF

  run metrics_display "$TEST_HISTORY_FILE"
  [ "$status" -eq 0 ]
  [[ "$output" == *"No canary runs recorded yet"* ]]
}

@test "metrics_display exits with code 2 for corrupted schema" {
  cat > "$TEST_HISTORY_FILE" <<'EOF'
date | run_id | headline_%
-----|--------|------------
2026-04-26 | run-001 | 85
EOF

  run metrics_display "$TEST_HISTORY_FILE"
  [ "$status" -eq 2 ]
}
