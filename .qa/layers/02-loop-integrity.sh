#!/bin/bash
# .qa/layers/02-loop-integrity.sh — Layer 2: Loop integrity
#
# Validates the full orchestration loop with a phase-aware mock agent:
#   2a. Adapter conformance: markdown adapter parses fixture → correct JSON shape
#   2b. Syntax check: github.js and linear.js are valid Node modules
#   2c. Full loop run: monozukuri run (full_auto, no-ui) with mock on PATH
#   2d. JSONL event assertions: run.started, feature.started, memory.bootstrap,
#       skill.invoked, skill.completed present in captured output
#   2e. State assertions: feature transitions to "done", logs are non-empty
#   2f. Worktree cleanup: .worktrees/feat-qa-001 removed after auto_cleanup
#
# Catches: MONOZUKURI_MEMORY_DIR crash, broken phase wiring, adapter regressions,
# worktree leaks.

set -euo pipefail

QA_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
REPO_ROOT="$(cd "$QA_DIR/.." && pwd)"
source "$QA_DIR/lib/assert.sh"

# ── helpers ───────────────────────────────────────────────────────────────────

_l2_jsonl_has_event() {
  local file="$1" event_type="$2"
  grep -q "\"type\":\"${event_type}\"" "$file" 2>/dev/null
}

_l2_feature_status() {
  local state_dir="$1" feat_id="$2"
  local status_file="$state_dir/$feat_id/status.json"
  [ -f "$status_file" ] || { echo "none"; return; }
  node -p "JSON.parse(require('fs').readFileSync('$status_file','utf-8')).status" 2>/dev/null || echo "unknown"
}

# ── 2a. Markdown adapter conformance ─────────────────────────────────────────

_layer2_adapter_conformance() {
  local failures=0
  local adapter_script="$REPO_ROOT/lib/plan/adapters/markdown.js"
  local fixture_backlog="$QA_DIR/fixtures/backlogs/markdown.md"

  assert_file_exists "markdown adapter exists" "$adapter_script" || return 1
  assert_file_exists "markdown fixture backlog exists" "$fixture_backlog" || return 1

  local tmp_dir
  tmp_dir=$(mktemp -d)
  cp "$fixture_backlog" "$tmp_dir/features.md"

  node "$adapter_script" "$tmp_dir/features.md" 2>/dev/null || {
    _qa_fail "markdown adapter exited non-zero" || failures=$((failures + 1))
    rm -rf "$tmp_dir"
    return "$failures"
  }

  local backlog_json="$tmp_dir/orchestration-backlog.json"
  assert_file_nonempty "markdown adapter produced orchestration-backlog.json" "$backlog_json" \
    || { failures=$((failures + 1)); rm -rf "$tmp_dir"; return "$failures"; }

  local count
  count=$(node -p "
    const d = JSON.parse(require('fs').readFileSync('$backlog_json','utf-8'));
    if (!Array.isArray(d)) throw new Error('not array');
    d.length
  " 2>/dev/null) || {
    _qa_fail "markdown adapter output is not a JSON array" || failures=$((failures + 1))
    rm -rf "$tmp_dir"
    return "$failures"
  }

  assert_eq "markdown adapter parses 2 features" "2" "$count" \
    || failures=$((failures + 1))

  local feat_id feat_status feat_source feat_deps
  feat_id=$(node -p "JSON.parse(require('fs').readFileSync('$backlog_json','utf-8'))[0].id" 2>/dev/null || echo "")
  feat_status=$(node -p "JSON.parse(require('fs').readFileSync('$backlog_json','utf-8'))[0].status" 2>/dev/null || echo "")
  feat_source=$(node -p "JSON.parse(require('fs').readFileSync('$backlog_json','utf-8'))[0].source" 2>/dev/null || echo "")

  assert_eq "feature[0].id == feat-qa-001" "feat-qa-001" "$feat_id" \
    || failures=$((failures + 1))
  assert_eq "feature[0].status == backlog" "backlog" "$feat_status" \
    || failures=$((failures + 1))
  assert_eq "feature[0].source == markdown" "markdown" "$feat_source" \
    || failures=$((failures + 1))

  feat_deps=$(node -p "JSON.parse(require('fs').readFileSync('$backlog_json','utf-8'))[1].dependencies.join(',')" 2>/dev/null || echo "")
  assert_eq "feature[1].dependencies includes feat-qa-001" "feat-qa-001" "$feat_deps" \
    || failures=$((failures + 1))

  rm -rf "$tmp_dir"
  return "$failures"
}

