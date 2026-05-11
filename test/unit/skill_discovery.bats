#!/usr/bin/env bats
# test/unit/skill_discovery.bats — unit tests for scripts/skill-discovery.sh
# and the manifest-aware phase_to_skill in lib/agent/skill-detect.sh.

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

# Run discovery with HOME pointed at HOME_TMP so we don't pick up the real user's skills.
_run_discovery() {
  HOME="$HOME_TMP" CLAUDE_CONFIG_DIR="$HOME_TMP/.claude" \
    bash "$DISCOVERY" "$TMP" "$MANIFEST" >/dev/null 2>&1
  MANIFEST_JSON=$(cat "$MANIFEST" 2>/dev/null || echo '{}')
}

# ── discovery: project + global skill scanning ────────────────────────────────

@test "empty project produces an empty skills array" {
  _run_discovery
  jq -e '.skills | length == 0' <<<"$MANIFEST_JSON"
}

@test "project-local .claude/skills/<name>/SKILL.md is discovered" {
  mkdir -p "$TMP/.claude/skills/deploy-staging"
  cat > "$TMP/.claude/skills/deploy-staging/SKILL.md" <<'EOF'
---
name: deploy-staging
description: Deploys to the staging environment
phase: deploy
---
Run kubectl apply...
EOF
  _run_discovery
  jq -e '.skills | length == 1' <<<"$MANIFEST_JSON"
  jq -e '.skills[0].name == "deploy-staging"' <<<"$MANIFEST_JSON"
  jq -e '.skills[0].scope == "project"' <<<"$MANIFEST_JSON"
  jq -e '.skills[0].agent == "claude-code"' <<<"$MANIFEST_JSON"
  jq -e '.skills[0].phases == ["deploy"]' <<<"$MANIFEST_JSON"
}

@test "global ~/.claude/skills/<name>/SKILL.md is discovered" {
  mkdir -p "$HOME_TMP/.claude/skills/lint-fix"
  cat > "$HOME_TMP/.claude/skills/lint-fix/SKILL.md" <<'EOF'
---
name: lint-fix
description: Auto-fix lint errors
---
EOF
  _run_discovery
  jq -e '.skills | length == 1' <<<"$MANIFEST_JSON"
  jq -e '.skills[0].scope == "global"' <<<"$MANIFEST_JSON"
}

@test "project-local takes precedence over global on name collision" {
  mkdir -p "$TMP/.claude/skills/deploy"
  mkdir -p "$HOME_TMP/.claude/skills/deploy"
  printf -- '---\nname: deploy\ndescription: Project version\n---\n' \
    > "$TMP/.claude/skills/deploy/SKILL.md"
  printf -- '---\nname: deploy\ndescription: Global version\n---\n' \
    > "$HOME_TMP/.claude/skills/deploy/SKILL.md"
  _run_discovery
  jq -e '.skills | length == 1' <<<"$MANIFEST_JSON"
  jq -e '.skills[0].description == "Project version"' <<<"$MANIFEST_JSON"
  jq -e '.skills[0].scope == "project"' <<<"$MANIFEST_JSON"
}

@test "SKILL.md without YAML frontmatter is skipped" {
  mkdir -p "$TMP/.claude/skills/no-fm"
  printf 'No frontmatter here.\n' > "$TMP/.claude/skills/no-fm/SKILL.md"
  _run_discovery
  jq -e '.skills | length == 0' <<<"$MANIFEST_JSON"
}

@test ".agents/skills/* is scanned for cursor/codex/gemini" {
  mkdir -p "$TMP/.agents/skills/codex-helper"
  cat > "$TMP/.agents/skills/codex-helper/SKILL.md" <<'EOF'
---
name: codex-helper
agent: codex
phase: code
---
EOF
  _run_discovery
  jq -e '.skills | length == 1' <<<"$MANIFEST_JSON"
  jq -e '.skills[0].agent == "codex"' <<<"$MANIFEST_JSON"
}

