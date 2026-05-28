#!/usr/bin/env bats
# test/integration/doctor_skill_manifest.bats — verifies that
# `monozukuri doctor` and `monozukuri status` surface the skills manifest
# written by scripts/skill-discovery.sh.

setup() {
  REPO_ROOT="$(cd "$(dirname "$BATS_TEST_FILENAME")/../.." && pwd)"
  ORCHESTRATE="$REPO_ROOT/scripts/orchestrate.sh"
  PROJECT=$(mktemp -d)
  STATE_TMPDIR="$PROJECT/.monozukuri/state"

  mkdir -p "$PROJECT/.monozukuri" "$STATE_TMPDIR/feat-001"
  cat > "$PROJECT/.monozukuri/config.yaml" <<'EOCFG'
source:
  adapter: markdown
autonomy: checkpoint
execution:
  base_branch: main
EOCFG
  # Minimal status fixture so `status` has something to render
  cat > "$STATE_TMPDIR/feat-001/status.json" <<'EOF'
{"id":"feat-001","status":"done","title":"fixture"}
EOF

  git -C "$PROJECT" init -q -b main 2>/dev/null || git -C "$PROJECT" init -q
  git -C "$PROJECT" \
    -c user.email=qa@test.local -c user.name=qa -c commit.gpgsign=false \
    add -A
  git -C "$PROJECT" \
    -c user.email=qa@test.local -c user.name=qa -c commit.gpgsign=false \
    commit -q -m init
}

teardown() {
  rm -rf "$PROJECT"
}

# Helper: drop a sample manifest at the path doctor/status expect.
_write_manifest() {
  cat > "$PROJECT/.monozukuri/skills-manifest.json" <<'EOF'
{
  "discovered_at": "2026-05-11T00:00:00Z",
  "project_root": "/tmp/x",
  "skills": [
    { "name": "deploy", "scope": "project", "agent": "claude-code", "phases": ["deploy"] },
    { "name": "lint",   "scope": "global",  "agent": "claude-code", "phases": ["tests"] }
  ]
}
EOF
}

_write_features() {
  cat > "$PROJECT/features.md" <<'EOF'
# Feature Backlog

## feat-001: Fixture feature

Implement the fixture.
EOF
}

_write_codex_stub() {
  mkdir -p "$PROJECT/stubs" "$PROJECT/home"
  cat > "$PROJECT/stubs/codex" <<'EOF'
#!/bin/bash
if [ "${1:-}" = "login" ] && [ "${2:-}" = "status" ]; then
  exit 0
fi
echo "codex test"
EOF
  chmod +x "$PROJECT/stubs/codex"
}

_write_codex_config() {
  local code_skill="${1:-}"
  cat > "$PROJECT/.monozukuri/config.yaml" <<'EOCFG'
agent: codex
source:
  adapter: markdown
  markdown:
    file: features.md
EOCFG
  if [ -n "$code_skill" ]; then
    cat >> "$PROJECT/.monozukuri/config.yaml" <<EOCFG
agents:
  codex:
    skills:
      code: $code_skill
EOCFG
  fi
}

# ── doctor surface ────────────────────────────────────────────────────────────

@test "doctor reports skills-manifest.json count when present" {
  _write_manifest
  mkdir -p "$PROJECT/.claude/skills/deploy"
  printf -- '---\nname: deploy\n---\n' > "$PROJECT/.claude/skills/deploy/SKILL.md"

  cd "$PROJECT"
  out=$(bash "$ORCHESTRATE" doctor 2>&1 || true)

  [[ "$out" == *"skills-manifest.json: 2 skill(s) discovered"* ]]
  [[ "$out" == *"1 project, 1 global"* ]]
  [[ "$out" == *"skills discovered: 2"* ]]
}

@test "doctor reports missing manifest with a hint" {
  cd "$PROJECT"
  out=$(bash "$ORCHESTRATE" doctor 2>&1 || true)
  [[ "$out" == *"skills-manifest.json: not yet built"* ]]
}

@test "doctor counts project-local SKILL.md files separately from manifest" {
  mkdir -p "$PROJECT/.claude/skills/deploy" "$PROJECT/.claude/skills/lint-fix"
  printf -- '---\nname: deploy\n---\n'   > "$PROJECT/.claude/skills/deploy/SKILL.md"
  printf -- '---\nname: lint-fix\n---\n' > "$PROJECT/.claude/skills/lint-fix/SKILL.md"

  cd "$PROJECT"
  out=$(bash "$ORCHESTRATE" doctor 2>&1 || true)

  [[ "$out" == *".claude/skills/: 2 project-local skill(s)"* ]]
}

@test "doctor reports active codex CLI auth injectable skills and live readiness" {
  mkdir -p "$PROJECT/bin"
  cat > "$PROJECT/bin/codex" <<'EOF'
#!/bin/sh
case "$1 $2" in
  "--version ") echo "codex-cli test"; exit 0 ;;
  "login status") exit 0 ;;
esac
exit 0
EOF
  chmod +x "$PROJECT/bin/codex"
  cat > "$PROJECT/.monozukuri/config.yaml" <<'EOCFG'
agent: codex
source:
  adapter: markdown
autonomy: full_auto
execution:
  base_branch: main