# ── 2b. Adapter syntax checks ─────────────────────────────────────────────────

_layer2_adapter_syntax() {
  local failures=0

  for adapter in github linear; do
    local script="$REPO_ROOT/lib/plan/adapters/${adapter}.js"
    assert_file_exists "${adapter} adapter file exists" "$script" \
      || { failures=$((failures + 1)); continue; }
    node --check "$script" 2>/dev/null \
      && _qa_pass "${adapter}.js passes Node syntax check" \
      || { _qa_fail "${adapter}.js has Node syntax errors" || failures=$((failures + 1)); }
  done

  return "$failures"
}

# ── 2c–2f. Full loop run ─────────────────────────────────────────────────────

_layer2_loop_run() {
  local failures=0
  local mock_dir="$QA_DIR/fixtures/mocks/claude"
  local fixture_src="$QA_DIR/fixtures/project"

  assert_file_exists "mock claude binary exists" "$mock_dir/claude" \
    || return 1

  # Seed a fresh temp project (copy fixture, then git-init so wt_create works)
  local tmp_proj
  tmp_proj=$(mktemp -d)
  cp -r "$fixture_src/." "$tmp_proj/"

  git -C "$tmp_proj" init -b main -q 2>/dev/null \
    || git -C "$tmp_proj" init -q 2>/dev/null || true
  git -C "$tmp_proj" -c user.email="qa@test.local" -c user.name="QA Gate" add -A 2>/dev/null
  git -C "$tmp_proj" -c user.email="qa@test.local" -c user.name="QA Gate" \
    commit -q -m "init" 2>/dev/null || true

  local run_output="$tmp_proj/.qa-run-output.txt"
  local run_exit=0

  (
    cd "$tmp_proj"
    PATH="$mock_dir:$PATH" \
      node "$REPO_ROOT/bin/monozukuri" run --autonomy full_auto
  ) > "$run_output" 2>&1 || run_exit=$?

  # 2c. Exit code assertion
  if [ "$run_exit" -eq 0 ]; then
    _qa_pass "monozukuri run exited 0 with mock agent"
  else
    _qa_fail "monozukuri run failed (exit $run_exit) — see output below" \
      || failures=$((failures + 1))
    printf '  [run output (last 40 lines)]\n'
    tail -40 "$run_output" | sed 's/^/    /'
    rm -rf "$tmp_proj"
    return "$failures"
  fi

  # 2d. JSONL event assertions (emitted via monozukuri_emit when MONOZUKURI_RUN_ID is set)
  for event in "run.started" "feature.started" "memory.bootstrap" "skill.invoked" "skill.completed"; do
    if _l2_jsonl_has_event "$run_output" "$event"; then
      _qa_pass "JSONL event present: $event"
    else
      _qa_fail "JSONL event missing: $event" || failures=$((failures + 1))
    fi
  done

  # 2e. Feature state: status.json must record "done" after pr_strategy=none run
  local state_dir="$tmp_proj/.monozukuri/state"
  local final_status
  final_status=$(_l2_feature_status "$state_dir" "feat-qa-001")
  assert_eq "feat-qa-001 reached status done" "done" "$final_status" \
    || failures=$((failures + 1))

  local log_count
  log_count=$(find "$state_dir/feat-qa-001/logs" -name "*.log" 2>/dev/null | wc -l | tr -d ' ')
  if [ "$log_count" -gt 0 ]; then
    _qa_pass "run log captured in state/feat-qa-001/logs/ (${log_count} file(s))"
  else
    _qa_fail "no run log in state/feat-qa-001/logs/" || failures=$((failures + 1))
  fi

  # 2f. Worktree cleanup: auto_cleanup=true → .worktrees/feat-qa-001 removed
  if [ ! -d "$tmp_proj/.worktrees/feat-qa-001" ]; then
    _qa_pass "worktree .worktrees/feat-qa-001 cleaned up (auto_cleanup=true)"
  else
    _qa_fail "worktree .worktrees/feat-qa-001 still present — wt_cleanup broken" \
      || failures=$((failures + 1))
  fi

  rm -rf "$tmp_proj"
  return "$failures"
}

# ── entry point ───────────────────────────────────────────────────────────────

run_layer2() {
  local failures=0

  echo "Layer 2: Loop integrity"

  _layer2_adapter_conformance || failures=$((failures + 1))
  _layer2_adapter_syntax       || failures=$((failures + 1))
  _layer2_loop_run             || failures=$((failures + 1))

  return "$failures"
}
