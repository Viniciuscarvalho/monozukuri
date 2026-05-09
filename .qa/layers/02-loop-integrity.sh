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
  local adapter_script="$REPO_ROOT/lib/ingest/adapters/markdown.js"
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
    local script="$REPO_ROOT/lib/ingest/adapters/${adapter}.js"
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

# ── 2g–2j. Phase A1–A4 safety properties ─────────────────────────────────────
#
# A1: auth-expiry detection — _thin_shell_auth_check pattern match (codex + gemini adapters)
# A2: wall-clock cap — op_timeout actually kills a hung subprocess
# A3: divergent loop — phase3-loop-diverged fires before max_fix_attempts
# A4: non-1 build exit — ANY non-zero verify_build exit is treated as broken

_layer2_phase_a_safety() {
  local failures=0

  # ── 2g: auth-expiry pattern matching ────────────────────────────────────────

  # Source adapters in a subshell to avoid polluting layer state
  local codex_adapter="$REPO_ROOT/lib/agent/adapter-codex.sh"
  local gemini_adapter="$REPO_ROOT/lib/agent/adapter-gemini.sh"

  assert_file_exists "adapter-codex.sh exists" "$codex_adapter" \
    || { failures=$((failures + 1)); }
  assert_file_exists "adapter-gemini.sh exists" "$gemini_adapter" \
    || { failures=$((failures + 1)); }

  # codex: known auth-error strings must be detected
  local tmp_log
  tmp_log=$(mktemp)

  for marker in \
    "Please run codex login to authenticate" \
    "Not authenticated" \
    "Authentication required" \
    "invalid api key" \
    "session expired" \
    "please log in" \
    "token expired" \
    "Unauthorized"
  do
    printf '%s\n' "$marker" > "$tmp_log"
    if (source "$codex_adapter" 2>/dev/null; _thin_shell_auth_check "$tmp_log"); then
      _qa_pass "codex auth-expiry detected: $(printf '%s' "$marker" | head -c 40)"
    else
      _qa_fail "codex auth-expiry NOT detected: $marker" || failures=$((failures + 1))
    fi
  done

  # gemini: known auth-error strings must be detected
  for marker in \
    "OAuth token expired" \
    "unable to refresh credentials" \
    "authentication failed" \
    "invalid credentials" \
    "Please authenticate" \
    "token revoked" \
    "access denied" \
    "401"
  do
    printf '%s\n' "$marker" > "$tmp_log"
    if (source "$gemini_adapter" 2>/dev/null; _thin_shell_auth_check "$tmp_log"); then
      _qa_pass "gemini auth-expiry detected: $(printf '%s' "$marker" | head -c 40)"
    else
      _qa_fail "gemini auth-expiry NOT detected: $marker" || failures=$((failures + 1))
    fi
  done

  # benign text must NOT trigger auth-expiry (avoid false positive abort)
  printf '%s\n' "All tests passed. Feature complete." > "$tmp_log"
  if (source "$codex_adapter" 2>/dev/null; _thin_shell_auth_check "$tmp_log"); then
    _qa_fail "codex auth-expiry falsely triggered on benign output" \
      || failures=$((failures + 1))
  else
    _qa_pass "codex auth-expiry no false positive on benign output"
  fi

  rm -f "$tmp_log"

  # ── 2h: op_timeout actually kills a hung subprocess ─────────────────────────

  local util_sh="$REPO_ROOT/lib/core/util.sh"
  assert_file_exists "util.sh exists" "$util_sh" \
    || { failures=$((failures + 1)); }

  local t0 t1 elapsed hang_exit=0
  t0=$(date +%s)
  (
    # shellcheck source=../../lib/core/util.sh
    source "$util_sh"
    op_timeout 2 sleep 100
  ) || hang_exit=$?
  t1=$(date +%s)
  elapsed=$((t1 - t0))

  if [ "$elapsed" -le 5 ]; then
    _qa_pass "op_timeout killed hung process in ${elapsed}s (≤5s expected)"
  else
    _qa_fail "op_timeout took ${elapsed}s — too slow (≤5s expected)" \
      || failures=$((failures + 1))
  fi

  # exit code must be non-zero (timeout exit codes vary: 124 on GNU, SIGKILL on perl)
  if [ "$hang_exit" -ne 0 ]; then
    _qa_pass "op_timeout returned non-zero exit ($hang_exit) for killed process"
  else
    _qa_fail "op_timeout returned 0 for a killed process — timeout may not have fired" \
      || failures=$((failures + 1))
  fi

  # ── 2i: auth-expired adapter exits 15 (adapter integration) ─────────────────
  #
  # Run agent_run_phase from the codex adapter with the hang-mock on PATH,
  # but in auth-expired mode — expect exit 15.

  local mock_codex_dir="$QA_DIR/fixtures/mocks/codex"
  assert_file_exists "mock codex binary exists" "$mock_codex_dir/codex" \
    || { failures=$((failures + 1)); }

  local wt
  wt=$(mktemp -d)
  git -C "$wt" init -q 2>/dev/null || true

  local auth_exit=0
  (
    export PATH="$mock_codex_dir:$PATH"
    export MONOZUKURI_FEATURE_ID="feat-qa-auth-test"
    export MONOZUKURI_WORKTREE="$wt"
    export MONOZUKURI_AUTONOMY="full_auto"
    export MONOZUKURI_PHASE="prd"
    export MONOZUKURI_LOG_FILE="/tmp/qa-codex-auth-$$.log"
    export MOCK_CODEX_MODE="auth-expired"
    source "$REPO_ROOT/lib/core/util.sh"
    source "$codex_adapter"
    render_phase_prompt() { echo "Implement feature ${MONOZUKURI_FEATURE_ID}."; }
    agent_run_phase
  ) || auth_exit=$?
  rm -rf "$wt"

  assert_eq "codex auth-expired exits 15" "15" "$auth_exit" \
    || failures=$((failures + 1))

  # ── 2j: wall-clock cap via op_timeout in adapter (hang mode) ─────────────────

  local mock_gemini_dir="$QA_DIR/fixtures/mocks/gemini"
  assert_file_exists "mock gemini binary exists" "$mock_gemini_dir/gemini" \
    || { failures=$((failures + 1)); }

  local wt2
  wt2=$(mktemp -d)
  git -C "$wt2" init -q 2>/dev/null || true

  local t2 t3 cap_elapsed cap_exit=0
  t2=$(date +%s)
  (
    export PATH="$mock_gemini_dir:$PATH"
    export MONOZUKURI_FEATURE_ID="feat-qa-cap-test"
    export MONOZUKURI_WORKTREE="$wt2"
    export MONOZUKURI_AUTONOMY="full_auto"
    export MONOZUKURI_PHASE="prd"
    export MONOZUKURI_LOG_FILE="/tmp/qa-gemini-cap-$$.log"
    export MOCK_GEMINI_MODE="hang"
    export SKILL_TIMEOUT_SECONDS=2
    source "$REPO_ROOT/lib/core/util.sh"
    source "$gemini_adapter"
    render_phase_prompt() { echo "Implement feature ${MONOZUKURI_FEATURE_ID}."; }
    agent_run_phase
  ) || cap_exit=$?
  t3=$(date +%s)
  cap_elapsed=$((t3 - t2))
  rm -rf "$wt2"

  if [ "$cap_elapsed" -le 10 ]; then
    _qa_pass "gemini wall-clock cap terminated hung adapter in ${cap_elapsed}s (≤10s expected)"
  else
    _qa_fail "gemini wall-clock cap took ${cap_elapsed}s — SKILL_TIMEOUT_SECONDS=2 did not fire" \
      || failures=$((failures + 1))
  fi

  return "$failures"
}

