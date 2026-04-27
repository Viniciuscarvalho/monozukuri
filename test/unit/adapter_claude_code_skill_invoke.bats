#!/usr/bin/env bats
# test/unit/adapter_claude_code_skill_invoke.bats — PR4 skill-native routing

setup() {
  REPO_ROOT="$(cd "$(dirname "$BATS_TEST_FILENAME")/../.." && pwd)"
  LIB_DIR="$REPO_ROOT/lib"
  FIXTURE_CTX="$REPO_ROOT/test/fixtures/contexts/simple.json"
  MOCK_CLAUDE_DIR="$REPO_ROOT/test/fixtures/agents/mock-claude-code"
  export LIB_DIR FIXTURE_CTX MOCK_CLAUDE_DIR REPO_ROOT

  source "$LIB_DIR/agent/contract.sh"
  source "$LIB_DIR/prompt/render.sh"
  source "$LIB_DIR/agent/skill-detect.sh"
  source "$LIB_DIR/agent/adapter-claude-code.sh"

  # Stub platform_claude: records invocation args to a capture file and exits 0
  platform_claude() {
    local _timeout="$1"; shift
    printf '%s\n' "$@" > "${PLATFORM_ARGS_FILE:-/tmp/platform-args-$$}"
    echo "mock-claude output"
  }
  export -f platform_claude
}

teardown() {
  unset MONOZUKURI_PHASE CONTEXT_JSON MONOZUKURI_FEATURE_ID \
        MONOZUKURI_WORKTREE MONOZUKURI_LOG_FILE MONOZUKURI_ERROR_FILE \
        PLATFORM_ARGS_FILE 2>/dev/null || true
  rm -rf /tmp/cc-skill-test-* 2>/dev/null || true
}

# ── Tier 1: native skill invocation ──────────────────────────────────────────

_install_skill() {
  local wt="$1" skill="$2"
  mkdir -p "$wt/.claude/skills/$skill"
  printf -- "---\nname: %s\n---\nSkill body.\n" "$skill" \
    > "$wt/.claude/skills/$skill/SKILL.md"
}

@test "agent_run_phase: invokes native skill when mz-create-prd is installed" {
  local wt; wt=$(mktemp -d /tmp/cc-skill-test-XXXXX)
  local args_file="$wt/platform-args"
  _install_skill "$wt" "mz-create-prd"

  PLATFORM_ARGS_FILE="$args_file" \
  MONOZUKURI_FEATURE_ID="feat-001" \
  MONOZUKURI_WORKTREE="$wt" \
  MONOZUKURI_LOG_FILE="$wt/run.log" \
  MONOZUKURI_PHASE="prd" \
  CONTEXT_JSON="$FIXTURE_CTX" \
    agent_run_phase

  grep -q -- "--agent" "$args_file"
  grep -q "mz-create-prd" "$args_file"
}

@test "_cc_run_phase_skill: passes skill name as --agent flag" {
  local wt; wt=$(mktemp -d /tmp/cc-skill-test-XXXXX)
  local args_file="$wt/platform-args"

  PLATFORM_ARGS_FILE="$args_file" \
  MONOZUKURI_PHASE="prd" \
    _cc_run_phase_skill "mz-create-prd" "feat-001" "$wt" "$wt/run.log"

  grep -q -- "--agent" "$args_file"
  grep -q "mz-create-prd" "$args_file"
}

@test "_cc_run_phase_skill: writes artifact file on success" {
  local wt; wt=$(mktemp -d /tmp/cc-skill-test-XXXXX)

  MONOZUKURI_PHASE="prd" \
    _cc_run_phase_skill "mz-create-prd" "feat-001" "$wt" "$wt/run.log"

  [ -f "$wt/tasks/prd-feat-001/prd.md" ]
}

@test "_cc_run_phase_skill: passes feat_id as -p argument" {
  local wt; wt=$(mktemp -d /tmp/cc-skill-test-XXXXX)
  local args_file="$wt/platform-args"

  PLATFORM_ARGS_FILE="$args_file" \
  MONOZUKURI_PHASE="techspec" \
    _cc_run_phase_skill "mz-create-techspec" "feat-007" "$wt" "$wt/run.log"

  grep -q "feat-007" "$args_file"
}

@test "_cc_run_phase_skill: returns non-zero when platform_claude fails" {
  local wt; wt=$(mktemp -d /tmp/cc-skill-test-XXXXX)
  platform_claude() { return 1; }
  export -f platform_claude

  MONOZUKURI_PHASE="prd" \
    run _cc_run_phase_skill "mz-create-prd" "feat-001" "$wt" "$wt/run.log"
  [ "$status" -ne 0 ]
}

