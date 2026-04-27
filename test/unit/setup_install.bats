#!/usr/bin/env bats
# test/unit/setup_install.bats — unit tests for lib/setup/install.sh

setup() {
  REPO_ROOT="$(cd "$(dirname "$BATS_TEST_FILENAME")/../.." && pwd)"
  LIB_DIR="$REPO_ROOT/lib"
  export LIB_DIR

  source "$LIB_DIR/setup/detect.sh"
  source "$LIB_DIR/setup/install.sh"

  TMPDIR_TEST="$(mktemp -d)"
  export HOME="$TMPDIR_TEST/home"
  mkdir -p "$HOME"

  ORIG_DIR="$(pwd)"
  # Work inside a temp project dir so installs go to $TMPDIR_TEST/project/
  mkdir -p "$TMPDIR_TEST/project"
  cd "$TMPDIR_TEST/project"

  # Point MONOZUKURI_HOME to a dir with a mock skills/ tree
  MONOZUKURI_HOME="$TMPDIR_TEST/mz_home"
  export MONOZUKURI_HOME
  mkdir -p "$MONOZUKURI_HOME/skills/mz-create-prd/references"
  printf -- "---\nname: mz-create-prd\ndescription: Generate a PRD.\n---\n\nSkill body.\n" \
    > "$MONOZUKURI_HOME/skills/mz-create-prd/SKILL.md"
  printf "PRD template content here.\n" \
    > "$MONOZUKURI_HOME/skills/mz-create-prd/references/prd-template.md"

  mkdir -p "$MONOZUKURI_HOME/skills/mz-create-techspec/references"
  printf -- "---\nname: mz-create-techspec\ndescription: Generate a TechSpec.\n---\n\nSkill body.\n" \
    > "$MONOZUKURI_HOME/skills/mz-create-techspec/SKILL.md"
}

teardown() {
  cd "$ORIG_DIR"
  rm -rf "$TMPDIR_TEST"
}

# ── setup_skills_source_dir ───────────────────────────────────────────────────

@test "setup_skills_source_dir: returns MONOZUKURI_HOME/skills when set" {
  [ "$(setup_skills_source_dir)" = "$MONOZUKURI_HOME/skills" ]
}

# ── setup_skills_list ─────────────────────────────────────────────────────────

@test "setup_skills_list: returns mz-* skills only" {
  local list
  list="$(setup_skills_list)"
  [[ "$list" == *"mz-create-prd"* ]]
  [[ "$list" == *"mz-create-techspec"* ]]
}

@test "setup_skills_list: excludes non-mz directories" {
  mkdir -p "$MONOZUKURI_HOME/skills/grill-me"
  printf -- "---\nname: grill-me\ndescription: Grill.\n---\n" \
    > "$MONOZUKURI_HOME/skills/grill-me/SKILL.md"
  local list
  list="$(setup_skills_list)"
  [[ "$list" != *"grill-me"* ]]
}

# ── setup_skill_status ────────────────────────────────────────────────────────

@test "setup_skill_status: missing when dst does not exist" {
  local src="$MONOZUKURI_HOME/skills/mz-create-prd"
  [ "$(setup_skill_status "$src" "nonexistent/path")" = "missing" ]
}

@test "setup_skill_status: current when dst matches src byte-for-byte" {
  local src="$MONOZUKURI_HOME/skills/mz-create-prd"
  local dst="$TMPDIR_TEST/project/.agents/skills/mz-create-prd"
  mkdir -p "$dst/references"
  cp "$src/SKILL.md" "$dst/SKILL.md"
  cp "$src/references/prd-template.md" "$dst/references/prd-template.md"
  [ "$(setup_skill_status "$src" "$dst")" = "current" ]
}

@test "setup_skill_status: drifted when a file differs" {
  local src="$MONOZUKURI_HOME/skills/mz-create-prd"
  local dst="$TMPDIR_TEST/project/.agents/skills/mz-create-prd"
  mkdir -p "$dst/references"
  cp "$src/SKILL.md" "$dst/SKILL.md"
  echo "modified content" > "$dst/references/prd-template.md"
  [ "$(setup_skill_status "$src" "$dst")" = "drifted" ]
}

@test "setup_skill_status: foreign when dst has no SKILL.md" {
  local src="$MONOZUKURI_HOME/skills/mz-create-prd"
  local dst="$TMPDIR_TEST/project/.agents/skills/mz-create-prd"
  mkdir -p "$dst"
  echo "some other content" > "$dst/README.md"
  [ "$(setup_skill_status "$src" "$dst")" = "foreign" ]
}

# ── setup_install: copy mode ──────────────────────────────────────────────────

@test "setup_install: creates skill files at agent path (copy mode)" {
  setup_install "claude-code" "mz-create-prd" --copy
  [ -f ".claude/skills/mz-create-prd/SKILL.md" ]
  [ -f ".claude/skills/mz-create-prd/references/prd-template.md" ]
}