# ── 2k–2m. Phase F: schema render parity for codex/gemini ───────────────────
#
# k: ADAPTER=codex  → render_phase_prompt inlines schema for prd/techspec/tasks
# l: ADAPTER=gemini → same
# m: ADAPTER=claude-code → schema NOT inlined (injected separately by _cc_inject_schemas)

_layer2_schema_render_parity() {
  local failures=0
  local render_sh="$REPO_ROOT/lib/prompt/render.sh"

  assert_file_exists "render.sh exists" "$render_sh" \
    || return 1

  # Helper: render a phase prompt under a given adapter context
  _rp_render() {
    local adapter="$1" phase="$2"
    (
      export ADAPTER="$adapter"
      export MONOZUKURI_FEATURE_ID="feat-qa-render"
      export MONOZUKURI_PHASE="$phase"
      unset CONTEXT_JSON 2>/dev/null || true
      source "$render_sh"
      render_phase_prompt "$phase"
    )
  }

  # codex and gemini must see schemas in their rendered prompts
  for adapter in codex gemini; do
    for phase in prd techspec tasks; do
      local rendered
      rendered=$(_rp_render "$adapter" "$phase") || {
        _qa_fail "${adapter}/${phase}: render_phase_prompt returned non-zero" \
          || failures=$((failures + 1))
        continue
      }

      if [[ "$rendered" == *'json-schema.org'* ]]; then
        _qa_pass "${adapter}/${phase}: schema block present in rendered prompt"
      else
        _qa_fail "${adapter}/${phase}: schema block MISSING from rendered prompt (codex/gemini must see schemas)" \
          || failures=$((failures + 1))
      fi
    done

    # Phases without a schema (code, pr) must not get a spurious schema block
    local rendered_code
    rendered_code=$(_rp_render "$adapter" "code") || true
    if [[ "$rendered_code" == *'json-schema.org'* ]]; then
      _qa_fail "${adapter}/code: unexpected schema block injected for code phase" \
        || failures=$((failures + 1))
    else
      _qa_pass "${adapter}/code: no schema block for code phase (correct)"
    fi
  done

  # claude-code must NOT get inlined schemas — it injects via _cc_inject_schemas
  for phase in prd techspec tasks; do
    local rendered
    rendered=$(_rp_render "claude-code" "$phase") || {
      _qa_fail "claude-code/${phase}: render_phase_prompt returned non-zero" \
        || failures=$((failures + 1))
      continue
    }

    if [[ "$rendered" == *'json-schema.org'* ]]; then
      _qa_fail "claude-code/${phase}: schema unexpectedly inlined — claude-code uses file injection" \
        || failures=$((failures + 1))
    else
      _qa_pass "claude-code/${phase}: schema NOT inlined (correct — injected via worktree file)"
    fi
  done

  return "$failures"
}

