#!/usr/bin/env bash
# Shared timeout budget helper for long Bats tests.

monozukuri_test_timeout_start() {
  local seconds="${1:-${MONOZUKURI_BATS_TEST_TIMEOUT_SECONDS:-120}}"
  local label="${2:-${BATS_TEST_DESCRIPTION:-${BATS_TEST_NAME:-bats-test}}}"

  if ! [[ "$seconds" =~ ^[0-9]+$ ]] || [ "$seconds" -le 0 ]; then
    return 0
  fi

  (
    sleep "$seconds"
    printf 'monozukuri test timeout after %ss: %s\n' "$seconds" "$label" >&2
    kill -TERM "$$" 2>/dev/null || true
  ) &
  MONOZUKURI_TEST_TIMEOUT_PID="$!"
  export MONOZUKURI_TEST_TIMEOUT_PID
}

monozukuri_test_timeout_stop() {
  if [ -n "${MONOZUKURI_TEST_TIMEOUT_PID:-}" ]; then
    pkill -TERM -P "$MONOZUKURI_TEST_TIMEOUT_PID" 2>/dev/null || true
    kill "$MONOZUKURI_TEST_TIMEOUT_PID" 2>/dev/null || true
    wait "$MONOZUKURI_TEST_TIMEOUT_PID" 2>/dev/null || true
    unset MONOZUKURI_TEST_TIMEOUT_PID
  fi
}
