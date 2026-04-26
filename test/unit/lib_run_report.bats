#!/usr/bin/env bats
# test/unit/lib_run_report.bats — unit tests for lib/run/report.sh

setup() {
  REPO_ROOT="$(cd "$(dirname "$BATS_TEST_FILENAME")/../.." && pwd)"
  LIB_DIR="$REPO_ROOT/lib"
  export LIB_DIR

  TMPDIR_TEST="$(mktemp -d)"
  STATE_DIR="$TMPDIR_TEST/state"
  CONFIG_DIR="$TMPDIR_TEST/.monozukuri"
  ROOT_DIR="$TMPDIR_TEST"
  export STATE_DIR CONFIG_DIR ROOT_DIR

  mkdir -p "$STATE_DIR" "$CONFIG_DIR/runs"

  # Load modules
  source "$LIB_DIR/core/modules.sh"
  modules_init "$LIB_DIR"
  module_require core/util
  module_require cli/output

  # Define helper functions (from orchestrate.sh)
  log()    { printf "[orchestrate] %s\n" "$*"; }
  info()   { printf "  [orchestrate] %s\n" "$*"; }
  warn()   { printf "⚠  [orchestrate] %s\n" "$*" >&2; }
  err()    { printf "✗ [orchestrate] %s\n" "$*" >&2; }

  # Source report.sh
  source "$LIB_DIR/run/report.sh"
}

teardown() {
  rm -rf "$TMPDIR_TEST"
}

_create_test_manifest() {
  local run_id="${1:-run-test-001}"
  local features="${2:-1}"
  local run_dir="$CONFIG_DIR/runs/$run_id"
  mkdir -p "$run_dir"

  # Build features array
  local features_json="[]"
  if [ "$features" -gt 0 ]; then
    features_json='[{"feat_id":"feat-001","status":"done","pr_url":"https://github.com/user/repo/pull/1"}]'
  fi

  cat > "$run_dir/manifest.json" <<EOF
{
  "run_id": "$run_id",
  "started_at": "2026-04-26T10:00:00Z",
  "updated_at": "2026-04-26T11:00:00Z",
  "status": "running",
  "features": $features_json
}
EOF

  echo "$run_id"
}

_create_feature_checkpoint() {
  local feat_id="${1:-feat-001}"
  local tokens="${2:-10000}"
  local cost="${3:-0.50}"

  local feat_dir="$STATE_DIR/$feat_id"
  mkdir -p "$feat_dir"

  cat > "$feat_dir/cost.json" <<EOF
{
  "total_tokens": $tokens,
  "total_cost": $cost
}
EOF

  cat > "$feat_dir/status.json" <<EOF
{
  "feat_id": "$feat_id",
  "title": "Test feature",
  "stack": "backend",
  "phases_completed": 6,
  "phase_retries": 0,
  "failure_reason": null
}
EOF
}

# ── generate_run_report ───────────────────────────────────────────────────────

@test "generate_run_report: no run-id — fails" {
  run generate_run_report
  [ "$status" -eq 1 ]
  [[ "$output" == *"run_id required"* ]]
}

@test "generate_run_report: manifest not found — fails" {
  run generate_run_report "nonexistent-run"
  [ "$status" -eq 1 ]
  [[ "$output" == *"manifest not found"* ]]
}

@test "generate_run_report: creates report.json" {
  local run_id
  run_id=$(_create_test_manifest)

  run generate_run_report "$run_id"
  [ "$status" -eq 0 ]

  local report_file="$CONFIG_DIR/runs/$run_id/report.json"
  [ -f "$report_file" ]
}

@test "generate_run_report: report contains run_id" {
  local run_id
  run_id=$(_create_test_manifest)

  generate_run_report "$run_id"

  local report_file="$CONFIG_DIR/runs/$run_id/report.json"
  local reported_run_id
  reported_run_id=$(jq -r '.run_id' "$report_file")
  [ "$reported_run_id" = "$run_id" ]
}

