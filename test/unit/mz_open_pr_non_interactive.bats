#!/usr/bin/env bats
# test/unit/mz_open_pr_non_interactive.bats
#
# Verifies the pr phase is hardened against interactive gh prompts:
# (i)  mz-open-pr/SKILL.md documents --body-file and MONOZUKURI_INTERACTIVE=0
# (ii) lib/prompt/phases/pr.tmpl.md carries the same non-interactive contract
# (iii) _cc_run_phase_skill sets GH_PROMPT_DISABLED=1 and 180s timeout in
#       full_auto pr phase (prevents gh from opening $EDITOR on hang)

REPO_ROOT="$(cd "$(dirname "$BATS_TEST_FILENAME")/../.." && pwd)"

# ── (i) SKILL.md static contract ─────────────────────────────────────────────

@test "mz-open-pr SKILL.md: contains MONOZUKURI_INTERACTIVE=0 clause" {
  grep -q "MONOZUKURI_INTERACTIVE=0" "$REPO_ROOT/skills/mz-open-pr/SKILL.md"
}

@test "mz-open-pr SKILL.md: uses --body-file instead of bare --body with inline string" {
  grep -q -- "--body-file" "$REPO_ROOT/skills/mz-open-pr/SKILL.md"
}

# ── (ii) render-fallback template static contract ─────────────────────────────

@test "pr.tmpl.md: contains MONOZUKURI_INTERACTIVE=0 non-interactive clause" {
  grep -q "MONOZUKURI_INTERACTIVE=0" "$REPO_ROOT/lib/prompt/phases/pr.tmpl.md"
}

@test "pr.tmpl.md: requires --body-file to avoid shell-escape fallback to \$EDITOR" {
  grep -q -- "--body-file" "$REPO_ROOT/lib/prompt/phases/pr.tmpl.md"
}

@test "pr.tmpl.md: does not offer 'platform native PR API' escape hatch" {
  ! grep -q "platform's native PR API" "$REPO_ROOT/lib/prompt/phases/pr.tmpl.md"
}

# ── (iii) adapter sets GH_PROMPT_DISABLED=1 + 180s timeout for pr/full_auto ──

setup() {
  LIB_DIR="$REPO_ROOT/lib"
  source "$LIB_DIR/agent/contract.sh"
  source "$LIB_DIR/agent/skill-detect.sh"
  source "$LIB_DIR/agent/adapter-claude-code.sh"

  monozukuri_emit() { :; }
  info()  { :; }
  warn()  { :; }
  err()   { :; }
  export -f monozukuri_emit info warn err

  CAPTURE="$(mktemp)"
  export CAPTURE
}

teardown() {
  rm -f "$CAPTURE"
}

@test "_cc_run_phase_skill: pr+full_auto sets GH_PROMPT_DISABLED=1 and 180s cap" {
  local wt; wt=$(mktemp -d)

  # platform_claude captures the timeout (arg 1) and GH_PROMPT_DISABLED from env
  platform_claude() {
    local timeout="$1"
    printf 'timeout=%s\n' "$timeout" > "$CAPTURE"
    printf 'GH_PROMPT_DISABLED=%s\n' "${GH_PROMPT_DISABLED:-unset}" >> "$CAPTURE"
  }
  export -f platform_claude

  MONOZUKURI_PHASE="pr" \
  MONOZUKURI_AUTONOMY="full_auto" \
    _cc_run_phase_skill "mz-open-pr" "feat-001" "$wt" "$wt/run.log" || true

  grep -q "timeout=180" "$CAPTURE"
  grep -q "GH_PROMPT_DISABLED=1" "$CAPTURE"

  rm -rf "$wt"
}

@test "_cc_run_phase_skill: non-pr phase does not set GH_PROMPT_DISABLED" {
  local wt; wt=$(mktemp -d)

  platform_claude() {
    local timeout="$1"
    printf 'timeout=%s\n' "$timeout" > "$CAPTURE"
    printf 'GH_PROMPT_DISABLED=%s\n' "${GH_PROMPT_DISABLED:-unset}" >> "$CAPTURE"
  }
  export -f platform_claude

  unset GH_PROMPT_DISABLED
  MONOZUKURI_PHASE="prd" \
  MONOZUKURI_AUTONOMY="full_auto" \
    _cc_run_phase_skill "mz-create-prd" "feat-001" "$wt" "$wt/run.log" || true

  ! grep -q "GH_PROMPT_DISABLED=1" "$CAPTURE"

  rm -rf "$wt"
}
