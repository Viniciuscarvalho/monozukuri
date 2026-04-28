#!/bin/bash
# .qa/layers/03-schema-integrity.sh — Layer 3: Schema integrity
set -euo pipefail

QA_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
REPO_ROOT="$(cd "$QA_DIR/.." && pwd)"
source "$QA_DIR/lib/assert.sh"

MONOZUKURI_HOME="$REPO_ROOT"
export MONOZUKURI_HOME
source "$REPO_ROOT/lib/schema/validate.sh"

run_layer3() {
  local artifact_dir="${1:-$QA_DIR/fixtures}"
  local failures=0

  echo "Layer 3: Schema integrity"

  # ── 3a. Canonical PRD ───────────────────────────────────────────────────────
  local prd_file="$artifact_dir/prd-canonical.md"
  assert_file_exists "prd-canonical.md present" "$prd_file" \
    || { failures=$((failures + 1)); }
  if schema_validate "prd" "$prd_file"; then
    _qa_pass "prd-canonical.md passes schema_validate"
  else
    _qa_fail "prd-canonical.md failed: $SCHEMA_VALIDATE_ERROR" \
      || failures=$((failures + 1))
  fi

  # ── 3b. Heading-alias regression (Background / Acceptance Criteria) ─────────
  local prd_alias="$artifact_dir/prd-alias-headings.md"
  assert_file_exists "prd-alias-headings.md present" "$prd_alias" \
    || { failures=$((failures + 1)); }
  if schema_validate "prd" "$prd_alias"; then
    _qa_pass "prd alias headings (Background/Acceptance Criteria) accepted"
  else
    _qa_fail "prd alias regression: '$SCHEMA_VALIDATE_ERROR' — alias patterns may have been removed" \
      || failures=$((failures + 1))
  fi

  # ── 3c. Canonical TechSpec ──────────────────────────────────────────────────
  local ts_file="$artifact_dir/techspec-canonical.md"
  assert_file_exists "techspec-canonical.md present" "$ts_file" \
    || { failures=$((failures + 1)); }
  if schema_validate "techspec" "$ts_file"; then
    _qa_pass "techspec-canonical.md passes schema_validate"
  else
    _qa_fail "techspec-canonical.md failed: $SCHEMA_VALIDATE_ERROR" \
      || failures=$((failures + 1))
  fi

  # ── 3d. Canonical tasks.json ────────────────────────────────────────────────
  local tasks_file="$artifact_dir/tasks-canonical.json"
  assert_file_exists "tasks-canonical.json present" "$tasks_file" \
    || { failures=$((failures + 1)); }
  if schema_validate "tasks" "$tasks_file"; then
    _qa_pass "tasks-canonical.json passes schema_validate"
  else
    _qa_fail "tasks-canonical.json failed: $SCHEMA_VALIDATE_ERROR" \
      || failures=$((failures + 1))
  fi

  # ── 3e. Hybrid content assertions on tasks.json ─────────────────────────────
  assert_json_field "tasks[0].id non-empty" "$tasks_file" ".0.id" \
    || failures=$((failures + 1))
  assert_json_field "tasks[0].title non-empty" "$tasks_file" ".0.title" \
    || failures=$((failures + 1))
  assert_json_field "tasks[0].acceptance_criteria non-empty" "$tasks_file" ".0.acceptance_criteria" \
    || failures=$((failures + 1))

  # ── 3f. Validator self-test: invalid fixture must be rejected ───────────────
  local bad_prd
  bad_prd=$(mktemp)
  printf '# PRD\n\nNo required headings present.\n' > "$bad_prd"
  if schema_validate "prd" "$bad_prd" 2>/dev/null; then
    _qa_fail "invalid PRD passed schema_validate — validator may be broken" \
      || failures=$((failures + 1))
  else
    _qa_pass "invalid PRD correctly rejected by schema_validate"
  fi
  rm -f "$bad_prd"

  return "$failures"
}