EOCFG
  cat > "$PROJECT/.monozukuri/skills-manifest.json" <<'EOF'
{
  "discovered_at": "2026-05-11T00:00:00Z",
  "project_root": "/tmp/x",
  "skills": [
    { "name": "codex-prd", "scope": "project", "agent": "codex", "phases": ["prd"] },
    { "name": "shared-code", "scope": "project", "agent": "any", "phases": ["code"] },
    { "name": "claude-only", "scope": "project", "agent": "claude-code", "phases": ["tests"] }
  ]
}
EOF

  cd "$PROJECT"
  out=$(PATH="$PROJECT/bin:$PATH" bash "$ORCHESTRATE" doctor 2>&1 || true)

  [[ "$out" == *"codex CLI installed"* ]]
  [[ "$out" == *"codex auth OK"* ]]
  [[ "$out" == *"skills discovered: 3"* ]]
  [[ "$out" == *"skills injectable for codex: 2"* ]]
  [[ "$out" == *"loop live validable: codex ready"* ]]
}

@test "doctor --json reports routed Codex skill as usable-injected" {
  _write_features
  _write_codex_stub
  _write_codex_config "custom-code"
  mkdir -p "$PROJECT/.agents/skills/custom-code"
  cat > "$PROJECT/.agents/skills/custom-code/SKILL.md" <<'EOF'
---
name: custom-code
phase: code
---

Use the Codex-compatible code path.
EOF

  cd "$PROJECT"
  out=$(HOME="$PROJECT/home" PATH="$PROJECT/stubs:$PATH" bash "$ORCHESTRATE" doctor --json)

  echo "$out" | jq -e '.phase_routing.code.classification == "usable-injected"'
  echo "$out" | jq -e '.skills[] | select(.name == "custom-code" and .classification == "usable-injected")'
}

@test "doctor --json reports discovered unrouted skill with fixes" {
  _write_features
  _write_codex_stub
  _write_codex_config
  mkdir -p "$PROJECT/.agents/skills/manual-review"
  cat > "$PROJECT/.agents/skills/manual-review/SKILL.md" <<'EOF'
---
name: manual-review
---

Review the implementation.
EOF

  cd "$PROJECT"
  out=$(HOME="$PROJECT/home" PATH="$PROJECT/stubs:$PATH" bash "$ORCHESTRATE" doctor --json)

  echo "$out" | jq -e '.skills[] | select(.name == "manual-review" and .classification == "discovered-not-routed" and (.fixes | length > 0))'
}

@test "doctor --json reports incompatible skill with migration fix" {
  _write_features
  _write_codex_stub
  _write_codex_config
  mkdir -p "$PROJECT/.agents/skills/legacy-code"
  cat > "$PROJECT/.agents/skills/legacy-code/SKILL.md" <<'EOF'
---
name: legacy-code
phase: code
---

Use TodoWrite before editing.
EOF

  cd "$PROJECT"
  out=$(HOME="$PROJECT/home" PATH="$PROJECT/stubs:$PATH" bash "$ORCHESTRATE" doctor --json)

  echo "$out" | jq -e '.phase_routing.code.classification == "incompatible"'
  echo "$out" | jq -e '.skills[] | select(.name == "legacy-code" and .classification == "incompatible" and (.fixes[] | contains("Remove Claude-only tool references")))'
}

@test "doctor --json reports configured missing skill with fix" {
  _write_features
  _write_codex_stub
  _write_codex_config "missing-code"

  cd "$PROJECT"
  out=$(HOME="$PROJECT/home" PATH="$PROJECT/stubs:$PATH" bash "$ORCHESTRATE" doctor --json)

  echo "$out" | jq -e '.phase_routing.code.classification == "missing"'
  echo "$out" | jq -e '.phase_routing.code.fixes | length > 0'
}

@test "doctor --json gives every non-usable skill at least one fix" {
  _write_features
  _write_codex_stub
  _write_codex_config
  mkdir -p "$PROJECT/.agents/skills/manual-review"
  printf -- '---\nname: manual-review\n---\nReview.\n' > "$PROJECT/.agents/skills/manual-review/SKILL.md"

  cd "$PROJECT"
  out=$(HOME="$PROJECT/home" PATH="$PROJECT/stubs:$PATH" bash "$ORCHESTRATE" doctor --json)

  echo "$out" | jq -e '[.skills[] | select((.classification | startswith("usable-") | not) and ((.fixes | length) == 0))] | length == 0'
}

# ── status surface ────────────────────────────────────────────────────────────

@test "status (text) shows 'Discovered skills' line when manifest present" {
  _write_manifest
  cd "$PROJECT"
  out=$(bash "$ORCHESTRATE" status 2>&1 || true)
  [[ "$out" == *"Discovered skills: 2 (1 project, 1 global)"* ]]
}

@test "status --json includes a skills summary when manifest present" {
  _write_manifest
  cd "$PROJECT"
  out=$(bash "$ORCHESTRATE" status --json 2>&1 || true)

  # Verify the JSON parses and skills has expected counts
  echo "$out" | jq -e '.skills.total  == 2'
  echo "$out" | jq -e '.skills.project == 1'
  echo "$out" | jq -e '.skills.global  == 1'
}

@test "status --json omits skills detail when manifest absent" {
  cd "$PROJECT"
  out=$(bash "$ORCHESTRATE" status --json 2>&1 || true)
  echo "$out" | jq -e '.skills == null'
}
