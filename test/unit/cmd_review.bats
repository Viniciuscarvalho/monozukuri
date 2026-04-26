#!/usr/bin/env bats
# test/unit/cmd_review.bats — unit tests for cmd/review.sh

setup() {
  REPO_ROOT="$(cd "$(dirname "$BATS_TEST_FILENAME")/../.." && pwd)"
  LIB_DIR="$REPO_ROOT/lib"
  CMD_DIR="$REPO_ROOT/cmd"
  MONOZUKURI_HOME="$REPO_ROOT"
  export LIB_DIR CMD_DIR MONOZUKURI_HOME

  TMPDIR_TEST="$(mktemp -d)"
  STATE_DIR="$TMPDIR_TEST/state"
  CONFIG_DIR="$TMPDIR_TEST/.monozukuri"
  ROOT_DIR="$TMPDIR_TEST"
  export STATE_DIR CONFIG_DIR ROOT_DIR

  mkdir -p "$STATE_DIR" "$CONFIG_DIR/runs"

  # Minimal stubs for module system
  source "$LIB_DIR/core/modules.sh"
  modules_init "$LIB_DIR"
  module_require core/util
  module_require cli/output

  # Define helper functions (from orchestrate.sh)
  log()    { printf "[orchestrate] %s\n" "$*"; }
  info()   { printf "  [orchestrate] %s\n" "$*"; }
  warn()   { printf "⚠  [orchestrate] %s\n" "$*" >&2; }
  err()    { printf "✗ [orchestrate] %s\n" "$*" >&2; }
  banner() { printf "\n═══════════════════════════════════════════════════\n  %s\n═══════════════════════════════════════════════════\n" "$*"; }

  # Source bundle generator
  source "$LIB_DIR/review/bundle.sh"

  # Source cmd/review.sh
  source "$CMD_DIR/review.sh"
}

teardown() {
  rm -rf "$TMPDIR_TEST"
}

_create_dummy_run() {
  local run_id="${1:-run-test-001}"
  local run_dir="$CONFIG_DIR/runs/$run_id"
  mkdir -p "$run_dir"

  # Create manifest.json
  cat > "$run_dir/manifest.json" <<EOF
{
  "run_id": "$run_id",
  "started_at": "2026-04-26T10:00:00Z",
  "features": []
}
EOF

  # Create report.json
  cat > "$run_dir/report.json" <<EOF
{
  "run_id": "$run_id",
  "started_at": "2026-04-26T10:00:00Z",
  "finished_at": "2026-04-26T11:00:00Z",
  "duration_seconds": 3600,
  "headline_pct": 85,
  "total_features": 10,
  "completed_features": 8,
  "failed_features": 2,
  "total_tokens": 50000,
  "total_cost_usd": 1.25,
  "features": []
}
EOF

  echo "$run_id"
}

# ── routing tests ─────────────────────────────────────────────────────────────

@test "sub_review: no action — prints usage" {
  run sub_review
  [ "$status" -eq 1 ]
  [[ "$output" == *"Usage: monozukuri review"* ]]
}

@test "sub_review: invalid action — prints usage" {
  run sub_review invalid
  [ "$status" -eq 1 ]
  [[ "$output" == *"Unknown review subcommand"* ]]
}

# ── export command ────────────────────────────────────────────────────────────

@test "review_export: no run-id — exits with error" {
  run review_export
  [ "$status" -eq 1 ]
  [[ "$output" == *"Usage"* ]]
}

@test "review_export: invalid run-id — exits with error" {
  run review_export "nonexistent-run"
  [ "$status" -eq 1 ]
  [[ "$output" == *"manifest not found"* ]] || [[ "$output" == *"Run directory not found"* ]]
}

@test "review_export: valid run — generates bundle" {
  local run_id
  run_id=$(_create_dummy_run)

  run review_export "$run_id"
  [ "$status" -eq 0 ]
  [[ "$output" == *"Bundle generated successfully"* ]]

  local bundle_path="$CONFIG_DIR/runs/$run_id/review/index.html"
  [ -f "$bundle_path" ]
}

# ── open command ──────────────────────────────────────────────────────────────

@test "review_open: no run-id — exits with error" {
  run review_open
  [ "$status" -eq 1 ]
  [[ "$output" == *"Usage"* ]]
}

@test "review_open: generates bundle for valid run" {
  local run_id
  run_id=$(_create_dummy_run)

  # Mock open command to avoid actually opening browser
  open() { echo "mock open called"; }
  export -f open

  run review_open "$run_id"
  [ "$status" -eq 0 ]

  local bundle_path="$CONFIG_DIR/runs/$run_id/review/index.html"
  [ -f "$bundle_path" ]
}

# ── list command ──────────────────────────────────────────────────────────────

@test "review_list: no runs — prints no runs message" {
  run review_list
  [ "$status" -eq 0 ]
  [[ "$output" == *"No completed runs"* ]] || [[ "$output" == *"No runs found"* ]]
}

@test "review_list: with runs — displays table" {
  _create_dummy_run "run-20260426-100000"
  _create_dummy_run "run-20260425-090000"

  run review_list
  [ "$status" -eq 0 ]
  [[ "$output" == *"Available Runs"* ]]
  [[ "$output" == *"run-20260426-100000"* ]]
  [[ "$output" == *"run-20260425-090000"* ]]
  [[ "$output" == *"HEADLINE"* ]]
  [[ "$output" == *"FEATURES"* ]]
}

@test "review_list: sorted by date descending" {
  _create_dummy_run "run-20260424-080000"
  _create_dummy_run "run-20260426-100000"
  _create_dummy_run "run-20260425-090000"

  run review_list
  [ "$status" -eq 0 ]

  # Newest should appear first
  local output_lines=("${lines[@]}")
  local idx_newest idx_middle idx_oldest
  for i in "${!output_lines[@]}"; do
    [[ "${output_lines[$i]}" == *"run-20260426-100000"* ]] && idx_newest=$i
    [[ "${output_lines[$i]}" == *"run-20260425-090000"* ]] && idx_middle=$i
    [[ "${output_lines[$i]}" == *"run-20260424-080000"* ]] && idx_oldest=$i
  done

  # Ensure newest < middle < oldest (lower line number = earlier in output)
  [ "${idx_newest:-99}" -lt "${idx_middle:-99}" ]
  [ "${idx_middle:-99}" -lt "${idx_oldest:-99}" ]
}
