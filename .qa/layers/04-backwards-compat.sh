#!/bin/bash
# .qa/layers/04-backwards-compat.sh — Layer 4: Backwards compatibility
#
# Validates that v1.19.x-era state is handled correctly by the current codebase:
#   4a. Learning store compat: v1.19.x learned.json (missing newer fields) is
#       readable by learning_read without crashing or returning garbage
#   4b. Resume compat: a paused feature with v1.19.x state (no pause.json)
#       resumes cleanly via --resume-paused and advances to "done"
#   4c. AGENTS.md promotion integrity: conventions promote writes the new
#       section without corrupting existing sections
#
# Catches: state-format breaks, learning-store reader breaks, AGENTS.md corruption.

set -euo pipefail

QA_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
REPO_ROOT="$(cd "$QA_DIR/.." && pwd)"
FIXTURES="$QA_DIR/fixtures/prev-version-state"
source "$QA_DIR/lib/assert.sh"

# ── helpers ───────────────────────────────────────────────────────────────────

_l4_feature_status() {
  local state_dir="$1" feat_id="$2"
  local status_file="$state_dir/$feat_id/status.json"
  [ -f "$status_file" ] || { echo "none"; return; }
  node -p "JSON.parse(require('fs').readFileSync('$status_file','utf-8')).status" 2>/dev/null || echo "unknown"
}

_l4_seed_project() {
  local src="$1" dst="$2"
  cp -r "$src/." "$dst/"
  git -C "$dst" init -b main -q 2>/dev/null \
    || git -C "$dst" init -q 2>/dev/null || true
  git -C "$dst" -c user.email="qa@test.local" -c user.name="QA Gate" add -A 2>/dev/null
  git -C "$dst" -c user.email="qa@test.local" -c user.name="QA Gate" \
    commit -q -m "init" 2>/dev/null || true
}

_l4_seed_paused_state() {
  local state_dir="$1" feat_id="$2"
  local feat_state="$state_dir/$feat_id"
  mkdir -p "$feat_state/logs"
  cp "$FIXTURES/status.json"     "$feat_state/status.json"
  cp "$FIXTURES/results.json"    "$feat_state/results.json"
  cp "$FIXTURES/learned.json"    "$feat_state/learned.json"
  cp "$FIXTURES/checkpoint.json" "$feat_state/checkpoint.json"
  # Intentionally omit pause.json — v1.19.x did not write this file.
  # Current code must default pause_kind to "transient" when it is absent.
  touch "$feat_state/logs/.keep"
}

# ── 4a. Learning store backwards compatibility ────────────────────────────────

