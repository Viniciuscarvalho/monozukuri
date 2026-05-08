#!/usr/bin/env bats
# test/integration/run_budget_pause.bats
#
# Verifies that when all features trip the lifetime-token budget guard,
# the run manifest is finalized as "paused" (not "completed").
# Regression test for the mislabel introduced when manifest_finalize
# always received the hardcoded string "completed".

REPO_ROOT="$(cd "$(dirname "$BATS_TEST_FILENAME")/../.." && pwd)"
LIB_DIR="$REPO_ROOT/lib"

setup() {
  export REPO_ROOT LIB_DIR

  TMPDIR_TEST="$(mktemp -d)"
  export TMPDIR_TEST

  # Minimal .monozukuri project config
  CONFIG_DIR="$TMPDIR_TEST/.monozukuri"
  STATE_DIR="$CONFIG_DIR/state"
  mkdir -p "$STATE_DIR"
  export CONFIG_DIR STATE_DIR

  cat > "$CONFIG_DIR/config.yaml" <<'EOCFG'
source:
  adapter: markdown
  markdown:
    file: features.md
autonomy: full_auto
execution:
  base_branch: main
EOCFG

  # Seed cost.json for feat-001 so it exceeds the cap immediately.
  # MONOZUKURI_MAX_FEATURE_TOKENS will be set to 1 in the test.
  mkdir -p "$STATE_DIR/feat-001"
  printf '{"cumulative_tokens":9999,"last_run_tokens":9999}' \
    > "$STATE_DIR/feat-001/cost.json"

  # Source only the modules needed for the finalization block under test.
  source "$LIB_DIR/run/manifest.sh"

  # Stub out everything pipeline.sh would call — we only exercise the
  # manifest_finalize status-derivation logic in cmd/run.sh's finalize block.
  monozukuri_emit() { :; }
  info()  { :; }
  warn()  { :; }
  err()   { :; }
  export -f monozukuri_emit info warn err

  # Write a paused status.json for feat-001 (simulates budget guard)
  printf '{"status":"paused","reason":"budget-exceeded"}' \
    > "$STATE_DIR/feat-001/status.json"

  # Initialize a manifest so manifest_finalize has something to write
  MANIFEST_RUN_ID="test-run-$$"
  export MANIFEST_RUN_ID
  manifest_init "$MANIFEST_RUN_ID" > /dev/null
}

teardown() {
  rm -rf "$TMPDIR_TEST"
}

# Simulate the finalization block from cmd/run.sh using the same logic.
# We source it inline rather than shelling out to the full orchestrator
# so the test stays fast and doesn't require a real agent.
_run_finalize_block() {
  local _done_count=0 _paused_count=0 _failed_count=0
  if [ -d "${STATE_DIR:-}" ]; then
    _done_count=$(find "$STATE_DIR" -name status.json -exec \
      node -p "try{const d=JSON.parse(require('fs').readFileSync('{}','utf-8'));['done','pr-created'].includes(d.status)?'1':''}catch(e){''}" \; \
      2>/dev/null | { grep -c "^1$" || true; })
    _paused_count=$(find "$STATE_DIR" -name status.json -exec \
      node -p "try{const d=JSON.parse(require('fs').readFileSync('{}','utf-8'));d.status==='paused'?'1':''}catch(e){''}" \; \
      2>/dev/null | { grep -c "^1$" || true; })
    _failed_count=$(find "$STATE_DIR" -name status.json -exec \
      node -p "try{const d=JSON.parse(require('fs').readFileSync('{}','utf-8'));d.status==='failed'?'1':''}catch(e){''}" \; \
      2>/dev/null | { grep -c "^1$" || true; })
  fi

  local _run_final="completed"
  if (( _failed_count > 0 )); then
    _run_final="failed"
  elif (( _done_count == 0 && _paused_count > 0 )); then
    _run_final="paused"
  fi

  manifest_finalize "$MANIFEST_RUN_ID" "$_run_final"
}

@test "budget-only run is finalized as paused, not completed" {
  _run_finalize_block

  local manifest_file="$CONFIG_DIR/runs/$MANIFEST_RUN_ID/manifest.json"
  [ -f "$manifest_file" ]

  local status
  status=$(node -p "JSON.parse(require('fs').readFileSync('$manifest_file','utf-8')).status")
  [ "$status" = "paused" ]
}

@test "run with one done and one paused feature is finalized as completed" {
  # Add a second feature that succeeded
  mkdir -p "$STATE_DIR/feat-002"
  printf '{"status":"done"}' > "$STATE_DIR/feat-002/status.json"

  _run_finalize_block

  local manifest_file="$CONFIG_DIR/runs/$MANIFEST_RUN_ID/manifest.json"
  local status
  status=$(node -p "JSON.parse(require('fs').readFileSync('$manifest_file','utf-8')).status")
  [ "$status" = "completed" ]
}

@test "run with any failed feature is finalized as failed" {
  printf '{"status":"failed"}' > "$STATE_DIR/feat-001/status.json"

  _run_finalize_block

  local manifest_file="$CONFIG_DIR/runs/$MANIFEST_RUN_ID/manifest.json"
  local status
  status=$(node -p "JSON.parse(require('fs').readFileSync('$manifest_file','utf-8')).status")
  [ "$status" = "failed" ]
}
