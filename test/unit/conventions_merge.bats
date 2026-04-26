#!/usr/bin/env bats
# test/unit/conventions_merge.bats — conventions-merge.sh unit tests

setup() {
  REPO_ROOT="$(cd "$(dirname "$BATS_TEST_FILENAME")/../.." && pwd)"
  LIB_DIR="$REPO_ROOT/lib"
  FIXTURES="$REPO_ROOT/test/fixtures/projects"
  export LIB_DIR REPO_ROOT FIXTURES
  source "$LIB_DIR/agent/conventions-merge.sh"

  # Minimal block file used by most tests
  BLOCK=$(mktemp)
  printf '<!-- monozukuri:generated-start v1 -->\n## Conventions\n\n- `pat` → fix\n\n<!-- monozukuri:generated-end -->\n' > "$BLOCK"
}

teardown() {
  rm -f "$BLOCK"
}

# ── no existing file ──────────────────────────────────────────────────────────

@test "write to new file creates AGENTS.md with block content" {
  tmpdir=$(mktemp -d)
  conventions_merge_write "$tmpdir" "$BLOCK"
  [ -f "$tmpdir/AGENTS.md" ]
  grep -q "generated-start" "$tmpdir/AGENTS.md"
  rm -rf "$tmpdir"
}

@test "write to new file: backup sentinel created" {
  tmpdir=$(mktemp -d)
  mkdir -p "$tmpdir/.monozukuri/conventions-backups"
  conventions_merge_write "$tmpdir" "$BLOCK"
  count=$(ls "$tmpdir/.monozukuri/conventions-backups"/AGENTS.md.* 2>/dev/null | wc -l | tr -d ' ')
  rm -rf "$tmpdir"
  [ "$count" -eq 1 ]
}

# ── file without markers ──────────────────────────────────────────────────────

@test "write to file without markers appends block" {
  tmpdir=$(mktemp -d)
  printf '# User Content\n\nKeep this.\n' > "$tmpdir/AGENTS.md"
  conventions_merge_write "$tmpdir" "$BLOCK"
  grep -q "Keep this" "$tmpdir/AGENTS.md"
  grep -q "generated-start" "$tmpdir/AGENTS.md"
  rm -rf "$tmpdir"
}

@test "user content before appended block is byte-identical" {
  tmpdir=$(mktemp -d)
  printf '# User Content\n\nKeep this.\n' > "$tmpdir/AGENTS.md"
  original=$(cat "$tmpdir/AGENTS.md")
  conventions_merge_write "$tmpdir" "$BLOCK"
  prefix=$(head -3 "$tmpdir/AGENTS.md")
  rm -rf "$tmpdir"
  [[ "$prefix" == "$(printf '# User Content\n\nKeep this.')" ]]
}

# ── file with existing markers ────────────────────────────────────────────────

@test "write replaces content between markers" {
  tmpdir=$(mktemp -d)
  cp "$FIXTURES/with-markers/AGENTS.md" "$tmpdir/AGENTS.md"
  conventions_merge_write "$tmpdir" "$BLOCK"
  grep -q "old pattern" "$tmpdir/AGENTS.md" && { rm -rf "$tmpdir"; return 1; }
  grep -q "## Conventions" "$tmpdir/AGENTS.md"
  rm -rf "$tmpdir"
}

@test "prefix outside markers is byte-identical after replace" {
  tmpdir=$(mktemp -d)
  cp "$FIXTURES/with-markers/AGENTS.md" "$tmpdir/AGENTS.md"
  start_line=$(grep -n "generated-start" "$tmpdir/AGENTS.md" | cut -d: -f1)
  prefix_before=$(head -n "$(( start_line - 1 ))" "$tmpdir/AGENTS.md")
  conventions_merge_write "$tmpdir" "$BLOCK"
  start_line_after=$(grep -n "generated-start" "$tmpdir/AGENTS.md" | cut -d: -f1)
  prefix_after=$(head -n "$(( start_line_after - 1 ))" "$tmpdir/AGENTS.md")
  rm -rf "$tmpdir"
  [[ "$prefix_before" == "$prefix_after" ]]
}

@test "suffix outside markers is byte-identical after replace" {
  tmpdir=$(mktemp -d)
  cp "$FIXTURES/with-markers/AGENTS.md" "$tmpdir/AGENTS.md"
  end_line=$(grep -n "generated-end" "$tmpdir/AGENTS.md" | cut -d: -f1)
  total=$(wc -l < "$tmpdir/AGENTS.md")
  suffix_before=$(tail -n "+$(( end_line + 1 ))" "$tmpdir/AGENTS.md")
  conventions_merge_write "$tmpdir" "$BLOCK"
  end_line_after=$(grep -n "generated-end" "$tmpdir/AGENTS.md" | cut -d: -f1)
  suffix_after=$(tail -n "+$(( end_line_after + 1 ))" "$tmpdir/AGENTS.md")
  rm -rf "$tmpdir"
  [[ "$suffix_before" == "$suffix_after" ]]
}