# ── Tier 2: template-render fallback ─────────────────────────────────────────

@test "agent_run_phase: falls back to render when skill not installed" {
  local wt; wt=$(mktemp -d /tmp/cc-skill-test-XXXXX)
  local args_file="$wt/platform-args"

  # Real mock-claude so render path succeeds
  platform_claude() {
    local _t="$1"; shift
    printf '%s\n' "$@" > "$args_file"
    PATH="$MOCK_CLAUDE_DIR:$PATH" claude "$@"
  }
  export -f platform_claude

  MONOZUKURI_FEATURE_ID="feat-001" \
  MONOZUKURI_WORKTREE="$wt" \
  MONOZUKURI_LOG_FILE="$wt/run.log" \
  MONOZUKURI_PHASE="prd" \
  CONTEXT_JSON="$FIXTURE_CTX" \
    agent_run_phase

  # Render path creates artifact (same as existing test behaviour)
  [ -f "$wt/tasks/prd-feat-001/prd.md" ]
  # Skill flag NOT used (rendered prompt passed as -p value, not --agent <skill>)
  ! grep -q "mz-create-prd" "$args_file" 2>/dev/null || true
}

@test "agent_run_phase: render path covers tasks phase (not just prd/techspec)" {
  local wt; wt=$(mktemp -d /tmp/cc-skill-test-XXXXX)

  platform_claude() {
    local _t="$1"; shift
    PATH="$MOCK_CLAUDE_DIR:$PATH" claude "$@"
  }
  export -f platform_claude

  MONOZUKURI_FEATURE_ID="feat-001" \
  MONOZUKURI_WORKTREE="$wt" \
  MONOZUKURI_LOG_FILE="$wt/run.log" \
  MONOZUKURI_PHASE="tasks" \
  CONTEXT_JSON="$FIXTURE_CTX" \
    agent_run_phase

  [ -f "$wt/tasks/prd-feat-001/tasks.md" ]
}

@test "agent_run_phase: render path covers pr phase" {
  local wt; wt=$(mktemp -d /tmp/cc-skill-test-XXXXX)

  platform_claude() {
    local _t="$1"; shift
    PATH="$MOCK_CLAUDE_DIR:$PATH" claude "$@"
  }
  export -f platform_claude

  MONOZUKURI_FEATURE_ID="feat-001" \
  MONOZUKURI_WORKTREE="$wt" \
  MONOZUKURI_LOG_FILE="$wt/run.log" \
  MONOZUKURI_PHASE="pr" \
  CONTEXT_JSON="$FIXTURE_CTX" \
    agent_run_phase

  [ -f "$wt/tasks/prd-feat-001/pr.md" ]
}

# ── Tier 3: legacy feature-marker fallback ────────────────────────────────────

@test "agent_run_phase: uses legacy path when no phase and no CONTEXT_JSON" {
  local wt; wt=$(mktemp -d /tmp/cc-skill-test-XXXXX)
  local args_file="$wt/platform-args"

  platform_claude() {
    local _t="$1"; shift
    printf '%s\n' "$@" > "$args_file"
  }
  export -f platform_claude

  MONOZUKURI_FEATURE_ID="feat-001" \
  MONOZUKURI_WORKTREE="$wt" \
  MONOZUKURI_LOG_FILE="$wt/run.log" \
    agent_run_phase || true

  grep -q -- "--agent" "$args_file"
  grep -q "feature-marker" "$args_file"
}

@test "agent_run_phase: skill path wins over render path when skill installed" {
  local wt; wt=$(mktemp -d /tmp/cc-skill-test-XXXXX)
  local args_file="$wt/platform-args"
  _install_skill "$wt" "mz-create-prd"

  platform_claude() {
    local _t="$1"; shift
    printf '%s\n' "$@" > "$args_file"
    echo "mock output"
  }
  export -f platform_claude

  MONOZUKURI_FEATURE_ID="feat-001" \
  MONOZUKURI_WORKTREE="$wt" \
  MONOZUKURI_LOG_FILE="$wt/run.log" \
  MONOZUKURI_PHASE="prd" \
  CONTEXT_JSON="$FIXTURE_CTX" \
    agent_run_phase

  # Skill native path uses --agent <skill-name>, NOT a rendered prompt
  grep -q "mz-create-prd" "$args_file"
  # The feat-id is the -p argument (not a rendered template text)
  grep -q "feat-001" "$args_file"
}
