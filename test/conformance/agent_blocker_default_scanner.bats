#!/usr/bin/env bats
# test/conformance/agent_blocker_default_scanner.bats
#
# Conformance suite for agent_scan_for_blocker() in lib/agent/error.sh.
# Verifies the default scanner detects interactive-blocking patterns across
# the three canned log styles (codex, gemini, kiro) and does not produce
# false positives on normal output lines.

REPO_ROOT="$(cd "$(dirname "$BATS_TEST_FILENAME")/../.." && pwd)"
LIB_DIR="$REPO_ROOT/lib"

setup() {
  export REPO_ROOT LIB_DIR
  source "$LIB_DIR/agent/error.sh"

  TMPDIR_TEST="$(mktemp -d)"
  export TMPDIR_TEST
  LOG="$TMPDIR_TEST/agent.log"
  ERR="$TMPDIR_TEST/error.json"
  export LOG ERR
}

teardown() {
  rm -rf "$TMPDIR_TEST"
}

# ── helpers ───────────────────────────────────────────────────────────────────

_write_log() {
  printf '%s\n' "$@" > "$LOG"
}

_assert_blocker_detected() {
  local rc=0
  agent_scan_for_blocker "$LOG" "$ERR" || rc=$?
  [ "$rc" -eq 1 ]
}

_assert_no_blocker() {
  run agent_scan_for_blocker "$LOG" "$ERR"
  [ "$status" -eq 0 ]
}

_assert_human_envelope() {
  [ -f "$ERR" ]
  node -e "
    const d = JSON.parse(require('fs').readFileSync('$ERR', 'utf-8'));
    if (d.class !== 'human') process.exit(1);
    if (d.code !== 'agent-blocker') process.exit(1);
  "
}

# ── canonical blocker patterns ────────────────────────────────────────────────

@test "scanner: detects 'Blocker — Need Your Input' pattern" {
  _write_log "## Blocker — Need Your Input" "Please clarify the target branch."
  _assert_blocker_detected
}

@test "scanner: detects 'Blocker - Need' dash variant" {
  _write_log "Blocker - Need clarification before continuing."
  _assert_blocker_detected
}

@test "scanner: detects 'Need Your Input' standalone phrase" {
  _write_log "Need Your Input: which database should I use?"
  _assert_blocker_detected
}

@test "scanner: detects 'human intervention required' phrase" {
  _write_log "This situation requires human intervention required to proceed."
  _assert_blocker_detected
}

@test "scanner: detects 'Blocker — Wait for' pattern" {
  _write_log "Blocker — Wait for operator confirmation before deploying."
  _assert_blocker_detected
}

@test "scanner: detects 'Blocker — Require' variant" {
  _write_log "Blocker — Require your review of the schema change."
  _assert_blocker_detected
}

# ── blocker detection writes class:human envelope ─────────────────────────────

@test "scanner: writes class:human envelope when blocker found" {
  _write_log "Need Your Input: confirm the API endpoint."
  agent_scan_for_blocker "$LOG" "$ERR" || true
  _assert_human_envelope
}

# ── codex-style log ───────────────────────────────────────────────────────────

@test "scanner (codex log): detects blocker in codex-style prefix output" {
  _write_log \
    "[codex] Starting task execution" \
    "[codex] Reading repository structure" \
    "[codex] Blocker — Need Your Input: cannot determine base branch" \
    "[codex] Halting execution"
  _assert_blocker_detected
}

@test "scanner (codex log): clean output does not trigger blocker" {
  _write_log \
    "[codex] Starting task execution" \
    "[codex] Writing lib/api/handler.go" \
    "[codex] Running tests" \
    "[codex] All tests passed" \
    "[codex] Done."
  _assert_no_blocker
}

# ── gemini-style log ──────────────────────────────────────────────────────────

@test "scanner (gemini log): detects blocker in gemini-style JSON-wrapped output" {
  _write_log \
    '{"role":"model","text":"Analyzing codebase..."}' \
    '{"role":"model","text":"Need Your Input: the migration target is ambiguous."}' \
    '{"role":"model","text":"Pausing until resolved."}'
  _assert_blocker_detected
}

@test "scanner (gemini log): clean JSON output does not trigger blocker" {
  _write_log \
    '{"role":"model","text":"Analyzing codebase..."}' \
    '{"role":"model","text":"Writing src/index.ts"}' \
    '{"role":"model","text":"Task complete."}'
  _assert_no_blocker
}

# ── kiro-style log ────────────────────────────────────────────────────────────

@test "scanner (kiro log): detects blocker in kiro-style YAML event output" {
  _write_log \
    "event: agent.step" \
    "data: step=1 action=read_file file=README.md" \
    "event: agent.blocked" \
    "data: reason='Blocker — Need Your Input: spec file missing'"
  _assert_blocker_detected
}

@test "scanner (kiro log): clean YAML event output does not trigger blocker" {
  _write_log \
    "event: agent.step" \
    "data: step=1 action=read_file file=README.md" \
    "event: agent.step" \
    "data: step=2 action=write_file file=src/main.ts" \
    "event: agent.done" \
    "data: status=success"
  _assert_no_blocker
}

# ── normal output — must not trigger blocker ──────────────────────────────────

@test "scanner: progress line does not trigger blocker" {
  _write_log "[progress] 45s elapsed — Claude working (no new files in last 45s)"
  _assert_no_blocker
}

@test "scanner: test failure line does not trigger blocker" {
  _write_log "FAIL: test_user_authentication — expected 200 got 401"
  _assert_no_blocker
}

@test "scanner: error envelope line does not trigger blocker" {
  _write_log '{"class":"phase","code":"schema-invalid","message":"Output failed schema validation"}'
  _assert_no_blocker
}

@test "scanner: empty log does not trigger blocker" {
  printf '' > "$LOG"
  _assert_no_blocker
}

@test "scanner: missing log file does not trigger blocker" {
  rm -f "$LOG"
  _assert_no_blocker
}

# ── case-insensitivity ────────────────────────────────────────────────────────

@test "scanner: detects lowercase 'blocker — need your input'" {
  _write_log "blocker — need your input: clarify the target branch"
  _assert_blocker_detected
}

@test "scanner: detects uppercase 'NEED YOUR INPUT'" {
  _write_log "NEED YOUR INPUT: which region should the bucket be in?"
  _assert_blocker_detected
}
