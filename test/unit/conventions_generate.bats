#!/usr/bin/env bats
# test/unit/conventions_generate.bats — conventions_generate_content unit tests

setup() {
  REPO_ROOT="$(cd "$(dirname "$BATS_TEST_FILENAME")/../.." && pwd)"
  LIB_DIR="$REPO_ROOT/lib"
  FIXTURES="$REPO_ROOT/test/fixtures/projects"
  export LIB_DIR REPO_ROOT FIXTURES
  source "$LIB_DIR/agent/conventions-generate.sh"
  unset PROJECT_BUILD_CMD PROJECT_TEST_CMD
}

# ── markers ───────────────────────────────────────────────────────────────────

@test "output contains opening marker" {
  result=$(conventions_generate_content "$FIXTURES/no-agents-md")
  [[ "$result" == *"<!-- monozukuri:generated-start v1 -->"* ]]
}

@test "output contains closing marker" {
  result=$(conventions_generate_content "$FIXTURES/no-agents-md")
  [[ "$result" == *"<!-- monozukuri:generated-end -->"* ]]
}

@test "opening marker appears before closing marker" {
  tmpout=$(mktemp)
  conventions_generate_content "$FIXTURES/no-agents-md" > "$tmpout"
  start_line=$(grep -n "generated-start" "$tmpout" | cut -d: -f1)
  end_line=$(grep   -n "generated-end"   "$tmpout" | cut -d: -f1)
  rm -f "$tmpout"
  [ "$start_line" -lt "$end_line" ]
}

# ── learning entries ─────────────────────────────────────────────────────────

@test "non-archived learning entries appear in output" {
  result=$(conventions_generate_content "$FIXTURES/no-agents-md")
  [[ "$result" == *"kysely migration fails"* ]]
}

@test "archived entries are excluded from output" {
  result=$(conventions_generate_content "$FIXTURES/no-agents-md")
  [[ "$result" != *"archived entry should be skipped"* ]]
}

@test "fix text appears alongside pattern" {
  result=$(conventions_generate_content "$FIXTURES/no-agents-md")
  [[ "$result" == *"defaultTo(null)"* ]]
}

@test "empty store produces block with only markers" {
  tmpdir=$(mktemp -d)
  result=$(conventions_generate_content "$tmpdir")
  rm -rf "$tmpdir"
  [[ "$result" == *"generated-start"* ]]
  [[ "$result" == *"generated-end"* ]]
  [[ "$result" != *"## Conventions"* ]]
}

# ── stack profile integration ─────────────────────────────────────────────────

@test "PROJECT_BUILD_CMD appears under Build section" {
  PROJECT_BUILD_CMD="npm run build"
  result=$(conventions_generate_content "$FIXTURES/no-agents-md")
  [[ "$result" == *"## Build"* ]]
  [[ "$result" == *'`npm run build`'* ]]
}

@test "PROJECT_TEST_CMD appears under Test section" {
  PROJECT_TEST_CMD="bats test/"
  result=$(conventions_generate_content "$FIXTURES/no-agents-md")
  [[ "$result" == *"## Test"* ]]
  [[ "$result" == *'`bats test/`'* ]]
}

@test "no Build section when PROJECT_BUILD_CMD unset" {
  unset PROJECT_BUILD_CMD
  result=$(conventions_generate_content "$FIXTURES/no-agents-md")
  [[ "$result" != *"## Build"* ]]
}

# ── deduplication ────────────────────────────────────────────────────────────

@test "duplicate patterns appear only once (project wins)" {
  tmpdir=$(mktemp -d)
  mkdir -p "$tmpdir/.claude/feature-state"
  cat > "$tmpdir/.claude/feature-state/learned.json" <<'EOF'
[
  {"id":"l1","pattern":"same pattern","fix":"project fix","tier":"project",
   "archived":false,"confidence":0.9,"hits":2,"success_count":2,"failure_count":0,
   "ttl_days":90,"promotion_candidate":false,"created_at":"2026-01-01T00:00:00Z","last_seen":"2026-01-01T00:00:00Z"},
  {"id":"l2","pattern":"same pattern","fix":"duplicate fix","tier":"project",
   "archived":false,"confidence":0.5,"hits":1,"success_count":0,"failure_count":1,
   "ttl_days":90,"promotion_candidate":false,"created_at":"2026-01-01T00:00:00Z","last_seen":"2026-01-01T00:00:00Z"}
]
EOF
  result=$(conventions_generate_content "$tmpdir")
  rm -rf "$tmpdir"
  count=$(grep -c "same pattern" <<<"$result" || true)
  [ "$count" -eq 1 ]
}
