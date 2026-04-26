#!/usr/bin/env bats
# test/unit/conventions_parse.bats — unit tests for lib/agent/conventions.sh

setup() {
  REPO_ROOT="$(cd "$(dirname "$BATS_TEST_FILENAME")/../.." && pwd)"
  LIB_DIR="$REPO_ROOT/lib"
  FIXTURES="$REPO_ROOT/test/fixtures/conventions"
  export LIB_DIR FIXTURES REPO_ROOT
  source "$LIB_DIR/agent/conventions.sh"
  unset MONOZUKURI_READ_CONVENTIONS
}

# ── sourcing ──────────────────────────────────────────────────────────────────

@test "conventions.sh sources without error" {
  run bash -c "source '$LIB_DIR/agent/conventions.sh' && echo ok"
  [ "$status" -eq 0 ]
  [[ "$output" == *"ok"* ]]
}

# ── _conventions_parse_file: H2 section splitting ─────────────────────────────

@test "parses AGENTS.md with H2 sections into one record per section" {
  result=$(_conventions_parse_file "$FIXTURES/agents-simple.md" "AGENTS.md")
  jq -e 'length == 3' <<<"$result"
}

@test "each record has required fields" {
  result=$(_conventions_parse_file "$FIXTURES/agents-simple.md" "AGENTS.md")
  jq -e 'all(.[]?; has("tier") and has("kind") and has("summary") and
                   has("body") and has("source") and has("confidence"))' <<<"$result"
}

@test "section summary matches H2 heading text" {
  result=$(_conventions_parse_file "$FIXTURES/agents-simple.md" "AGENTS.md")
  jq -e '.[0].summary == "Build"' <<<"$result"
}

@test "section body contains the convention text" {
  result=$(_conventions_parse_file "$FIXTURES/agents-simple.md" "AGENTS.md")
  jq -e '.[2].body | contains("kysely")' <<<"$result"
}

@test "source.file is the rel_path argument" {
  result=$(_conventions_parse_file "$FIXTURES/agents-simple.md" "AGENTS.md")
  jq -e 'all(.[]?; .source.file == "AGENTS.md")' <<<"$result"
}

@test "confidence is always 1.0" {
  result=$(_conventions_parse_file "$FIXTURES/agents-simple.md" "AGENTS.md")
  jq -e 'all(.[]?; .confidence == 1.0)' <<<"$result"
}

# ── CLAUDE.md: same format, same parse ───────────────────────────────────────

@test "parses CLAUDE.md identically to AGENTS.md (same H2 format)" {
  result=$(_conventions_parse_file "$FIXTURES/claude-md.md" "CLAUDE.md")
  jq -e 'length == 2' <<<"$result"
}

# ── fallback: paragraph splitting ────────────────────────────────────────────

@test "falls back to paragraph splitting for files without H2 sections" {
  result=$(_conventions_parse_file "$FIXTURES/no-sections.md" ".cursorrules")
  jq -e 'length == 3' <<<"$result"
}

@test "paragraph fallback: summary is the first line of the paragraph" {
  result=$(_conventions_parse_file "$FIXTURES/no-sections.md" ".cursorrules")
  jq -e '.[0].summary | contains("kysely")' <<<"$result"
}

# ── malformed / edge cases ────────────────────────────────────────────────────

@test "malformed file (title only, no content) produces [], not abort" {
  result=$(_conventions_parse_file "$FIXTURES/malformed.md" "AGENTS.md")
  jq -e 'length == 0' <<<"$result"
}

@test "missing file produces []" {
  result=$(_conventions_parse_file "/nonexistent/path.md" "AGENTS.md")
  jq -e 'length == 0' <<<"$result"
}

# ── read_project_conventions: scanning and dedup ──────────────────────────────

@test "empty project (no convention files) returns []" {
  result=$(read_project_conventions "$FIXTURES/empty")
  jq -e 'length == 0' <<<"$result"
}

@test "project with AGENTS.md returns conventions from it" {
  result=$(read_project_conventions "$FIXTURES/with-agents-md")
  jq -e 'length == 3' <<<"$result"
}

@test "deduplicates identical H2 headings across AGENTS.md and CLAUDE.md" {
  tmpdir=$(mktemp -d)
  cp "$FIXTURES/agents-simple.md" "$tmpdir/AGENTS.md"
  cp "$FIXTURES/claude-md.md"     "$tmpdir/CLAUDE.md"

  result=$(read_project_conventions "$tmpdir")
  rm -rf "$tmpdir"

  # agents-simple: Build, Test, Database (3)
  # claude-md: Build (dup→dropped), Style (new) → total 4
  jq -e 'length == 4' <<<"$result"
}

@test "dedup is case-insensitive" {
  tmpdir=$(mktemp -d)
  printf '## build\nnpm run build\n' > "$tmpdir/AGENTS.md"
  printf '## Build\nnpm run build\n' > "$tmpdir/CLAUDE.md"

  result=$(read_project_conventions "$tmpdir")
  rm -rf "$tmpdir"

  jq -e 'length == 1' <<<"$result"
}

@test "MONOZUKURI_READ_CONVENTIONS=0 returns [] without scanning" {
  MONOZUKURI_READ_CONVENTIONS=0
  result=$(read_project_conventions "$FIXTURES/with-agents-md")
  [[ "$result" == "[]" ]]
}

# ── conventions_detected_sources ─────────────────────────────────────────────

@test "detected_sources lists AGENTS.md when present" {
  result=$(conventions_detected_sources "$FIXTURES/with-agents-md")
  [[ "$result" == *"AGENTS.md"* ]]
}

@test "detected_sources returns non-zero exit for empty project" {
  run conventions_detected_sources "$FIXTURES/empty"
  [ "$status" -ne 0 ]
}

# ── context_pack_build integration ───────────────────────────────────────────

@test "conventions appear in project_learnings in rendered context pack" {
  source "$LIB_DIR/prompt/context-pack.sh"
  ROOT_DIR="$FIXTURES/with-agents-md"
  tmpout=$(mktemp)
  context_pack_build "feat-test" "$tmpout"
  count=$(jq '.project_learnings | length' "$tmpout")
  rm -f "$tmpout"
  [ "$count" -gt 0 ]
}

@test "project_learnings summaries contain section content (not just headings)" {
  source "$LIB_DIR/prompt/context-pack.sh"
  ROOT_DIR="$FIXTURES/with-agents-md"
  tmpout=$(mktemp)
  context_pack_build "feat-test" "$tmpout"
  result=$(jq '[.project_learnings[].summary] | any(contains("kysely"))' "$tmpout")
  rm -f "$tmpout"
  [[ "$result" == "true" ]]
}

@test "no-convention-file project produces zero project_learnings (regression)" {
  source "$LIB_DIR/prompt/context-pack.sh"
  ROOT_DIR="$FIXTURES/empty"
  LEARNINGS_BLOCK=""
  tmpout=$(mktemp)
  context_pack_build "feat-test" "$tmpout"
  count=$(jq '.project_learnings | length' "$tmpout")
  rm -f "$tmpout"
  [ "$count" -eq 0 ]
}
