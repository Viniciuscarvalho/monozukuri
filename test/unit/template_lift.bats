#!/usr/bin/env bats

# Verifies that the lifted templates in skills/mz-*/references/ are byte-identical
# to their source files in lib/prompt/phases/.
#
# This is the critical byte-identity invariant from MONOZUKURI_SKILLS_PLAN.md PR1:
# "mz-create-prd/references/prd-template.md is byte-identical to lib/prompt/phases/prd.tmpl.md"
#
# When this test fails, it means a template was edited in one location but not the other.
# Fix: apply the edit to both files, or make skills/mz-*/references/ the canonical source
# and update the legacy path to match.

REPO_ROOT="$(cd "$(dirname "$BATS_TEST_FILENAME")/../.." && pwd)"
PHASES_DIR="$REPO_ROOT/lib/prompt/phases"
SKILLS_DIR="$REPO_ROOT/skills"

@test "mz-create-prd/references/prd-template.md is byte-identical to lib/prompt/phases/prd.tmpl.md" {
  cmp -s \
    "$SKILLS_DIR/mz-create-prd/references/prd-template.md" \
    "$PHASES_DIR/prd.tmpl.md"
}

@test "mz-create-techspec/references/techspec-template.md is byte-identical to lib/prompt/phases/techspec.tmpl.md" {
  cmp -s \
    "$SKILLS_DIR/mz-create-techspec/references/techspec-template.md" \
    "$PHASES_DIR/techspec.tmpl.md"
}

@test "mz-create-tasks/references/tasks-template.md is byte-identical to lib/prompt/phases/tasks.tmpl.md" {
  cmp -s \
    "$SKILLS_DIR/mz-create-tasks/references/tasks-template.md" \
    "$PHASES_DIR/tasks.tmpl.md"
}

@test "mz-open-pr/references/pr-body-template.md is byte-identical to lib/prompt/phases/pr.tmpl.md" {
  cmp -s \
    "$SKILLS_DIR/mz-open-pr/references/pr-body-template.md" \
    "$PHASES_DIR/pr.tmpl.md"
}

@test "lib/prompt/phases/README.md exists (deprecation marker)" {
  [[ -f "$PHASES_DIR/README.md" ]]
}

@test "existing .tmpl.md files are still present (no accidental deletion)" {
  local templates=(prd techspec tasks code tests pr)
  local failed=0
  for t in "${templates[@]}"; do
    if [[ ! -f "$PHASES_DIR/${t}.tmpl.md" ]]; then
      echo "MISSING legacy template: ${t}.tmpl.md" >&3
      failed=1
    fi
  done
  [[ "$failed" -eq 0 ]]
}