@test "skill with multiple phases (YAML list) records all of them" {
  mkdir -p "$TMP/.claude/skills/multi"
  cat > "$TMP/.claude/skills/multi/SKILL.md" <<'EOF'
---
name: multi
phases:
  - code
  - tests
---
EOF
  _run_discovery
  jq -e '.skills[0].phases == ["code","tests"]' <<<"$MANIFEST_JSON"
}

# ── phase_to_skill: manifest lookup integration ───────────────────────────────

setup_skill_detect() {
  source "$REPO_ROOT/lib/agent/skill-detect.sh"
  unset CFG_AGENTS_CLAUDE_CODE_SKILLS_PRD
  unset CFG_AGENTS_CLAUDE_CODE_SKILLS_CODE
  unset MONOZUKURI_SKILLS_MANIFEST
  ROOT_DIR=""
}

@test "phase_to_skill returns mz-* default when no manifest exists" {
  setup_skill_detect
  ROOT_DIR="$TMP"
  result=$(phase_to_skill prd)
  [[ "$result" == "mz-create-prd" ]]
}

@test "phase_to_skill returns project-skill name when manifest matches phase" {
  setup_skill_detect
  mkdir -p "$TMP/.claude/skills/my-prd-skill"
  cat > "$TMP/.claude/skills/my-prd-skill/SKILL.md" <<'EOF'
---
name: my-prd-skill
phase: prd
---
EOF
  _run_discovery
  ROOT_DIR="$TMP"
  result=$(phase_to_skill prd)
  [[ "$result" == "my-prd-skill" ]]
}

@test "phase_to_skill falls back to mz-* default when manifest has no match for phase" {
  setup_skill_detect
  mkdir -p "$TMP/.claude/skills/deploy-skill"
  cat > "$TMP/.claude/skills/deploy-skill/SKILL.md" <<'EOF'
---
name: deploy-skill
phase: deploy
---
EOF
  _run_discovery
  ROOT_DIR="$TMP"
  result=$(phase_to_skill prd)
  [[ "$result" == "mz-create-prd" ]]
}

@test "config override beats manifest for the same phase" {
  setup_skill_detect
  mkdir -p "$TMP/.claude/skills/manifest-skill"
  cat > "$TMP/.claude/skills/manifest-skill/SKILL.md" <<'EOF'
---
name: manifest-skill
phase: prd
---
EOF
  _run_discovery
  export CFG_AGENTS_CLAUDE_CODE_SKILLS_PRD=config-override-skill
  ROOT_DIR="$TMP"
  result=$(phase_to_skill prd)
  unset CFG_AGENTS_CLAUDE_CODE_SKILLS_PRD
  [[ "$result" == "config-override-skill" ]]
}

@test "phase_to_skill respects agent filter (only returns skill matching agent)" {
  setup_skill_detect
  mkdir -p "$TMP/.claude/skills/codex-only"
  cat > "$TMP/.claude/skills/codex-only/SKILL.md" <<'EOF'
---
name: codex-only
agent: codex
phase: prd
---
EOF
  _run_discovery
  ROOT_DIR="$TMP"
  result=$(phase_to_skill prd claude-code)
  # codex-only doesn't match claude-code → fall through to mz-create-prd
  [[ "$result" == "mz-create-prd" ]]
}

@test "MONOZUKURI_SKILLS_MANIFEST overrides manifest path" {
  setup_skill_detect
  custom_manifest=$(mktemp)
  cat > "$custom_manifest" <<'EOF'
{
  "skills": [
    { "name": "custom-prd", "phases": ["prd"], "agent": "any" }
  ]
}
EOF
  export MONOZUKURI_SKILLS_MANIFEST="$custom_manifest"
  result=$(phase_to_skill prd)
  unset MONOZUKURI_SKILLS_MANIFEST
  rm -f "$custom_manifest"
  [[ "$result" == "custom-prd" ]]
}
