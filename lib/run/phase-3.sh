#!/bin/bash
# lib/run/phase-3.sh — Scripted test runner with Ralph Loop (ADR-008 PR-A)
#
# Extracted from pipeline.sh so the Phase 3 fix-retry loop is independently
# testable. The interface is run_phase3_tests(feat_id, wt_path) → exit code.
#
# Exit codes:
#   0  tests passed (happy path or after a fix)
#   1  unrecoverable error (e.g. claude CLI missing)
#   2  exhausted — feature paused, backlog continues
#
# Requires: lib/core/util.sh        (op_timeout)
#           lib/memory/learning.sh  (learning_read, learning_write, learning_verify_entry)
#           lib/core/feature-state.sh (fstate_transition, fstate_record_pause)
#           lib/core/platform.sh    (platform_claude)
# Calls _orchestrator_watcher_start/stop defined in pipeline.sh (looked up at runtime).

# run_phase3_tests <feat_id> <wt_path>
# ADR-008 PR-A: runs the stack-appropriate test command, invokes Claude on failure
# (up to max_fix_attempts), and integrates with the learning store on each attempt.
run_phase3_tests() {
  local feat_id="$1"
  local wt_path="$2"

  local fix_attempts=0
  echo "$fix_attempts" > "$STATE_DIR/$feat_id/phase3-fix-attempts"
  rm -f "$STATE_DIR/$feat_id/phase3-attempts.log"

  # Reuse stack profile already populated by run_feature (idempotent)
  stack_profile_init "$wt_path" 2>/dev/null || true
  local stack="${PROJECT_STACK:-unknown}"

  local test_cmd="${PROJECT_TEST_CMD:-}"
  if [ -z "$test_cmd" ]; then
    case "$stack" in
      ios)         test_cmd="swift test" ;;
      nodejs|node) test_cmd="jest" ;;
      rust)        test_cmd="cargo test" ;;
      python)      test_cmd="pytest" ;;
      go)          test_cmd="go test ./..." ;;
      *)
        info "Phase 3: unknown stack — skipping scripted tests"
        return 0
        ;;
    esac
  fi

  info "Phase 3: running tests ($stack): $test_cmd"

  local test_exit=0
  local tmp_out="/tmp/phase3-test-output-$$.txt"
  (cd "$wt_path" && eval "$test_cmd" >"$tmp_out" 2>&1) || test_exit=$?

  if [ "$test_exit" -eq 0 ]; then
    info "Phase 3: tests passed"
    rm -f "$tmp_out"
    return 0
  fi

  local test_output
  test_output=$(cat "$tmp_out" 2>/dev/null || echo "test output unavailable")
  rm -f "$tmp_out"

  local max_fix_attempts=2
  if [ "$AUTONOMY" = "full_auto" ]; then
    max_fix_attempts="${CFG_PHASE3_FULL_AUTO_MAX_FIX_ATTEMPTS:-5}"
    info "Phase 3: Ralph Loop active — up to $max_fix_attempts fix attempts (full_auto)"
  fi

  local trail_file="$STATE_DIR/$feat_id/phase3-attempts.log"

  while [ "$fix_attempts" -lt "$max_fix_attempts" ]; do
    fix_attempts=$((fix_attempts + 1))
    echo "$fix_attempts" > "$STATE_DIR/$feat_id/phase3-fix-attempts"
    info "Phase 3: fix attempt $fix_attempts/$max_fix_attempts"

    local error_sig
    error_sig=$(echo "$test_output" | head -5 | tr '\n' ' ' | sed 's/  */ /g')

    local learned_fix used_learn_id=""
    learned_fix=$(learning_read "$feat_id" "$error_sig")

    local fix_prompt="Fix the failing tests. Test output:\n$test_output"
    if [ "$fix_attempts" -gt 1 ] && [ -f "$trail_file" ]; then
      local trail_content
      trail_content=$(tail -c 2000 "$trail_file")
      fix_prompt="Previous fix attempts for context:\n$trail_content\n\nCurrent failing tests:\n$test_output"
    fi

    if [ -n "$learned_fix" ] && [ "$learned_fix" != "null" ]; then
      local hint
      hint=$(echo "$learned_fix" | python3 -c "import json,sys; d=json.load(sys.stdin); print(d.get('fix',''))" 2>/dev/null || echo "")
      used_learn_id=$(echo "$learned_fix" | python3 -c "import json,sys; d=json.load(sys.stdin); print(d.get('id',''))" 2>/dev/null || echo "")
      if [ -n "$hint" ]; then
        info "Phase 3: applying learned fix hint (id: $used_learn_id)"
        fix_prompt="$fix_prompt\n\nKnown fix hint: $hint"
      fi
    fi

    local model_flag=""
    local _fix_model="${MODEL_DEFAULT:-}"
    [ "$_fix_model" = "opusplan" ] && _fix_model="opus"
    [ -n "$_fix_model" ] && model_flag="--model $_fix_model"

    local fix_perm_flag=""
    [ "$AUTONOMY" = "full_auto" ] && fix_perm_flag="--permission-mode bypassPermissions"

    local fix_exit=0
    if declare -f _orchestrator_watcher_start &>/dev/null && [ "$AUTONOMY" = "full_auto" ]; then
      _orchestrator_watcher_start \
        "$STATE_DIR/$feat_id/.fix-watcher-active" \
        "$wt_path" \
        "${PROGRESS_INTERVAL:-45}" \
        "$feat_id"
    fi

    (cd "$wt_path" && printf '%b' "$fix_prompt" | \
      platform_claude "${SKILL_TIMEOUT_SECONDS:-1800}" $model_flag $fix_perm_flag --print) \
      2>/dev/null || fix_exit=$?

    if declare -f _orchestrator_watcher_stop &>/dev/null; then
      _orchestrator_watcher_stop "$STATE_DIR/$feat_id/.fix-watcher-active"
    fi

    # ADR-011 PR-E: verify build compiles after each fix attempt
    if [ -f "${SCRIPTS_DIR}/verify_build.sh" ]; then
      local _build_exit=0
      bash "${SCRIPTS_DIR}/verify_build.sh" "$wt_path" 2>/dev/null || _build_exit=$?
      if [ "$_build_exit" -eq 1 ]; then
        info "Phase 3: build broken after fix attempt $fix_attempts — continuing"
        test_exit=1
        continue
      fi
    fi

    # Re-run tests
    test_exit=0
    (cd "$wt_path" && eval "$test_cmd" >"$tmp_out" 2>&1) || test_exit=$?

    if [ "$test_exit" -eq 0 ]; then
      info "Phase 3: tests passed after fix attempt $fix_attempts"

      [ -n "$used_learn_id" ] && learning_verify_entry "$used_learn_id" "true"

      local fix_description
      fix_description=$(printf '%b' "$fix_prompt" | head -3 | tr '\n' ' ')
      learning_write "$feat_id" "$error_sig" "$fix_description"

      # Verify the newly written entry to initialise its success count
      local project_path
      project_path="$ROOT_DIR/.claude/feature-state/learned.json"
      if [ -f "$project_path" ]; then
        local learn_id
        local _sig_js
        _sig_js=$(node -p "JSON.stringify('$error_sig')" 2>/dev/null || echo "''")
        learn_id=$(node -p "
          try {
            const entries = JSON.parse(require('fs').readFileSync('$project_path','utf-8'));
            const m = entries.find(e => !e.archived && e.pattern === ${_sig_js});
            m ? m.id : '';
          } catch(e) { ''; }
        " 2>/dev/null || echo "")
        [ -n "$learn_id" ] && learning_verify_entry "$learn_id" "true"
      fi

      rm -f "$tmp_out"
      return 0
    fi

    local prev_output="$test_output"
    test_output=$(cat "$tmp_out" 2>/dev/null || echo "test output unavailable")
    rm -f "$tmp_out"

    [ -n "$used_learn_id" ] && learning_verify_entry "$used_learn_id" "false"

    local fix_desc_short post_error_sig
    fix_desc_short=$(printf '%b' "$fix_prompt" | head -1 | cut -c1-120)
    post_error_sig=$(echo "$test_output" | head -3 | tr '\n' ' ' | sed 's/  */ /g')
    learning_write "$feat_id" "$error_sig" "FAILED[attempt $fix_attempts]: $fix_desc_short | result: $post_error_sig"

    {
      echo "=== Attempt $fix_attempts/$max_fix_attempts ==="
      echo "Error: $error_sig"
      echo "Fix tried: $fix_desc_short"
      echo "Result: $post_error_sig"
      echo ""
    } >> "$trail_file"

    if [ "$(wc -l < "$trail_file" 2>/dev/null || echo 0)" -gt 60 ]; then
      tail -60 "$trail_file" > "${trail_file}.tmp" && mv "${trail_file}.tmp" "$trail_file"
    fi

    mem_record_error "$feat_id" "phase3" "fix attempt $fix_attempts failed: $test_cmd"
  done

  err "Phase 3: tests still failing after $max_fix_attempts fix attempts — pausing $feat_id"
  fstate_transition "$feat_id" "paused" "phase3-exhausted"
  fstate_record_pause "$feat_id" "human" "phase3-exhausted"

  local last_error_sig
  last_error_sig=$(echo "$test_output" | head -5 | tr '\n' ' ' | sed 's/  */ /g')
  node - "$feat_id" "$fix_attempts" "$trail_file" \
       "$STATE_DIR/$feat_id/pause-reason.json" <<JSEOF 2>/dev/null || true
const [,, feat_id, attempts, trail_path, out_path] = process.argv;
const fs = require('fs');
fs.writeFileSync(out_path, JSON.stringify({
  reason: 'phase3-exhausted',
  attempts: parseInt(attempts, 10),
  last_error_sig: $(node -p "JSON.stringify('$last_error_sig')" 2>/dev/null || echo '""'),
  trail_path,
  paused_at: new Date().toISOString()
}, null, 2));
JSEOF

  if declare -f display_paused_handoff &>/dev/null; then
    display_paused_handoff "$feat_id" "$fix_attempts" "$STATE_DIR/$feat_id/pause-reason.json"
  fi
  return 2
}