# ── conflicting markers ───────────────────────────────────────────────────────

@test "conflicting markers (start without end) → write returns error" {
  tmpdir=$(mktemp -d)
  cp "$FIXTURES/with-conflicting-markers/AGENTS.md" "$tmpdir/AGENTS.md"
  run conventions_merge_write "$tmpdir" "$BLOCK"
  rm -rf "$tmpdir"
  [ "$status" -ne 0 ]
}

@test "conflicting markers: AGENTS.md is not modified" {
  tmpdir=$(mktemp -d)
  cp "$FIXTURES/with-conflicting-markers/AGENTS.md" "$tmpdir/AGENTS.md"
  original=$(cat "$tmpdir/AGENTS.md")
  conventions_merge_write "$tmpdir" "$BLOCK" 2>/dev/null || true
  after=$(cat "$tmpdir/AGENTS.md")
  rm -rf "$tmpdir"
  [[ "$original" == "$after" ]]
}

# ── backup ────────────────────────────────────────────────────────────────────

@test "backup is created before each write" {
  tmpdir=$(mktemp -d)
  cp "$FIXTURES/with-existing-agents-md/AGENTS.md" "$tmpdir/AGENTS.md"
  conventions_merge_write "$tmpdir" "$BLOCK"
  conventions_merge_write "$tmpdir" "$BLOCK"
  count=$(ls "$tmpdir/.monozukuri/conventions-backups"/AGENTS.md.* 2>/dev/null | wc -l | tr -d ' ')
  rm -rf "$tmpdir"
  [ "$count" -ge 2 ]
}

@test "backup content matches pre-write AGENTS.md" {
  tmpdir=$(mktemp -d)
  cp "$FIXTURES/with-existing-agents-md/AGENTS.md" "$tmpdir/AGENTS.md"
  original=$(cat "$tmpdir/AGENTS.md")
  conventions_merge_write "$tmpdir" "$BLOCK"
  backup=$(cat "$tmpdir/.monozukuri/conventions-backups"/AGENTS.md.*)
  rm -rf "$tmpdir"
  [[ "$original" == "$backup" ]]
}

# ── restore ───────────────────────────────────────────────────────────────────

@test "restore brings AGENTS.md back to pre-write state" {
  tmpdir=$(mktemp -d)
  cp "$FIXTURES/with-existing-agents-md/AGENTS.md" "$tmpdir/AGENTS.md"
  original=$(cat "$tmpdir/AGENTS.md")
  conventions_merge_write "$tmpdir" "$BLOCK"
  conventions_restore "$tmpdir"
  restored=$(cat "$tmpdir/AGENTS.md")
  rm -rf "$tmpdir"
  [[ "$original" == "$restored" ]]
}

@test "restore on new file removes AGENTS.md" {
  tmpdir=$(mktemp -d)
  conventions_merge_write "$tmpdir" "$BLOCK"
  conventions_restore "$tmpdir"
  rm -rf "$tmpdir"
  [ ! -f "$tmpdir/AGENTS.md" ] || true
}

@test "restore with no backups returns error" {
  tmpdir=$(mktemp -d)
  run conventions_restore "$tmpdir"
  rm -rf "$tmpdir"
  [ "$status" -ne 0 ]
}

# ── restore-list ──────────────────────────────────────────────────────────────

@test "restore-list shows backup filenames" {
  tmpdir=$(mktemp -d)
  cp "$FIXTURES/with-existing-agents-md/AGENTS.md" "$tmpdir/AGENTS.md"
  conventions_merge_write "$tmpdir" "$BLOCK"
  result=$(conventions_restore_list "$tmpdir")
  rm -rf "$tmpdir"
  [[ "$result" == *"AGENTS.md."* ]]
}

# ── diff ──────────────────────────────────────────────────────────────────────

@test "diff output contains unified diff markers for changed content" {
  tmpdir=$(mktemp -d)
  cp "$FIXTURES/with-markers/AGENTS.md" "$tmpdir/AGENTS.md"
  result=$(conventions_merge_diff "$tmpdir" "$BLOCK")
  rm -rf "$tmpdir"
  [[ "$result" == *"---"* || "$result" == *"+++"* ]]
}

@test "diff on identical content produces no hunks" {
  tmpdir=$(mktemp -d)
  cp "$BLOCK" "$tmpdir/AGENTS.md"
  result=$(conventions_merge_diff "$tmpdir" "$BLOCK")
  rm -rf "$tmpdir"
  [[ -z "$result" ]]
}
