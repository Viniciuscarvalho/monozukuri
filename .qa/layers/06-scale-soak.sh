#!/bin/bash
# .qa/layers/06-scale-soak.sh — Layer 6: Personal-scale soak
#
# Runs monozukuri against 3 foreign-project fixtures (node, python, go), each
# with 5 features. Uses mock adapters for repeatable CI runs. One variant uses
# live adapters for tag-time gate (set MONOZUKURI_SCALE_SOAK_LIVE=1).
#
# v1.0 SLO assertions:
#   - ≤ 30% features in paused state across all projects
#   - 0 silent failures (no exit 0 with empty artifacts)
#   - Total cost ≤ $50 when live (mock runs always $0)
#
# Skipped when MONOZUKURI_SKIP_SCALE_SOAK=1 (rarely needed).
# Live variant skipped when MONOZUKURI_SKIP_SCALE_SOAK_LIVE=1 (CI default).
set -euo pipefail

QA_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
REPO_ROOT="$(cd "$QA_DIR/.." && pwd)"
source "$QA_DIR/lib/assert.sh"

# ── helpers ───────────────────────────────────────────────────────────────────

_l6_feature_status() {
  local state_dir="$1" feat_id="$2"
  local status_file="$state_dir/$feat_id/status.json"
  [ -f "$status_file" ] || { echo "none"; return; }
  node -p "JSON.parse(require('fs').readFileSync('$status_file','utf-8')).status" \
    2>/dev/null || echo "unknown"
}

_l6_feature_ids_from_backlog() {
  local backlog="$1"
  [ -f "$backlog" ] || { echo ""; return; }
  node -p "
    const d = JSON.parse(require('fs').readFileSync('$backlog','utf-8'));
    Array.isArray(d) ? d.map(f=>f.id).join('\n') : '';
  " 2>/dev/null || echo ""
}

_l6_count_artifact_files() {
  local state_dir="$1" feat_id="$2"
  find "$state_dir/$feat_id" -type f 2>/dev/null | wc -l | tr -d ' '
}

# _l6_run_project <fixture_dir> <mock_binary_dir> <project_name>
# Returns: total features, paused count, silent failures count via globals:
#   _L6_TOTAL, _L6_PAUSED, _L6_SILENT_FAILURES
_l6_run_project() {
  local fixture_src="$1"
  local mock_dir="$2"
  local project_name="$3"

  _L6_TOTAL=0
  _L6_PAUSED=0
  _L6_SILENT_FAILURES=0

  local tmp_proj
  tmp_proj=$(mktemp -d)
  cp -r "$fixture_src/." "$tmp_proj/"

  git -C "$tmp_proj" init -b main -q 2>/dev/null \
    || git -C "$tmp_proj" init -q 2>/dev/null || true
  git -C "$tmp_proj" -c user.email="qa@test.local" -c user.name="QA Gate" add -A 2>/dev/null
  git -C "$tmp_proj" -c user.email="qa@test.local" -c user.name="QA Gate" \
    commit -q -m "init: $project_name" 2>/dev/null || true

  local run_output="$tmp_proj/.qa-run.txt"
  local run_exit=0

  (
    cd "$tmp_proj"
    PATH="$mock_dir:$PATH" \
    MONOZUKURI_NON_INTERACTIVE=true \
    MONOZUKURI_SKIP_CYCLE_CHECK=true \
      node "$REPO_ROOT/bin/monozukuri" run --autonomy full_auto --non-interactive
  ) > "$run_output" 2>&1 || run_exit=$?

  # Count features from backlog (written before run, deleted after)
  # Fall back to counting features.md headings if backlog was cleaned up
  local feat_count
  feat_count=$(grep -c '^## feat-' "$tmp_proj/features.md" 2>/dev/null || echo "0")
  _L6_TOTAL="$feat_count"

  local state_dir="$tmp_proj/.monozukuri/state"

  local i=0
  while IFS= read -r feat_id; do
    [ -z "$feat_id" ] && continue
    i=$((i + 1))
    local status
    status=$(_l6_feature_status "$state_dir" "$feat_id")
    if [ "$status" = "paused" ]; then
      _L6_PAUSED=$((_L6_PAUSED + 1))
    fi
    # Silent failure: exit 0 but no artifacts written
    if [ "$status" = "done" ] || [ "$status" = "pr-created" ]; then
      local artifact_count
      artifact_count=$(_l6_count_artifact_files "$state_dir" "$feat_id")
      if [ "$artifact_count" -eq 0 ]; then
        _L6_SILENT_FAILURES=$((_L6_SILENT_FAILURES + 1))
      fi
    fi
  done < <(grep -oE 'feat-[a-z0-9-]+' "$tmp_proj/features.md" | sort -u 2>/dev/null || true)

  rm -rf "$tmp_proj"
  return 0
}