_layer4_learning_compat() {
  local failures=0

  assert_file_exists "v1.19.x learned.json fixture exists" "$FIXTURES/learned.json" \
    || return 1

  local tmp_dir
  tmp_dir=$(mktemp -d)
  local state_dir="$tmp_dir/state"
  local root_dir="$tmp_dir/root"
  mkdir -p "$state_dir/feat-compat-001" "$root_dir/.claude/feature-state"

  cp "$FIXTURES/learned.json" "$state_dir/feat-compat-001/learned.json"
  # Project and global tiers are empty — only the feature tier has entries.
  echo '[]' > "$root_dir/.claude/feature-state/learned.json"

  # Source learning.sh with the temp state dirs wired in
  local read_result
  read_result=$(
    STATE_DIR="$state_dir" ROOT_DIR="$root_dir" \
    bash -c "
      source '$REPO_ROOT/lib/memory/learning.sh'
      learning_read 'feat-compat-001' 'ENOENT reading package.json in worktree'
    " 2>/dev/null
  ) || true

  if [ -n "$read_result" ]; then
    _qa_pass "learning_read returns v1.19.x entry without crashing"
  else
    _qa_fail "learning_read returned empty for v1.19.x learned.json entry" \
      || failures=$((failures + 1))
  fi

  # The returned entry should still expose the 'pattern' field correctly
  local got_pattern
  got_pattern=$(node -p "
    try {
      const e = JSON.parse('$read_result' || '{}');
      e.pattern || ''
    } catch(_) { '' }
  " 2>/dev/null || echo "")

  assert_not_empty "learning_read result contains pattern field" "$got_pattern" \
    || failures=$((failures + 1))

  rm -rf "$tmp_dir"
  return "$failures"
}

# ── 4b. Resume from v1.19.x paused state (no pause.json) ─────────────────────

_layer4_resume_compat() {
  local failures=0
  local mock_dir="$QA_DIR/fixtures/mocks/claude"
  local fixture_src="$QA_DIR/fixtures/compat-project"
  local feat_id="feat-compat-001"

  local tmp_proj
  tmp_proj=$(mktemp -d)
  _l4_seed_project "$fixture_src" "$tmp_proj"

  local state_dir="$tmp_proj/.monozukuri/state"
  mkdir -p "$state_dir"
  _l4_seed_paused_state "$state_dir" "$feat_id"

  local run_output="$tmp_proj/.qa-resume-output.txt"
  local run_exit=0

  (
    cd "$tmp_proj"
    PATH="$mock_dir:$PATH" \
      node "$REPO_ROOT/bin/monozukuri" --resume-paused "$feat_id"
  ) > "$run_output" 2>&1 || run_exit=$?

  if [ "$run_exit" -eq 0 ]; then
    _qa_pass "monozukuri --resume-paused exited 0 with v1.19.x state (no pause.json)"
  else
    _qa_fail "monozukuri --resume-paused failed (exit $run_exit) with v1.19.x state" \
      || failures=$((failures + 1))
    printf '  [resume output (last 30 lines)]\n'
    tail -30 "$run_output" | sed 's/^/    /'
    rm -rf "$tmp_proj"
    return "$failures"
  fi

  # Feature must have advanced to "done" (not still "paused")
  local final_status
  final_status=$(_l4_feature_status "$state_dir" "$feat_id")
  assert_eq "feat-compat-001 advanced to status done after resume" "done" "$final_status" \
    || failures=$((failures + 1))

  # Worktree cleaned up (auto_cleanup=true)
  if [ ! -d "$tmp_proj/.worktrees/$feat_id" ]; then
    _qa_pass "worktree cleaned up after resume run"
  else
    _qa_fail "worktree still present after resume (auto_cleanup may be broken)" \
      || failures=$((failures + 1))
  fi

  rm -rf "$tmp_proj"
  return "$failures"
}

# ── 4c. AGENTS.md promotion integrity ────────────────────────────────────────

_layer4_agents_md_promotion() {
  local failures=0
  local fixture_src="$QA_DIR/fixtures/compat-project"

  local tmp_proj
  tmp_proj=$(mktemp -d)
  _l4_seed_project "$fixture_src" "$tmp_proj"

  # Install the old-format AGENTS.md (no monozukuri marker block)
  cp "$FIXTURES/agents-md-old-format.md" "$tmp_proj/AGENTS.md"

  # Wire up the promotion candidate in the project learning tier
  local tier_dir="$tmp_proj/.claude/feature-state"
  mkdir -p "$tier_dir"
  cp "$FIXTURES/promo-candidate.json" "$tier_dir/learned.json"

  local run_output="$tmp_proj/.qa-promote-output.txt"
  local run_exit=0

  (
    cd "$tmp_proj"
    node "$REPO_ROOT/bin/monozukuri" conventions promote learn-promo-001
  ) > "$run_output" 2>&1 || run_exit=$?

  if [ "$run_exit" -eq 0 ]; then
    _qa_pass "conventions promote exited 0"
  else
    _qa_fail "conventions promote failed (exit $run_exit)" \
      || failures=$((failures + 1))
    printf '  [promote output]\n'
    tail -20 "$run_output" | sed 's/^/    /'
    rm -rf "$tmp_proj"
    return "$failures"
  fi

  local agents_md="$tmp_proj/AGENTS.md"
  assert_file_nonempty "AGENTS.md is non-empty after promotion" "$agents_md" \
    || { failures=$((failures + 1)); rm -rf "$tmp_proj"; return "$failures"; }

  # Original sections must still be present (no corruption)
  assert_grep "AGENTS.md preserves original section 'Use descriptive variable names'" \
    "Use descriptive variable names" "$agents_md" \
    || failures=$((failures + 1))
  assert_grep "AGENTS.md preserves original section 'Commit messages should explain why'" \
    "Commit messages should explain why" "$agents_md" \
    || failures=$((failures + 1))

  # The promoted section must be present
  assert_grep "AGENTS.md contains promoted pattern text" \
    "npm ci" "$agents_md" \
    || failures=$((failures + 1))

  rm -rf "$tmp_proj"
  return "$failures"
}

# ── entry point ───────────────────────────────────────────────────────────────

run_layer4() {
  local failures=0

  echo "Layer 4: Backwards compatibility"

  _layer4_learning_compat   || failures=$((failures + 1))
  _layer4_resume_compat     || failures=$((failures + 1))
  _layer4_agents_md_promotion || failures=$((failures + 1))

  return "$failures"
}
