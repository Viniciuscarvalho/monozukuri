#!/usr/bin/env bats
# test/unit/skill_allowed_tools.bats — verifies that
#   1. scripts/skill-discovery.sh parses `allowed-tools` from SKILL.md frontmatter
#   2. lib/agent/skill-detect.sh::skill_allowed_tools returns it
#   3. lib/agent/adapter-claude-code.sh logs it at invocation time

setup() {
  REPO_ROOT="$(cd "$(dirname "$BATS_TEST_FILENAME")/../.." && pwd)"
  DISCOVERY="$REPO_ROOT/scripts/skill-discovery.sh"
  TMP=$(mktemp -d)
  HOME_TMP=$(mktemp -d)
  MANIFEST="$TMP/.monozukuri/skills-manifest.json"
  export REPO_ROOT DISCOVERY TMP HOME_TMP MANIFEST
}

teardown() {
  rm -rf "$TMP" "$HOME_TMP"
}

_run_discovery() {
  HOME="$HOME_TMP" CLAUDE_CONFIG_DIR="$HOME_TMP/.claude" \
    bash "$DISCOVERY" "$TMP" "$MANIFEST" >/dev/null 2>&1
  MANIFEST_JSON=$(cat "$MANIFEST" 2>/dev/null || echo '{}')
}

# ── discovery: allowed-tools parsing ──────────────────────────────────────────

@test "discovery captures inline-array allowed-tools" {
  mkdir -p "$TMP/.claude/skills/deploy"
  cat > "$TMP/.claude/skills/deploy/SKILL.md" <<'EOF'
---
name: deploy
phase: deploy
allowed-tools: [Read, Write, Bash]
---
EOF
  _run_discovery
  jq -e '.skills[0].allowed_tools == ["Read","Write","Bash"]' <<<"$MANIFEST_JSON"
}

@test "discovery captures YAML-list allowed-tools" {
  mkdir -p "$TMP/.claude/skills/lint"
  cat > "$TMP/.claude/skills/lint/SKILL.md" <<'EOF'
---
name: lint
phase: tests
allowed-tools:
  - Read
  - Grep
  - Edit
---
EOF
  _run_discovery
  jq -e '.skills[0].allowed_tools == ["Read","Grep","Edit"]' <<<"$MANIFEST_JSON"
}

@test "discovery records empty allowed_tools when frontmatter omits the key" {
  mkdir -p "$TMP/.claude/skills/no-tools"
  cat > "$TMP/.claude/skills/no-tools/SKILL.md" <<'EOF'
---
name: no-tools
phase: prd
---
EOF
  _run_discovery
  jq -e '.skills[0].allowed_tools == []' <<<"$MANIFEST_JSON"
}

# ── skill_allowed_tools helper ────────────────────────────────────────────────

setup_skill_detect() {
  source "$REPO_ROOT/lib/agent/skill-detect.sh"
}

@test "skill_allowed_tools returns comma-separated tools from manifest" {
  mkdir -p "$TMP/.claude/skills/deploy"
  cat > "$TMP/.claude/skills/deploy/SKILL.md" <<'EOF'
---
name: deploy
phase: deploy
allowed-tools: [Read, Write, Bash]
---
EOF
  _run_discovery
  setup_skill_detect
  MONOZUKURI_SKILLS_MANIFEST="$MANIFEST"
  result=$(skill_allowed_tools "deploy")
  [[ "$result" == "Read,Write,Bash" ]]
}

@test "skill_allowed_tools returns empty when skill has no allowed-tools" {
  mkdir -p "$TMP/.claude/skills/no-tools"
  printf -- '---\nname: no-tools\n---\n' > "$TMP/.claude/skills/no-tools/SKILL.md"
  _run_discovery
  setup_skill_detect
  MONOZUKURI_SKILLS_MANIFEST="$MANIFEST"
  result=$(skill_allowed_tools "no-tools")
  [[ -z "$result" ]]
}

@test "skill_allowed_tools returns empty when manifest is absent" {
  setup_skill_detect
  unset MONOZUKURI_SKILLS_MANIFEST
  ROOT_DIR="$TMP"
  result=$(skill_allowed_tools "anything")
  [[ -z "$result" ]]
}

@test "skill_allowed_tools returns empty for unknown skill name" {
  mkdir -p "$TMP/.claude/skills/known"
  cat > "$TMP/.claude/skills/known/SKILL.md" <<'EOF'
---
name: known
allowed-tools: [Read]
---
EOF
  _run_discovery
  setup_skill_detect
  MONOZUKURI_SKILLS_MANIFEST="$MANIFEST"
  result=$(skill_allowed_tools "unknown")
  [[ -z "$result" ]]
}

# ── adapter integration: log line at invocation time ──────────────────────────

# Helper: provide the `info` function the adapter calls (defined in
# orchestrate.sh at runtime; stubbed here for unit isolation).
_setup_adapter_env() {
  source "$REPO_ROOT/lib/cli/output.sh"
  source "$REPO_ROOT/lib/agent/skill-detect.sh"
  source "$REPO_ROOT/lib/agent/adapter-claude-code.sh"
  info() { printf '[info] %s\n' "$*"; }
  _cc_invoke_claude() { return 0; }
  export -f info _cc_invoke_claude
}

@test "claude-code adapter logs allowed-tools before invoking the skill" {
  mkdir -p "$TMP/.claude/skills/deploy"
  cat > "$TMP/.claude/skills/deploy/SKILL.md" <<'EOF'
---
name: deploy
phase: deploy
allowed-tools: [Read, Bash]
---
EOF
  _run_discovery
  _setup_adapter_env

  export MONOZUKURI_SKILLS_MANIFEST="$MANIFEST"
  export MONOZUKURI_PHASE=deploy

  out=$(_cc_run_phase_skill "deploy" "feat-001" "$TMP" "$TMP/run.log" 2>&1 || true)
  [[ "$out" == *"skill deploy declares allowed-tools: Read,Bash"* ]]
}

@test "claude-code adapter stays silent when skill has no allowed-tools" {
  mkdir -p "$TMP/.claude/skills/silent"
  printf -- '---\nname: silent\nphase: deploy\n---\n' > "$TMP/.claude/skills/silent/SKILL.md"
  _run_discovery
  _setup_adapter_env

  export MONOZUKURI_SKILLS_MANIFEST="$MANIFEST"
  export MONOZUKURI_PHASE=deploy

  out=$(_cc_run_phase_skill "silent" "feat-001" "$TMP" "$TMP/run.log" 2>&1 || true)
  [[ "$out" != *"allowed-tools"* ]]
}