@test "setup_install: creates canonical and universal agent can read it" {
  setup_install "cursor" "mz-create-prd"
  [ -f ".agents/skills/mz-create-prd/SKILL.md" ]
}

@test "setup_install: claude-code gets symlink to canonical when universal also selected" {
  setup_install "cursor claude-code" "mz-create-prd"
  [ -f ".agents/skills/mz-create-prd/SKILL.md" ]
  [ -L ".claude/skills/mz-create-prd" ]
}

@test "setup_install: dry-run makes no filesystem changes" {
  setup_install "claude-code" "mz-create-prd" --dry-run --copy
  [ ! -e ".claude/skills/mz-create-prd" ]
}

@test "setup_install: is idempotent (running twice produces same result)" {
  setup_install "claude-code" "mz-create-prd" --copy
  setup_install "claude-code" "mz-create-prd" --copy
  [ -f ".claude/skills/mz-create-prd/SKILL.md" ]
}

@test "setup_install: refuses to overwrite foreign skill without --force" {
  mkdir -p ".claude/skills/mz-create-prd"
  echo "foreign content" > ".claude/skills/mz-create-prd/README.md"
  local out
  out="$(setup_install "claude-code" "mz-create-prd" --copy 2>&1)"
  [[ "$out" == *"foreign"* ]] || [[ "$out" == *"SKIP"* ]]
  # The foreign file must still be intact
  [ -f ".claude/skills/mz-create-prd/README.md" ]
  [ ! -f ".claude/skills/mz-create-prd/SKILL.md" ]
}

@test "setup_install: --force overwrites foreign skill" {
  mkdir -p ".claude/skills/mz-create-prd"
  echo "foreign content" > ".claude/skills/mz-create-prd/README.md"
  setup_install "claude-code" "mz-create-prd" --copy --force
  [ -f ".claude/skills/mz-create-prd/SKILL.md" ]
}

@test "setup_install: installs all skills with skill_list=all" {
  setup_install "cursor" "all" --copy
  [ -f ".agents/skills/mz-create-prd/SKILL.md" ]
  [ -f ".agents/skills/mz-create-techspec/SKILL.md" ]
}

# ── setup_uninstall ───────────────────────────────────────────────────────────

@test "setup_uninstall: removes installed skill" {
  setup_install "claude-code" "mz-create-prd" --copy
  [ -f ".claude/skills/mz-create-prd/SKILL.md" ]
  setup_uninstall "claude-code" "mz-create-prd"
  [ ! -e ".claude/skills/mz-create-prd" ]
}

@test "setup_uninstall: dry-run does not remove files" {
  setup_install "claude-code" "mz-create-prd" --copy
  setup_uninstall "claude-code" "mz-create-prd" --dry-run
  [ -f ".claude/skills/mz-create-prd/SKILL.md" ]
}

@test "setup_uninstall: skips foreign directories (no SKILL.md)" {
  mkdir -p ".claude/skills/mz-create-prd"
  echo "foreign" > ".claude/skills/mz-create-prd/README.md"
  local out
  out="$(setup_uninstall "claude-code" "mz-create-prd" 2>&1)"
  [[ "$out" == *"foreign"* ]] || [[ "$out" == *"SKIP"* ]]
  [ -f ".claude/skills/mz-create-prd/README.md" ]
}

@test "setup_uninstall: removes canonical for universal agents" {
  setup_install "cursor" "mz-create-prd"
  [ -f ".agents/skills/mz-create-prd/SKILL.md" ]
  setup_uninstall "cursor" "mz-create-prd"
  [ ! -e ".agents/skills/mz-create-prd" ]
}

@test "setup_uninstall: removes symlink for claude-code in canonical mode" {
  setup_install "cursor claude-code" "mz-create-prd"
  [ -L ".claude/skills/mz-create-prd" ]
  setup_uninstall "cursor claude-code" "mz-create-prd"
  [ ! -e ".claude/skills/mz-create-prd" ]
  [ ! -e ".agents/skills/mz-create-prd" ]
}

# ── setup_status ──────────────────────────────────────────────────────────────

@test "setup_status: shows missing before install" {
  local out
  out="$(setup_status "claude-code" "mz-create-prd")"
  [[ "$out" == *"missing"* ]]
}

@test "setup_status: shows current after install" {
  setup_install "claude-code" "mz-create-prd" --copy
  local out
  out="$(setup_status "claude-code" "mz-create-prd")"
  [[ "$out" == *"current"* ]]
}

@test "setup_status: shows drifted after manual edit" {
  setup_install "claude-code" "mz-create-prd" --copy
  echo "tampered" >> ".claude/skills/mz-create-prd/SKILL.md"
  local out
  out="$(setup_status "claude-code" "mz-create-prd")"
  [[ "$out" == *"drifted"* ]]
}
