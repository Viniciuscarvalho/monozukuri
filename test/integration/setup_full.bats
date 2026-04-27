#!/usr/bin/env bats
# test/integration/setup_full.bats — end-to-end setup command tests
#
# Sources the real skills from the repo and exercises the full install/uninstall
# cycle against a temporary project directory. Does not touch real ~/.claude etc.

setup() {
  REPO_ROOT="$(cd "$(dirname "$BATS_TEST_FILENAME")/../.." && pwd)"
  LIB_DIR="$REPO_ROOT/lib"
  export LIB_DIR REPO_ROOT

  TMPDIR_TEST="$(mktemp -d)"
  export HOME="$TMPDIR_TEST/home"
  mkdir -p "$HOME"

  ORIG_DIR="$(pwd)"
  mkdir -p "$TMPDIR_TEST/project"
  cd "$TMPDIR_TEST/project"

  # Point to real skills
  export MONOZUKURI_HOME="$REPO_ROOT"

  source "$LIB_DIR/setup/detect.sh"
  source "$LIB_DIR/setup/install.sh"
}

teardown() {
  cd "$ORIG_DIR"
  rm -rf "$TMPDIR_TEST"
}

# ── full install cycle ────────────────────────────────────────────────────────

@test "full cycle: install all skills for claude-code, verify, uninstall" {
  # Install
  setup_install "claude-code" "all" --copy

  # Every mz-* skill should be present
  local skill
  while IFS= read -r skill; do
    [ -f ".claude/skills/$skill/SKILL.md" ]
  done < <(setup_skills_list)

  # Status should show all current
  local status_out
  status_out="$(setup_status "claude-code" "all")"
  [[ "$status_out" != *"missing"* ]]
  [[ "$status_out" != *"drifted"* ]]

  # Uninstall
  setup_uninstall "claude-code" "all"

  # All gone
  while IFS= read -r skill; do
    [ ! -e ".claude/skills/$skill" ]
  done < <(setup_skills_list)
}

@test "full cycle: canonical root shared by universal agents" {
  # Install for two universal agents — canonical written only once
  setup_install "cursor gemini-cli" "mz-create-prd"

  # Both should resolve to the same canonical location
  [ -f ".agents/skills/mz-create-prd/SKILL.md" ]

  # Byte-identical to source
  local src="$REPO_ROOT/skills/mz-create-prd/SKILL.md"
  local dst=".agents/skills/mz-create-prd/SKILL.md"
  cmp -s "$src" "$dst"
}

@test "full cycle: claude-code gets symlink pointing to canonical" {
  setup_install "cursor claude-code" "mz-create-prd"

  # Canonical exists
  [ -f ".agents/skills/mz-create-prd/SKILL.md" ]

  # claude-code path is a symlink
  [ -L ".claude/skills/mz-create-prd" ]

  # And resolves to the same SKILL.md
  local canonical_content symlink_content
  canonical_content="$(cat ".agents/skills/mz-create-prd/SKILL.md")"
  symlink_content="$(cat ".claude/skills/mz-create-prd/SKILL.md")"
  [ "$canonical_content" = "$symlink_content" ]
}

@test "full cycle: dry-run shows plan and makes no changes" {
  local out
  out="$(setup_install "claude-code" "all" --dry-run --copy 2>&1)"

  # Output mentions would-install
  [[ "$out" == *"would install"* ]] || [[ "$out" == *"dry"* ]] || [[ "$out" == *"would"* ]]

  # No files actually created
  [ ! -e ".claude/skills" ]
}

@test "full cycle: idempotent — second install leaves status current" {
  setup_install "claude-code" "mz-create-prd" --copy
  setup_install "claude-code" "mz-create-prd" --copy

  local status_out
  status_out="$(setup_status "claude-code" "mz-create-prd")"
  [[ "$status_out" == *"current"* ]]
  [[ "$status_out" != *"drifted"* ]]
}

@test "full cycle: drift detection catches tampered skill file" {
  setup_install "claude-code" "mz-create-prd" --copy

  # Tamper with an installed file
  echo "# TAMPERED" >> ".claude/skills/mz-create-prd/SKILL.md"

  local status_out
  status_out="$(setup_status "claude-code" "mz-create-prd")"
  [[ "$status_out" == *"drifted"* ]]

  # Re-install with --force should restore it
  setup_install "claude-code" "mz-create-prd" --copy --force
  status_out="$(setup_status "claude-code" "mz-create-prd")"
  [[ "$status_out" == *"current"* ]]
}

@test "full cycle: installed SKILL.md is byte-identical to source" {
  setup_install "claude-code" "mz-create-prd" --copy

  local src="$REPO_ROOT/skills/mz-create-prd/SKILL.md"
  local dst=".claude/skills/mz-create-prd/SKILL.md"
  cmp -s "$src" "$dst"
}

@test "full cycle: gitignore updated when .agents/ is created" {
  touch .gitignore
  setup_install "cursor" "mz-create-prd"

  # .agents/ should be in .gitignore now
  grep -qxF ".agents/" .gitignore
}

@test "full cycle: gitignore not duplicated on second install" {
  touch .gitignore
  setup_install "cursor" "mz-create-prd"
  setup_install "cursor" "mz-create-prd"

  local count
  count="$(grep -c "^\.agents/$" .gitignore || true)"
  [ "$count" -eq 1 ]
}
