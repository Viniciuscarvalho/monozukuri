#!/usr/bin/env bats
# test/unit/lib_review_bundle.bats — unit tests for lib/review/bundle.sh

setup() {
  REPO_ROOT="$(cd "$(dirname "$BATS_TEST_FILENAME")/../.." && pwd)"
  LIB_DIR="$REPO_ROOT/lib"
  MONOZUKURI_HOME="$REPO_ROOT"
  export LIB_DIR MONOZUKURI_HOME

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

  # Source bundle.sh
  source "$LIB_DIR/review/bundle.sh"
}

teardown() {
  rm -rf "$TMPDIR_TEST"
}

_create_test_run() {
  local run_id="${1:-run-test-001}"
  local run_dir="$CONFIG_DIR/runs/$run_id"
  mkdir -p "$run_dir"

  # Create manifest.json
  cat > "$run_dir/manifest.json" <<'EOF'
{
  "run_id": "run-test-001",
  "started_at": "2026-04-26T10:00:00Z",
  "features": [
    {
      "feat_id": "feat-001",
      "status": "done",
      "pr_url": "https://github.com/user/repo/pull/1"
    }
  ]
}
EOF

  # Create report.json
  cat > "$run_dir/report.json" <<'EOF'
{
  "run_id": "run-test-001",
  "started_at": "2026-04-26T10:00:00Z",
  "finished_at": "2026-04-26T11:00:00Z",
  "duration_seconds": 3600,
  "headline_pct": 100,
  "total_features": 1,
  "completed_features": 1,
  "failed_features": 0,
  "total_tokens": 10000,
  "total_cost_usd": 0.50,
  "features": [
    {
      "id": "feat-001",
      "title": "Test feature",
      "stack": "backend",
      "status": "done",
      "pr_url": "https://github.com/user/repo/pull/1",
      "tokens": 10000,
      "cost_usd": 0.50,
      "phases_completed": 6,
      "phase_retries": 0,
      "failure_reason": null
    }
  ]
}
EOF

  echo "$run_id"
}

# ── generate_bundle ───────────────────────────────────────────────────────────

@test "generate_bundle: no run-id — fails" {
  run generate_bundle
  [ "$status" -eq 1 ]
  [[ "$output" == *"run_id required"* ]]
}

@test "generate_bundle: run directory not found — fails" {
  run generate_bundle "nonexistent-run"
  [ "$status" -eq 1 ]
  [[ "$output" == *"Run directory not found"* ]]
}

@test "generate_bundle: no manifest.json — fails" {
  local run_id="run-no-manifest"
  mkdir -p "$CONFIG_DIR/runs/$run_id"

  run generate_bundle "$run_id"
  [ "$status" -eq 1 ]
  [[ "$output" == *"No manifest.json"* ]]
}

@test "generate_bundle: no report.json — fails" {
  local run_id="run-no-report"
  local run_dir="$CONFIG_DIR/runs/$run_id"
  mkdir -p "$run_dir"
  echo '{"run_id":"run-no-report"}' > "$run_dir/manifest.json"

  run generate_bundle "$run_id"
  [ "$status" -eq 1 ]
  [[ "$output" == *"No report.json"* ]]
}

@test "generate_bundle: valid run — creates bundle" {
  local run_id
  run_id=$(_create_test_run)

  run generate_bundle "$run_id"
  [ "$status" -eq 0 ]

  local bundle_path="$CONFIG_DIR/runs/$run_id/review/index.html"
  [ -f "$bundle_path" ]
  echo "$output" | grep -q "$bundle_path"
}

@test "generate_bundle: bundle contains report data" {
  local run_id
  run_id=$(_create_test_run)

  generate_bundle "$run_id"

  local bundle_path="$CONFIG_DIR/runs/$run_id/review/index.html"
  grep -q '"run_id":"run-test-001"' "$bundle_path"
  grep -q '"headline_pct":100' "$bundle_path"
  grep -q '"total_features":1' "$bundle_path"
}

@test "generate_bundle: bundle contains manifest data" {
  local run_id
  run_id=$(_create_test_run)

  generate_bundle "$run_id"

  local bundle_path="$CONFIG_DIR/runs/$run_id/review/index.html"
  grep -q '"started_at":"2026-04-26T10:00:00Z"' "$bundle_path"
}

@test "generate_bundle: bundle is valid HTML" {
  local run_id
  run_id=$(_create_test_run)

  generate_bundle "$run_id"

  local bundle_path="$CONFIG_DIR/runs/$run_id/review/index.html"
  grep -q '<!DOCTYPE html>' "$bundle_path"
  grep -q '<html' "$bundle_path"
  grep -q '</html>' "$bundle_path"
  grep -q '<script>' "$bundle_path"
}

@test "generate_bundle: invalid JSON in manifest — fails" {
  local run_id="run-bad-manifest"
  local run_dir="$CONFIG_DIR/runs/$run_id"
  mkdir -p "$run_dir"
  echo 'invalid json' > "$run_dir/manifest.json"
  echo '{"run_id":"test"}' > "$run_dir/report.json"

  run generate_bundle "$run_id"
  [ "$status" -eq 1 ]
  [[ "$output" == *"Invalid JSON"* ]]
}

@test "generate_bundle: invalid JSON in report — fails" {
  local run_id="run-bad-report"
  local run_dir="$CONFIG_DIR/runs/$run_id"
  mkdir -p "$run_dir"
  echo '{"run_id":"test"}' > "$run_dir/manifest.json"
  echo 'invalid json' > "$run_dir/report.json"

  run generate_bundle "$run_id"
  [ "$status" -eq 1 ]
  [[ "$output" == *"Invalid JSON"* ]]
}

# ── render_template ───────────────────────────────────────────────────────────

@test "render_template: replaces placeholders" {
  local manifest='{"run_id":"test"}'
  local report='{"headline_pct":85}'

  run render_template "$manifest" "$report"
  [ "$status" -eq 0 ]
  echo "$output" | grep -q 'headline_pct'
  echo "$output" | grep -q 'run_id'
}

@test "render_template: output is valid HTML" {
  local manifest='{"run_id":"test"}'
  local report='{"headline_pct":85,"features":[]}'

  run render_template "$manifest" "$report"
  [ "$status" -eq 0 ]
  echo "$output" | grep -q '<!DOCTYPE html>'
  echo "$output" | grep -q '<body>'
}
