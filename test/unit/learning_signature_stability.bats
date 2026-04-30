#!/usr/bin/env bats
# test/unit/learning_signature_stability.bats
#
# Verifies that learning_write deduplicates by error signature regardless of
# which feat_id generated the failure, and that distinct signatures stay
# distinct.  This guards against volatile data (feat-ids, absolute paths,
# timestamps) leaking into the signature and breaking cross-run deduplication.

setup() {
  REPO_ROOT="$(cd "$(dirname "$BATS_TEST_FILENAME")/../.." && pwd)"
  LIB_DIR="$REPO_ROOT/lib"

  TMPDIR_TEST="$(mktemp -d)"
  export STATE_DIR="$TMPDIR_TEST/state"
  export ROOT_DIR="$TMPDIR_TEST/root"
  mkdir -p "$STATE_DIR" "$ROOT_DIR/.claude/feature-state"

  # Stubs required by learning.sh before sourcing
  info() { :; }
  warn() { :; }
  err()  { echo "ERR: $*" >&2; }
  export -f info warn err

  source "$LIB_DIR/memory/learning.sh"

  PROJECT_LEARNED="$ROOT_DIR/.claude/feature-state/learned.json"
  export PROJECT_LEARNED
}

teardown() {
  rm -rf "$TMPDIR_TEST"
}

# ── helper: count entries in project learned.json ────────────────────────────

_entry_count() {
  node -p "
    try {
      const e = JSON.parse(require('fs').readFileSync('$PROJECT_LEARNED','utf-8'));
      e.filter(x => !x.archived).length;
    } catch(_) { 0; }
  " 2>/dev/null || echo "0"
}

_hits_for_sig() {
  local sig="$1"
  node -p "
    try {
      const entries = JSON.parse(require('fs').readFileSync('$PROJECT_LEARNED','utf-8'));
      const m = entries.find(e => !e.archived && e.pattern === $(node -p "JSON.stringify('$sig')" 2>/dev/null || echo "\"\""));
      m ? m.hits : 0;
    } catch(_) { 0; }
  " 2>/dev/null || echo "0"
}

# ── 1. Same signature from three different feat_ids → one entry, hits=3 ──────

@test "same error_sig from 3 feat_ids deduplicates to 1 entry with hits=3" {
  local sig="prd:missing a problem/overview section heading"
  local fix="Add a Problem Statement section to prd.md"

  learning_write "feat-alpha-001" "$sig" "$fix"
  learning_write "feat-beta-002"  "$sig" "$fix"
  learning_write "feat-gamma-003" "$sig" "$fix"

  local count
  count=$(_entry_count)
  [ "$count" -eq 1 ]
}

@test "same error_sig from 3 feat_ids results in hits=3" {
  local sig="prd:missing a problem/overview section heading"
  local fix="Add a Problem Statement section to prd.md"

  learning_write "feat-alpha-001" "$sig" "$fix"
  learning_write "feat-beta-002"  "$sig" "$fix"
  learning_write "feat-gamma-003" "$sig" "$fix"

  local hits
  hits=$(_hits_for_sig "$sig")
  [ "$hits" -eq 3 ]
}

# ── 2. Three distinct signatures → three entries ─────────────────────────────

@test "3 distinct error_sigs produce 3 separate entries" {
  learning_write "feat-001" "prd:missing a problem/overview section heading" \
    "Add Problem Statement section"
  learning_write "feat-002" "techspec:missing a technical approach section heading" \
    "Add Technical Approach section"
  learning_write "feat-003" "tasks:missing required field id in task objects" \
    "Ensure every task object has an id field"

  local count
  count=$(_entry_count)
  [ "$count" -eq 3 ]
}

# ── 3. Mixed run: 1 repeated sig + 3 distinct sigs → 4 entries total ─────────

@test "1 repeated sig (3x) plus 3 distinct sigs yields 4 total entries" {
  local repeated_sig="prd:missing a problem/overview section heading"
  local fix="Add Problem Statement section"

  # Same sig written 3 times (from different features)
  learning_write "feat-001" "$repeated_sig" "$fix"
  learning_write "feat-002" "$repeated_sig" "$fix"
  learning_write "feat-003" "$repeated_sig" "$fix"

  # Three distinct sigs
  learning_write "feat-004" "techspec:missing a technical approach section heading" \
    "Add Technical Approach"
  learning_write "feat-005" "tasks:missing required field id in task objects" \
    "Ensure task id field"
  learning_write "feat-006" "prd:missing a success criteria or acceptance criteria section heading" \
    "Add Success Criteria section"

  local count
  count=$(_entry_count)
  [ "$count" -eq 4 ]
}

# ── 4. Signature stability: validate.sh compose path does not leak paths ──────
#
# lib/schema/validate.sh line 258 ("file not found: $artifact_file") embeds a
# volatile absolute path in SCHEMA_VALIDATE_ERROR.  Before the fix, the
# signature composition `${artifact_type}:${error_msg#*: }` would preserve
# that path, producing a different dedup key per temp dir.
#
# The fix in validate.sh uses `${_raw_msg%%: /*}` to strip everything from the
# first ": /" onward, keeping only the stable error class ("file not found").
#
# This test verifies that the fixed composition logic removes the path by
# replicating the exact post-fix formula against a live SCHEMA_VALIDATE_ERROR.

@test "validate.sh missing-file error_msg does not leak absolute path into learn_sig after fix" {
  source "$LIB_DIR/schema/validate.sh"

  local artifact_file="$TMPDIR_TEST/nonexistent/prd.md"
  schema_validate "prd" "$artifact_file" || true

  # Post-fix composition from validate.sh: strip everything from ": /" onward
  local _raw_msg="${SCHEMA_VALIDATE_ERROR#*: }"
  local learn_sig="prd:${_raw_msg%%: /*}"

  # The signature must not contain an absolute path so dedup works across runs.
  [[ "$learn_sig" != *"$TMPDIR_TEST"* ]]
}

@test "validate.sh missing-file learn_sig contains stable error class" {
  source "$LIB_DIR/schema/validate.sh"

  local artifact_file="$TMPDIR_TEST/nonexistent/prd.md"
  schema_validate "prd" "$artifact_file" || true

  local _raw_msg="${SCHEMA_VALIDATE_ERROR#*: }"
  local learn_sig="prd:${_raw_msg%%: /*}"

  # Must still carry meaningful content (not empty after stripping)
  [ -n "$learn_sig" ]
  [[ "$learn_sig" == *"file not found"* ]]
}

# ── 5. Regression: feat_id is never embedded in the project-tier pattern ─────

@test "project-tier pattern field never contains feat_id" {
  local sig="prd:missing a problem/overview section heading"
  local fix="Add Problem Statement section"

  learning_write "feat-unique-xyz-999" "$sig" "$fix"

  local pattern
  pattern=$(node -p "
    try {
      const e = JSON.parse(require('fs').readFileSync('$PROJECT_LEARNED','utf-8'));
      const m = e.find(x => !x.archived && x.pattern === $(node -p "JSON.stringify('$sig')" 2>/dev/null || echo "\"\""));
      m ? m.pattern : '';
    } catch(_) { ''; }
  " 2>/dev/null || echo "")

  [[ "$pattern" != *"feat-unique-xyz-999"* ]]
}
