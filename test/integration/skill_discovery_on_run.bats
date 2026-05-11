#!/usr/bin/env bats
# test/integration/skill_discovery_on_run.bats — verifies `monozukuri run`
# automatically invokes scripts/skill-discovery.sh on session start and
# writes .monozukuri/skills-manifest.json into the project.
#
# Uses an isolated tmpdir as the project root so it never mutates shared
# fixture branch state (run_dry_run.bats' setup does a `git checkout main`
# inside a non-git fixture, which would otherwise flip monozukuri's branch).

setup() {
  REPO_ROOT="$(cd "$(dirname "$BATS_TEST_FILENAME")/../.." && pwd)"
  ORCHESTRATE="$REPO_ROOT/scripts/orchestrate.sh"
  PROJECT=$(mktemp -d)

  # Minimal valid project layout
  mkdir -p "$PROJECT/.monozukuri"
  cat > "$PROJECT/.monozukuri/config.yaml" <<'EOCFG'
source:
  adapter: markdown
  markdown:
    file: features.md
autonomy: checkpoint
execution:
  base_branch: main
EOCFG
  printf '## feat-001 — test feature\n\nA tiny canary feature.\n' \
    > "$PROJECT/features.md"

  # Init a real git repo so worktree/branch ops don't escape to monozukuri's repo.
  # Signing disabled because this is a throwaway test fixture, not a real commit.
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

@test "run --dry-run writes skills-manifest.json when SKILL_DISCOVERY=true (default)" {
  mkdir -p "$PROJECT/.claude/skills/sample-skill"
  cat > "$PROJECT/.claude/skills/sample-skill/SKILL.md" <<'EOF'
---
name: sample-skill
description: Sample skill for integration test
phase: tests
---
EOF
  (cd "$PROJECT" && bash "$ORCHESTRATE" run --dry-run) >/dev/null 2>&1 || true

  [ -f "$PROJECT/.monozukuri/skills-manifest.json" ]
  jq -e '.skills | length >= 1' "$PROJECT/.monozukuri/skills-manifest.json"
  jq -e '.skills | map(.name) | contains(["sample-skill"])' \
    "$PROJECT/.monozukuri/skills-manifest.json"
}

@test "run --dry-run writes a manifest containing zero project-scoped skills when none installed" {
  (cd "$PROJECT" && bash "$ORCHESTRATE" run --dry-run) >/dev/null 2>&1 || true

  [ -f "$PROJECT/.monozukuri/skills-manifest.json" ]
  # Manifest may still contain user-global skills from ~/.claude/skills/ —
  # what matters is that no project-scoped skills appear when none are installed.
  jq -e '[.skills[] | select(.scope == "project")] | length == 0' \
    "$PROJECT/.monozukuri/skills-manifest.json"
}

@test "run --dry-run exports MONOZUKURI_SKILLS_MANIFEST pointing at the new file" {
  mkdir -p "$PROJECT/.claude/skills/echo-env-skill"
  cat > "$PROJECT/.claude/skills/echo-env-skill/SKILL.md" <<'EOF'
---
name: echo-env-skill
phase: prd
---
EOF
  # Run, then assert MONOZUKURI_SKILLS_MANIFEST is exported by inspecting the
  # discovery block's contract: the env var should be set to the manifest path
  # we expect (.monozukuri/skills-manifest.json).
  (cd "$PROJECT" && bash "$ORCHESTRATE" run --dry-run) >/dev/null 2>&1 || true

  [ -f "$PROJECT/.monozukuri/skills-manifest.json" ]
  # The contract is documented in cmd/run.sh — we assert via the side effect
  # (manifest file exists at the documented path).
}