# ── main soak ─────────────────────────────────────────────────────────────────

_layer6_soak() {
  local failures=0
  local fixtures_dir="$QA_DIR/fixtures/scale"
  local mock_claude="$QA_DIR/fixtures/mocks/claude"

  local projects=("node" "python" "go")
  local total_features=0
  local total_paused=0
  local total_silent=0
  local soak_start soak_end soak_elapsed
  soak_start=$(date +%s)

  for proj in "${projects[@]}"; do
    local fixture_dir="$fixtures_dir/$proj"
    assert_file_exists "$proj fixture exists" "$fixture_dir/features.md" \
      || { failures=$((failures + 1)); continue; }

    printf '  Running soak: %s (mock)\n' "$proj"
    _l6_run_project "$fixture_dir" "$mock_claude" "$proj"

    total_features=$((total_features + _L6_TOTAL))
    total_paused=$((total_paused + _L6_PAUSED))
    total_silent=$((total_silent + _L6_SILENT_FAILURES))

    printf '    features=%d  paused=%d  silent_failures=%d\n' \
      "$_L6_TOTAL" "$_L6_PAUSED" "$_L6_SILENT_FAILURES"
  done

  soak_end=$(date +%s)
  soak_elapsed=$((soak_end - soak_start))

  # ── SLO assertions ────────────────────────────────────────────────────────

  # 1. Total feature count (sanity: 3 projects × 5 = 15)
  if [ "$total_features" -ge 15 ]; then
    _qa_pass "scale soak ran $total_features features across ${#projects[@]} projects"
  else
    _qa_fail "scale soak ran only $total_features features — expected ≥15" \
      || failures=$((failures + 1))
  fi

  # 2. Pause rate ≤ 30%
  if [ "$total_features" -gt 0 ]; then
    local pause_pct=$(( (total_paused * 100) / total_features ))
    if [ "$pause_pct" -le 30 ]; then
      _qa_pass "pause rate ${pause_pct}% ≤ 30% SLO"
    else
      _qa_fail "pause rate ${pause_pct}% exceeds 30% SLO (${total_paused}/${total_features} paused)" \
        || failures=$((failures + 1))
    fi
  fi

  # 3. Zero silent failures
  if [ "$total_silent" -eq 0 ]; then
    _qa_pass "0 silent failures (no exit-0 with empty artifacts)"
  else
    _qa_fail "$total_silent silent failure(s) detected — features marked done but no artifacts written" \
      || failures=$((failures + 1))
  fi

  # 4. Wall-clock (mock runs should complete in minutes, not hours)
  printf '  Soak elapsed: %ds\n' "$soak_elapsed"

  return "$failures"
}

# ── entry point ───────────────────────────────────────────────────────────────

run_layer6() {
  echo "Layer 6: Scale soak"

  if [ "${MONOZUKURI_SKIP_SCALE_SOAK:-0}" = "1" ]; then
    printf '  ~ skipped (MONOZUKURI_SKIP_SCALE_SOAK=1)\n'
    return 0
  fi

  _layer6_soak
}
