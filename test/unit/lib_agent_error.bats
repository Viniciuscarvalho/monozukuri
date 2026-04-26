#!/usr/bin/env bats
# test/unit/lib_agent_error.bats — unit tests for lib/agent/error.sh

setup() {
  REPO_ROOT="$(cd "$(dirname "$BATS_TEST_FILENAME")/../.." && pwd)"
  LIB_DIR="$REPO_ROOT/lib"
  export LIB_DIR

  warn() { echo "WARN: $*" >&2; }
  info() { echo "INFO: $*" >&2; }
  export -f warn info

  source "$LIB_DIR/agent/error.sh"

  TMPDIR_TEST="$(mktemp -d)"
  MONOZUKURI_ERROR_FILE=""
  export MONOZUKURI_ERROR_FILE
}

teardown() {
  rm -rf "$TMPDIR_TEST"
}

# ── agent_error_classify: adapter-written envelope ───────────────────────────

@test "agent_error_classify: returns adapter envelope when valid class present" {
  echo '{"class":"fatal","code":"auth-failure","message":"bad key"}' \
    > "$TMPDIR_TEST/err.json"
  MONOZUKURI_ERROR_FILE="$TMPDIR_TEST/err.json" export MONOZUKURI_ERROR_FILE
  result=$(agent_error_classify 1 "" "$TMPDIR_TEST/err.json")
  [[ "$result" == *'"class":"fatal"'* ]]
  [[ "$result" == *'"code":"auth-failure"'* ]]
}

@test "agent_error_classify: ignores adapter file with invalid class" {
  echo '{"class":"bogus","code":"x","message":"y"}' \
    > "$TMPDIR_TEST/err.json"
  result=$(agent_error_classify 1 "" "$TMPDIR_TEST/err.json")
  # should fall through to heuristic — exit 1 with no log → unknown
  [[ "$result" == *'"class":"unknown"'* ]]
}

# ── agent_error_classify: timeout exit codes ──────────────────────────────────

@test "agent_error_classify: exit 124 → transient/timeout" {
  result=$(agent_error_classify 124 "")
  [[ "$result" == *'"class":"transient"'* ]]
  [[ "$result" == *'"code":"timeout"'* ]]
}

@test "agent_error_classify: exit 137 → transient/timeout" {
  result=$(agent_error_classify 137 "")
  [[ "$result" == *'"class":"transient"'* ]]
  [[ "$result" == *'"code":"timeout"'* ]]
}

# ── agent_error_classify: log pattern heuristics ─────────────────────────────

@test "agent_error_classify: rate-limit pattern → transient/rate-limit" {
  printf 'Error: rate limit exceeded\n' > "$TMPDIR_TEST/run.log"
  result=$(agent_error_classify 1 "$TMPDIR_TEST/run.log")
  [[ "$result" == *'"class":"transient"'* ]]
  [[ "$result" == *'"code":"rate-limit"'* ]]
}

@test "agent_error_classify: 429 in log → transient/rate-limit" {
  printf 'HTTP 429 Too Many Requests\n' > "$TMPDIR_TEST/run.log"
  result=$(agent_error_classify 1 "$TMPDIR_TEST/run.log")
  [[ "$result" == *'"class":"transient"'* ]]
  [[ "$result" == *'"code":"rate-limit"'* ]]
}

@test "agent_error_classify: retry-after header extracted from log" {
  printf 'Retry-After: 120\nrate limit exceeded\n' > "$TMPDIR_TEST/run.log"
  result=$(agent_error_classify 1 "$TMPDIR_TEST/run.log")
  [[ "$result" == *'"retryable_after":120'* ]]
}

@test "agent_error_classify: auth failure → fatal/auth-failure" {
  printf 'Error: Unauthorized — invalid API key\n' > "$TMPDIR_TEST/run.log"
  result=$(agent_error_classify 1 "$TMPDIR_TEST/run.log")
  [[ "$result" == *'"class":"fatal"'* ]]
  [[ "$result" == *'"code":"auth-failure"'* ]]
}

@test "agent_error_classify: command not found → fatal/tool-missing" {
  printf 'bash: claude: command not found\n' > "$TMPDIR_TEST/run.log"
  result=$(agent_error_classify 127 "$TMPDIR_TEST/run.log")
  [[ "$result" == *'"class":"fatal"'* ]]
  [[ "$result" == *'"code":"tool-missing"'* ]]
}

@test "agent_error_classify: unknown exit code → unknown class" {
  result=$(agent_error_classify 42 "")
  [[ "$result" == *'"class":"unknown"'* ]]
  [[ "$result" == *'"code":"exit-42"'* ]]
}

# ── agent_error_field ─────────────────────────────────────────────────────────

@test "agent_error_field: extracts class" {
  envelope='{"class":"transient","code":"timeout","message":"timed out","retryable_after":0}'
  result=$(agent_error_field "$envelope" "class")
  [ "$result" = "transient" ]
}

@test "agent_error_field: extracts retryable_after" {
  envelope='{"class":"transient","code":"rate-limit","message":"too many","retryable_after":300}'
  result=$(agent_error_field "$envelope" "retryable_after")
  [ "$result" = "300" ]
}

@test "agent_error_field: returns empty for missing field" {
  envelope='{"class":"fatal","code":"auth-failure","message":"bad key"}'
  result=$(agent_error_field "$envelope" "retryable_after")
  [ -z "$result" ]
}