# ── 2f. Skill config override (Gap 2) ────────────────────────────────────────

_layer2_skill_config_override() {
  local failures=0
  local skill_detect_sh="$REPO_ROOT/lib/agent/skill-detect.sh"
  local parse_config_js="$REPO_ROOT/scripts/parse-config.js"

  assert_file_exists "skill-detect.sh exists" "$skill_detect_sh" || return 1
  assert_file_exists "parse-config.js exists" "$parse_config_js" || return 1

  local tmpdir; tmpdir=$(mktemp -d)
  trap 'rm -rf "$tmpdir"' RETURN

  cat > "$tmpdir/config.yaml" <<'YAML'
agent: claude-code
agents:
  claude-code:
    skills:
      prd: my-custom-prd
YAML

  local result
  result=$(node "$parse_config_js" "$tmpdir/config.yaml" 2>/dev/null || true)
  if echo "$result" | grep -q 'CFG_AGENTS_CLAUDE_CODE_SKILLS_PRD.*my-custom-prd'; then
    _qa_pass "parse-config.js exports CFG_AGENTS_CLAUDE_CODE_SKILLS_PRD for override"
  else
    _qa_fail "parse-config.js did not export CFG_AGENTS_CLAUDE_CODE_SKILLS_PRD=my-custom-prd" \
             "Check scripts/parse-config.js 4-level nesting support" \
      || failures=$((failures + 1))
  fi

  local skill_result
  skill_result=$(
    eval "$(node "$parse_config_js" "$tmpdir/config.yaml" 2>/dev/null)"
    source "$skill_detect_sh"
    phase_to_skill "prd" 2>/dev/null || true
  )
  if [[ "$skill_result" == "my-custom-prd" ]]; then
    _qa_pass "phase_to_skill respects CFG_AGENTS_CLAUDE_CODE_SKILLS_PRD override"
  else
    _qa_fail "phase_to_skill returned '${skill_result}' instead of 'my-custom-prd'" \
             "Check phase_to_skill in lib/agent/skill-detect.sh reads CFG_AGENTS_* first" \
      || failures=$((failures + 1))
  fi

  return "$failures"
}

# ── 2g. Thin-shell template override (Gap 2b) ─────────────────────────────────