@test "generate_run_report: calculates duration" {
  local run_id
  run_id=$(_create_test_manifest)

  generate_run_report "$run_id"

  local report_file="$CONFIG_DIR/runs/$run_id/report.json"
  local duration
  duration=$(jq -r '.duration_seconds' "$report_file")
  [ "$duration" -ge 0 ]
}

@test "generate_run_report: calculates headline percentage" {
  local run_id
  run_id=$(_create_test_manifest "run-test-001" 1)

  generate_run_report "$run_id"

  local report_file="$CONFIG_DIR/runs/$run_id/report.json"
  local headline
  headline=$(jq -r '.headline_pct' "$report_file")
  [ "$headline" -eq 100 ]  # 1 completed out of 1 total
}

@test "generate_run_report: handles zero features" {
  local run_id
  run_id=$(_create_test_manifest "run-test-empty" 0)

  generate_run_report "$run_id"

  local report_file="$CONFIG_DIR/runs/$run_id/report.json"
  local total
  total=$(jq -r '.total_features' "$report_file")
  [ "$total" -eq 0 ]

  local headline
  headline=$(jq -r '.headline_pct' "$report_file")
  [ "$headline" -eq 0 ]
}

@test "generate_run_report: aggregates tokens and cost" {
  local run_id
  run_id=$(_create_test_manifest)
  _create_feature_checkpoint "feat-001" 10000 0.50

  generate_run_report "$run_id"

  local report_file="$CONFIG_DIR/runs/$run_id/report.json"
  local tokens
  tokens=$(jq -r '.total_tokens' "$report_file")
  [ "$tokens" -eq 10000 ]

  local cost
  cost=$(jq -r '.total_cost_usd' "$report_file")
  # Use bc for floating point comparison
  [ "$(echo "$cost >= 0.50" | bc)" -eq 1 ]
}

@test "generate_run_report: enriches features with checkpoint data" {
  local run_id
  run_id=$(_create_test_manifest)
  _create_feature_checkpoint "feat-001" 5000 0.25

  generate_run_report "$run_id"

  local report_file="$CONFIG_DIR/runs/$run_id/report.json"
  local feature_tokens
  feature_tokens=$(jq -r '.features[0].tokens' "$report_file")
  [ "$feature_tokens" -eq 5000 ]

  local feature_cost
  feature_cost=$(jq -r '.features[0].cost_usd' "$report_file")
  [ "$(echo "$feature_cost >= 0.25" | bc)" -eq 1 ]

  local feature_title
  feature_title=$(jq -r '.features[0].title' "$report_file")
  [ "$feature_title" = "Test feature" ]
}

@test "generate_run_report: report has correct schema" {
  local run_id
  run_id=$(_create_test_manifest)

  generate_run_report "$run_id"

  local report_file="$CONFIG_DIR/runs/$run_id/report.json"

  # Validate required fields exist
  jq -e '.run_id' "$report_file" >/dev/null
  jq -e '.started_at' "$report_file" >/dev/null
  jq -e '.finished_at' "$report_file" >/dev/null
  jq -e '.duration_seconds' "$report_file" >/dev/null
  jq -e '.headline_pct' "$report_file" >/dev/null
  jq -e '.total_features' "$report_file" >/dev/null
  jq -e '.completed_features' "$report_file" >/dev/null
  jq -e '.failed_features' "$report_file" >/dev/null
  jq -e '.total_tokens' "$report_file" >/dev/null
  jq -e '.total_cost_usd' "$report_file" >/dev/null
  jq -e '.features' "$report_file" >/dev/null
}

@test "generate_run_report: handles missing checkpoint files gracefully" {
  local run_id
  run_id=$(_create_test_manifest)
  # Don't create checkpoint files

  run generate_run_report "$run_id"
  [ "$status" -eq 0 ]

  local report_file="$CONFIG_DIR/runs/$run_id/report.json"
  [ -f "$report_file" ]

  # Tokens and cost should be 0
  local tokens
  tokens=$(jq -r '.total_tokens' "$report_file")
  [ "$tokens" -eq 0 ]
}
