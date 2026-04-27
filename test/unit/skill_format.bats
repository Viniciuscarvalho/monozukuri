#!/usr/bin/env bats

# Verifies that every skill under skills/ has well-formed SKILL.md frontmatter.
# Rules (from docs/research/compozy-skills.md §1):
#   - name and description fields must be present and non-empty
#   - name must match the containing directory name
#   - version, allowed-tools, and model fields must NOT be present (drift signals)

SKILLS_DIR="$(cd "$(dirname "$BATS_TEST_FILENAME")/../.." && pwd)/skills"

# Helper: extract a frontmatter value by key from a SKILL.md
frontmatter_value() {
  local file="$1" key="$2"
  awk '/^---$/{n++; next} n==1 && /^'"$key"':/{gsub(/^[^:]+:[[:space:]]*/,""); gsub(/^["'"'"']|["'"'"']$/,""); print; exit}' "$file"
}

# Helper: check if a frontmatter key is present
frontmatter_has_key() {
  local file="$1" key="$2"
  awk '/^---$/{n++; next} n==1 && /^'"$key"':/{found=1; exit} END{exit !found}' "$file"
}

@test "all skill directories have a SKILL.md" {
  local missing=0
  for dir in "$SKILLS_DIR"/*/; do
    if [[ ! -f "$dir/SKILL.md" ]]; then
      echo "MISSING: $dir/SKILL.md" >&3
      missing=1
    fi
  done
  [[ "$missing" -eq 0 ]]
}

@test "every SKILL.md has a non-empty name field" {
  local failed=0
  for skill_md in "$SKILLS_DIR"/*/SKILL.md; do
    local name
    name=$(frontmatter_value "$skill_md" "name")
    if [[ -z "$name" ]]; then
      echo "MISSING name: $skill_md" >&3
      failed=1
    fi
  done
  [[ "$failed" -eq 0 ]]
}

@test "every SKILL.md has a non-empty description field" {
  local failed=0
  for skill_md in "$SKILLS_DIR"/*/SKILL.md; do
    local desc
    desc=$(frontmatter_value "$skill_md" "description")
    if [[ -z "$desc" ]]; then
      echo "MISSING description: $skill_md" >&3
      failed=1
    fi
  done
  [[ "$failed" -eq 0 ]]
}

@test "every SKILL.md name matches its directory name" {
  local failed=0
  for skill_md in "$SKILLS_DIR"/*/SKILL.md; do
    local dir_name name
    dir_name=$(basename "$(dirname "$skill_md")")
    name=$(frontmatter_value "$skill_md" "name")
    if [[ "$name" != "$dir_name" ]]; then
      echo "NAME MISMATCH in $skill_md: frontmatter='$name' dir='$dir_name'" >&3
      failed=1
    fi
  done
  [[ "$failed" -eq 0 ]]
}

@test "no SKILL.md contains a version field (drift signal)" {
  local failed=0
  for skill_md in "$SKILLS_DIR"/*/SKILL.md; do
    if frontmatter_has_key "$skill_md" "version"; then
      echo "UNEXPECTED version field: $skill_md" >&3
      failed=1
    fi
  done
  [[ "$failed" -eq 0 ]]
}

@test "no SKILL.md contains an allowed-tools field (drift signal)" {
  local failed=0
  for skill_md in "$SKILLS_DIR"/*/SKILL.md; do
    if frontmatter_has_key "$skill_md" "allowed-tools"; then
      echo "UNEXPECTED allowed-tools field: $skill_md" >&3
      failed=1
    fi
  done
  [[ "$failed" -eq 0 ]]
}

@test "no SKILL.md contains a model field (drift signal)" {
  local failed=0
  for skill_md in "$SKILLS_DIR"/*/SKILL.md; do
    if frontmatter_has_key "$skill_md" "model"; then
      echo "UNEXPECTED model field: $skill_md" >&3
      failed=1
    fi
  done
  [[ "$failed" -eq 0 ]]
}

@test "all 8 mz-* skill directories exist" {
  local skills=(
    mz-create-prd
    mz-create-techspec
    mz-create-tasks
    mz-execute-task
    mz-run-tests
    mz-open-pr
    mz-workflow-memory
    mz-validate-artifact
  )
  local failed=0
  for skill in "${skills[@]}"; do
    if [[ ! -d "$SKILLS_DIR/$skill" ]]; then
      echo "MISSING skill directory: $skill" >&3
      failed=1
    fi
  done
  [[ "$failed" -eq 0 ]]
}