_layer2_thin_shell_template_override() {
  local failures=0
  local render_sh="$REPO_ROOT/lib/prompt/render.sh"

  assert_file_exists "render.sh exists" "$render_sh" || return 1

  local tmpdir; tmpdir=$(mktemp -d)
  trap 'rm -rf "$tmpdir"' RETURN

  local phases_dir="$tmpdir/phases"
  mkdir -p "$phases_dir"
  printf '# Sentinel: CUSTOM_OVERRIDE_PRESENT\nFeature: {{feature_id}}\n' \
    > "$phases_dir/custom-codex-prd.tmpl.md"
  printf '# Default prd template\nFeature: {{feature_id}}\n' \
    > "$phases_dir/prd.tmpl.md"

  local rendered
  rendered=$(
    MONOZUKURI_AGENT=codex \
    MONOZUKURI_PHASE=prd \
    MONOZUKURI_FEATURE_ID=test-001 \
    PROMPT_PHASES_DIR="$phases_dir" \
    bash -c "source '$render_sh'; render_phase_prompt prd 'custom-codex-prd'" 2>/dev/null || true
  )
  if echo "$rendered" | grep -q 'CUSTOM_OVERRIDE_PRESENT'; then
    _qa_pass "render_phase_prompt uses custom template when override file exists"
  else
    _qa_fail "render_phase_prompt did not use custom template" \
             "Check render_phase_prompt second arg handling in lib/prompt/render.sh" \
      || failures=$((failures + 1))
  fi

  local warn_output
  warn_output=$(
    MONOZUKURI_AGENT=codex \
    MONOZUKURI_PHASE=prd \
    MONOZUKURI_FEATURE_ID=test-001 \
    PROMPT_PHASES_DIR="$phases_dir" \
    bash -c "source '$render_sh'; render_phase_prompt prd 'nonexistent-override'" 2>&1 >/dev/null || true
  )
  if echo "$warn_output" | grep -qi 'falling back\|not found\|override'; then
    _qa_pass "render_phase_prompt warns when override template missing"
  else
    _qa_fail "render_phase_prompt did not warn about missing override template" \
             "Check stderr warning in render_phase_prompt for missing override file" \
      || failures=$((failures + 1))
  fi

  return "$failures"
}

# ── 2h. NO_COLOR respected (Gap 4b) ──────────────────────────────────────────

_layer2_no_color_respected() {
  local failures=0
  local doctor_cmd="$REPO_ROOT/orchestrate.sh"

  assert_file_exists "orchestrate.sh exists" "$doctor_cmd" || return 1

  local out
  out=$(NO_COLOR=1 "$doctor_cmd" doctor 2>/dev/null || true)
  if printf '%s' "$out" | grep -qP '\033\['; then
    _qa_fail "NO_COLOR=1 monozukuri doctor still emits ANSI escape sequences" \
             "Check lib/cli/tokens.sh and cmd/doctor.sh NO_COLOR handling" \
      || failures=$((failures + 1))
  else
    _qa_pass "NO_COLOR=1 monozukuri doctor: no ANSI escape sequences in stdout"
  fi

  return "$failures"
}

# ── 2i. Status icons consistent — no ❌ (Gap 4b) ─────────────────────────────

_layer2_status_icons_consistent() {
  local failures=0

  local found
  found=$(grep -rn $'❌' "$REPO_ROOT/cmd/" "$REPO_ROOT/lib/cli/" 2>/dev/null | grep -v '.DS_Store' || true)
  if [[ -n "$found" ]]; then
    _qa_fail "Found ❌ icon in cmd/ or lib/cli/ — use ✗ for consistency" \
             "$found" \
      || failures=$((failures + 1))
  else
    _qa_pass "No ❌ icons found in cmd/ or lib/cli/ (all use ✗)"
  fi

  return "$failures"
}

# ── entry point ───────────────────────────────────────────────────────────────

run_layer2() {
  local failures=0

  echo "Layer 2: Loop integrity"

  _layer2_adapter_conformance          || failures=$((failures + 1))
  _layer2_adapter_syntax               || failures=$((failures + 1))
  _layer2_loop_run                     || failures=$((failures + 1))
  _layer2_phase_a_safety               || failures=$((failures + 1))
  _layer2_schema_render_parity         || failures=$((failures + 1))
  _layer2_skill_config_override        || failures=$((failures + 1))
  _layer2_thin_shell_template_override || failures=$((failures + 1))
  _layer2_no_color_respected           || failures=$((failures + 1))
  _layer2_status_icons_consistent      || failures=$((failures + 1))

  return "$failures"
}
