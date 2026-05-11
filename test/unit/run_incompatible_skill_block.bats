#!/usr/bin/env bats
# test/unit/run_incompatible_skill_block.bats — hard-block gate in cmd/run.sh
#
# Tests that _run_check_incompatible_skills() exits EXIT_CONFIG_INVALID=10
# when a phase is configured to a known-incompatible skill, and passes through
# when all skills are mz-* compliant.

setup() {
  REPO_ROOT="$(cd "$(dirname "$BATS_TEST_FILENAME")/../.." && pwd)"
  REAL_LIB_DIR="$REPO_ROOT/lib"
  export REPO_ROOT REAL_LIB_DIR

  TMPDIR_TEST="$(mktemp -d)"
  ORIG_DIR="$(pwd)"
  export TMPDIR_TEST ORIG_DIR

  # LIB_DIR needs known-incompatible.sh and skill-detect.sh available
  export LIB_DIR="$REAL_LIB_DIR"

  # EXIT_CONFIG_INVALID constant (normally from lib/core/exit-codes.sh via modules_init)
  export EXIT_CONFIG_INVALID=10
}

teardown() {
  cd "$ORIG_DIR"
  rm -rf "$TMPDIR_TEST"
}

# Helper: run _run_check_incompatible_skills in a subshell so exit() doesn't kill bats
_run_check() {
  bash -c "
    set -euo pipefail
    export LIB_DIR='$LIB_DIR'
    export EXIT_CONFIG_INVALID=10
    export MONOZUKURI_AGENT='claude-code'
    $(for kv in "$@"; do echo "export $kv"; done)

    # Define err() the same way orchestrate.sh does
    err() { printf 'ERROR: %s\n' \"\$*\" >&2; }

    source '$REPO_ROOT/cmd/run.sh'
    _run_check_incompatible_skills
  " 2>&1
}

@test "passes when no phase overrides are set (default mz-* mapping)" {
  # No CFG_AGENTS_* vars → phase_to_skill returns mz-* defaults → should pass
  run bash -c "
    set -euo pipefail
    export LIB_DIR='$LIB_DIR'
    export EXIT_CONFIG_INVALID=10
    export MONOZUKURI_AGENT='claude-code'
    err() { printf 'ERROR: %s\n' \"\$*\" >&2; }
    source '$REPO_ROOT/cmd/run.sh'
    _run_check_incompatible_skills
  " 2>&1
  [ "$status" -eq 0 ]
}

@test "passes when all phase overrides are mz-* skills" {
  run bash -c "
    set -euo pipefail
    export LIB_DIR='$LIB_DIR'
    export EXIT_CONFIG_INVALID=10
    export MONOZUKURI_AGENT='claude-code'
    export CFG_AGENTS_CLAUDE_CODE_SKILLS_PRD='mz-create-prd'
    export CFG_AGENTS_CLAUDE_CODE_SKILLS_TECHSPEC='mz-create-techspec'
    export CFG_AGENTS_CLAUDE_CODE_SKILLS_TASKS='mz-create-tasks'
    export CFG_AGENTS_CLAUDE_CODE_SKILLS_CODE='mz-execute-task'
    export CFG_AGENTS_CLAUDE_CODE_SKILLS_TESTS='mz-run-tests'
    export CFG_AGENTS_CLAUDE_CODE_SKILLS_PR='mz-open-pr'
    err() { printf 'ERROR: %s\n' \"\$*\" >&2; }
    source '$REPO_ROOT/cmd/run.sh'
    _run_check_incompatible_skills
  " 2>&1
  [ "$status" -eq 0 ]
}

@test "exits EXIT_CONFIG_INVALID when code phase maps to feature-marker" {
  run bash -c "
    set -euo pipefail
    export LIB_DIR='$LIB_DIR'
    export EXIT_CONFIG_INVALID=10
    export MONOZUKURI_AGENT='claude-code'
    export CFG_AGENTS_CLAUDE_CODE_SKILLS_CODE='feature-marker'
    err() { printf 'ERROR: %s\n' \"\$*\" >&2; }
    source '$REPO_ROOT/cmd/run.sh'
    _run_check_incompatible_skills
  " 2>&1
  [ "$status" -eq 10 ]
}

@test "stderr names the incompatible skill on hard block" {
  run bash -c "
    set -euo pipefail
    export LIB_DIR='$LIB_DIR'
    export EXIT_CONFIG_INVALID=10
    export MONOZUKURI_AGENT='claude-code'
    export CFG_AGENTS_CLAUDE_CODE_SKILLS_CODE='feature-marker'
    err() { printf 'ERROR: %s\n' \"\$*\" >&2; }
    source '$REPO_ROOT/cmd/run.sh'
    _run_check_incompatible_skills
  " 2>&1
  [[ "$output" == *"feature-marker"* ]]
}

@test "stderr names the affected phase on hard block" {
  run bash -c "
    set -euo pipefail
    export LIB_DIR='$LIB_DIR'
    export EXIT_CONFIG_INVALID=10
    export MONOZUKURI_AGENT='claude-code'
    export CFG_AGENTS_CLAUDE_CODE_SKILLS_PRD='feature-marker'
    err() { printf 'ERROR: %s\n' \"\$*\" >&2; }
    source '$REPO_ROOT/cmd/run.sh'
    _run_check_incompatible_skills
  " 2>&1
  [[ "$output" == *"prd"* ]]
}

@test "blocks on prd phase mapped to feature-marker" {
  run bash -c "
    set -euo pipefail
    export LIB_DIR='$LIB_DIR'
    export EXIT_CONFIG_INVALID=10
    export MONOZUKURI_AGENT='claude-code'
    export CFG_AGENTS_CLAUDE_CODE_SKILLS_PRD='feature-marker'
    err() { printf 'ERROR: %s\n' \"\$*\" >&2; }
    source '$REPO_ROOT/cmd/run.sh'
    _run_check_incompatible_skills
  " 2>&1
  [ "$status" -eq 10 ]
}

@test "stderr contains fix guidance on hard block" {
  run bash -c "
    set -euo pipefail
    export LIB_DIR='$LIB_DIR'
    export EXIT_CONFIG_INVALID=10
    export MONOZUKURI_AGENT='claude-code'
    export CFG_AGENTS_CLAUDE_CODE_SKILLS_CODE='feature-marker'
    err() { printf 'ERROR: %s\n' \"\$*\" >&2; }
    source '$REPO_ROOT/cmd/run.sh'
    _run_check_incompatible_skills
  " 2>&1
  [[ "$output" == *"Fix"* ]] || [[ "$output" == *"config.yaml"* ]]
}

@test "no-op when lib files are absent (graceful degradation)" {
  run bash -c "
    set -euo pipefail
    export LIB_DIR='/tmp/nonexistent-lib-dir-$$'
    export EXIT_CONFIG_INVALID=10
    export MONOZUKURI_AGENT='claude-code'
    err() { printf 'ERROR: %s\n' \"\$*\" >&2; }
    source '$REPO_ROOT/cmd/run.sh'
    _run_check_incompatible_skills
  " 2>&1
  [ "$status" -eq 0 ]
}
