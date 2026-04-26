#!/usr/bin/env bats
# test/integration/legacy_skill_command_back_compat.bats
# Verifies that old-style configs (skill.command: feature-marker, no agent: key)
# continue to work after the multi-agent refactor.

setup() {
  REPO_ROOT="$(cd "$(dirname "$BATS_TEST_FILENAME")/../.." && pwd)"
  ORCHESTRATE="$REPO_ROOT/orchestrate.sh"
  SAMPLE_PROJECT="$REPO_ROOT/test/fixtures/sample-project"
  MOCK_CLAUDE="$REPO_ROOT/test/fixtures/agents/mock-claude-code"

  mkdir -p "$SAMPLE_PROJECT/.monozukuri"
  # Old-style config: skill.command only, no agent: key
  cat > "$SAMPLE_PROJECT/.monozukuri/config.yaml" << 'EOCFG'
source:
  adapter: markdown
  markdown:
    file: features.md
autonomy: checkpoint
execution:
  base_branch: main
skill:
  command: feature-marker
EOCFG

  cd "$SAMPLE_PROJECT"
  git checkout -b main 2>/dev/null || git checkout main 2>/dev/null || true

  export PATH="$MOCK_CLAUDE:$PATH"
}

teardown() {
  rm -f "$SAMPLE_PROJECT/.monozukuri/config.yaml" \
        "$SAMPLE_PROJECT/orchestration-backlog.json"
}

@test "legacy config (skill.command only) dry-run exits 0" {
  run bash "$ORCHESTRATE" run --dry-run --non-interactive
  [ "$status" -eq 0 ]
}

@test "legacy config dry-run shows plan output" {
  run bash "$ORCHESTRATE" run --dry-run --non-interactive
  [[ "$output" == *"feat-001"* ]] || [[ "$output" == *"Dry Run"* ]]
}

@test "legacy config sets MONOZUKURI_AGENT to claude-code via back-compat shim" {
  local cfg_dir="$SAMPLE_PROJECT/.monozukuri"
  local tmp_script
  tmp_script="$(mktemp /tmp/mz_test_XXXXXX.sh)"
  cat > "$tmp_script" <<SCRIPT
#!/bin/bash
LIB_DIR="$REPO_ROOT/lib"
SCRIPTS_DIR="$REPO_ROOT/scripts"
CONFIG_DIR="$cfg_dir"
ROOT_DIR="$SAMPLE_PROJECT"
TEMPLATES_DIR="$REPO_ROOT/templates"
STATE_DIR="/tmp/mz-test-state-$$"
RESULTS_DIR="/tmp/mz-test-results-$$"
OPT_DRY_RUN=false
OPT_NON_INTERACTIVE=true
cd "$SAMPLE_PROJECT"
source "\$LIB_DIR/core/modules.sh"
modules_init "\$LIB_DIR"
module_require core/util
module_require cli/output
module_require config/load
load_config "\$CONFIG_DIR/config.yaml" 2>/dev/null || true
echo "AGENT=\${MONOZUKURI_AGENT:-unset}"
echo "SKILL=\${SKILL_COMMAND:-unset}"
SCRIPT
  chmod +x "$tmp_script"
  run bash "$tmp_script"
  rm -f "$tmp_script"
  [[ "$output" == *"AGENT=claude-code"* ]]
  [[ "$output" == *"SKILL=feature-marker"* ]]
}
