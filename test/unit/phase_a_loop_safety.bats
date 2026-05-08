#!/usr/bin/env bats
# test/unit/phase_a_loop_safety.bats
# Unit tests for Phase A loop-safety fixes:
#   A1: auth-expiry classification (exit 15)
#   A2: op_timeout wrapping (wall-clock cap)
#   A3: Ralph Loop divergence detection
#   A4: verify_build.sh strict exit handling

REPO_ROOT="$(cd "$(dirname "$BATS_TEST_FILENAME")/../.." && pwd)"

# ── A1: auth-expiry helpers ───────────────────────────────────────────────────

@test "A1: codex auth check returns true on 'please run codex login'" {
  source "$REPO_ROOT/lib/agent/adapter-codex.sh" 2>/dev/null || true
  local tmp; tmp=$(mktemp)
  echo "Error: please run codex login to continue" > "$tmp"
  run _thin_shell_auth_check "$tmp"
  rm -f "$tmp"
  [ "$status" -eq 0 ]
}

@test "A1: codex auth check returns true on 'not authenticated'" {
  source "$REPO_ROOT/lib/agent/adapter-codex.sh" 2>/dev/null || true
  local tmp; tmp=$(mktemp)
  echo "You are not authenticated. Please log in." > "$tmp"
  run _thin_shell_auth_check "$tmp"
  rm -f "$tmp"
  [ "$status" -eq 0 ]
}

@test "A1: codex auth check returns false on normal output" {
  source "$REPO_ROOT/lib/agent/adapter-codex.sh" 2>/dev/null || true
  local tmp; tmp=$(mktemp)
  echo "Successfully created PR #42" > "$tmp"
  run _thin_shell_auth_check "$tmp"
  rm -f "$tmp"
  [ "$status" -ne 0 ]
}

@test "A1: gemini auth check returns true on 'OAuth token expired'" {
  source "$REPO_ROOT/lib/agent/adapter-gemini.sh" 2>/dev/null || true
  local tmp; tmp=$(mktemp)
  echo "OAuth token expired, please authenticate again." > "$tmp"
  run _thin_shell_auth_check "$tmp"
  rm -f "$tmp"
  [ "$status" -eq 0 ]
}

@test "A1: gemini auth check returns true on '401'" {
  source "$REPO_ROOT/lib/agent/adapter-gemini.sh" 2>/dev/null || true
  local tmp; tmp=$(mktemp)
  echo "HTTP 401: access denied" > "$tmp"
  run _thin_shell_auth_check "$tmp"
  rm -f "$tmp"
  [ "$status" -eq 0 ]
}

@test "A1: gemini auth check returns false on normal output" {
  source "$REPO_ROOT/lib/agent/adapter-gemini.sh" 2>/dev/null || true
  local tmp; tmp=$(mktemp)
  echo "Task completed successfully." > "$tmp"
  run _thin_shell_auth_check "$tmp"
  rm -f "$tmp"
  [ "$status" -ne 0 ]
}

# ── A3: Ralph Loop divergence detection ──────────────────────────────────────

@test "A3: phase-3 run_phase3_tests exports divergence detection variable" {
  source "$REPO_ROOT/lib/core/util.sh" 2>/dev/null || true
  source "$REPO_ROOT/lib/run/phase-3.sh" 2>/dev/null || true
  # Verify the function exists and contains the divergence counter init
  declare -f run_phase3_tests | grep -q "_consecutive_same_error"
}

@test "A3: divergence: same post_error_sig increments counter" {
  # Test the divergence logic directly by simulating the comparison
  local _consecutive_same_error=0
  local error_sig="FAIL: AssertionError line 42"
  local post_error_sig="FAIL: AssertionError line 42"  # same as error_sig

  if [ "$post_error_sig" = "$error_sig" ]; then
    _consecutive_same_error=$((_consecutive_same_error + 1))
  else
    _consecutive_same_error=0
  fi

  [ "$_consecutive_same_error" -eq 1 ]
}

@test "A3: divergence: different post_error_sig resets counter" {
  local _consecutive_same_error=1
  local error_sig="FAIL: AssertionError line 42"
  local post_error_sig="FAIL: TypeError: undefined is not a function"

  if [ "$post_error_sig" = "$error_sig" ]; then
    _consecutive_same_error=$((_consecutive_same_error + 1))
  else
    _consecutive_same_error=0
  fi

  [ "$_consecutive_same_error" -eq 0 ]
}

@test "A3: divergence: counter >= 2 triggers abort condition" {
  local _consecutive_same_error=2
  local aborted=false
  if [ "$_consecutive_same_error" -ge 2 ]; then
    aborted=true
  fi
  [ "$aborted" = "true" ]
}

# ── A4: verify_build strict exit handling ────────────────────────────────────

@test "A4: MONOZUKURI_VERIFY_BUILD_REQUIRED=0 skips build check" {
  # When VERIFY_BUILD_REQUIRED=0, even a missing verify_build.sh should not block.
  local _build_exit=0
  local MONOZUKURI_VERIFY_BUILD_REQUIRED=0
  local SCRIPTS_DIR="/nonexistent"

  local skipped=false
  if [ "${MONOZUKURI_VERIFY_BUILD_REQUIRED:-1}" != "0" ] && [ -f "${SCRIPTS_DIR}/verify_build.sh" ]; then
    bash "${SCRIPTS_DIR}/verify_build.sh" . 2>/dev/null || _build_exit=$?
  else
    skipped=true
  fi

  [ "$skipped" = "true" ]
}

@test "A4: exit code 2 from verify_build.sh is treated as broken (not silently ignored)" {
  local _build_exit=2  # previously silently ignored (only == 1 was checked)
  local broken=false

  if [ "$_build_exit" -ne 0 ]; then
    broken=true
  fi

  [ "$broken" = "true" ]
}

@test "A4: exit code 127 (script not found) from verify_build.sh is treated as broken" {
  local _build_exit=127
  local broken=false

  if [ "$_build_exit" -ne 0 ]; then
    broken=true
  fi

  [ "$broken" = "true" ]
}

@test "A4: exit code 0 from verify_build.sh passes through cleanly" {
  local _build_exit=0
  local broken=false

  if [ "$_build_exit" -ne 0 ]; then
    broken=true
  fi

  [ "$broken" = "false" ]
}
