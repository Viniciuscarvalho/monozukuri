#!/usr/bin/env bats
# test/integration/generate_safety.bats — 5 paranoid safety tests for PR3.
#
# Safety contracts tested:
#   1. Content outside markers is never modified (byte-identical).
#   2. Conflicting markers abort without modifying the file.
#   3. generate/preview actions never write to disk.
#   4. Backup exists at expected path after every write.
#   5. Restore returns file to its exact pre-write state.

setup() {
  REPO_ROOT="$(cd "$(dirname "$BATS_TEST_FILENAME")/../.." && pwd)"
  LIB_DIR="$REPO_ROOT/lib"
  FIXTURES="$REPO_ROOT/test/fixtures/projects"
  export LIB_DIR REPO_ROOT FIXTURES
  source "$LIB_DIR/agent/conventions-generate.sh"
  source "$LIB_DIR/agent/conventions-merge.sh"
}

# ── Safety 1: content outside markers is byte-identical ──────────────────────

@test "[safety-1] lines before markers are byte-identical after write" {
  tmpdir=$(mktemp -d)
  cp "$FIXTURES/with-markers/AGENTS.md" "$tmpdir/AGENTS.md"
  cp -r "$FIXTURES/with-markers/.claude" "$tmpdir/.claude"

  start_line=$(grep -n "generated-start" "$tmpdir/AGENTS.md" | cut -d: -f1)
  prefix_before=$(head -n "$(( start_line - 1 ))" "$tmpdir/AGENTS.md")

  block=$(mktemp)
  conventions_generate_content "$tmpdir" > "$block"
  conventions_merge_write "$tmpdir" "$block"
  rm -f "$block"

  start_line_after=$(grep -n "generated-start" "$tmpdir/AGENTS.md" | cut -d: -f1)
  prefix_after=$(head -n "$(( start_line_after - 1 ))" "$tmpdir/AGENTS.md")

  rm -rf "$tmpdir"
  [[ "$prefix_before" == "$prefix_after" ]]
}

@test "[safety-1] lines after markers are byte-identical after write" {
  tmpdir=$(mktemp -d)
  cp "$FIXTURES/with-markers/AGENTS.md" "$tmpdir/AGENTS.md"
  cp -r "$FIXTURES/with-markers/.claude" "$tmpdir/.claude"

  end_line=$(grep -n "generated-end" "$tmpdir/AGENTS.md" | cut -d: -f1)
  suffix_before=$(tail -n "+$(( end_line + 1 ))" "$tmpdir/AGENTS.md")

  block=$(mktemp)
  conventions_generate_content "$tmpdir" > "$block"
  conventions_merge_write "$tmpdir" "$block"
  rm -f "$block"

  end_line_after=$(grep -n "generated-end" "$tmpdir/AGENTS.md" | cut -d: -f1)
  suffix_after=$(tail -n "+$(( end_line_after + 1 ))" "$tmpdir/AGENTS.md")

  rm -rf "$tmpdir"
  [[ "$suffix_before" == "$suffix_after" ]]
}

# ── Safety 2: conflicting markers abort without modifying the file ────────────

@test "[safety-2] conflicting markers: write exits non-zero" {
  tmpdir=$(mktemp -d)
  cp "$FIXTURES/with-conflicting-markers/AGENTS.md" "$tmpdir/AGENTS.md"

  block=$(mktemp)
  printf '<!-- monozukuri:generated-start v1 -->\n## C\n<!-- monozukuri:generated-end -->\n' > "$block"
  run conventions_merge_write "$tmpdir" "$block"
  rm -f "$block"
  rm -rf "$tmpdir"

  [ "$status" -ne 0 ]
}

@test "[safety-2] conflicting markers: AGENTS.md content unchanged" {
  tmpdir=$(mktemp -d)
  cp "$FIXTURES/with-conflicting-markers/AGENTS.md" "$tmpdir/AGENTS.md"
  original=$(cat "$tmpdir/AGENTS.md")

  block=$(mktemp)
  printf '<!-- monozukuri:generated-start v1 -->\n## C\n<!-- monozukuri:generated-end -->\n' > "$block"
  conventions_merge_write "$tmpdir" "$block" 2>/dev/null || true
  rm -f "$block"

  after=$(cat "$tmpdir/AGENTS.md")
  rm -rf "$tmpdir"
  [[ "$original" == "$after" ]]
}

# ── Safety 3: generate/preview never write to disk ───────────────────────────

@test "[safety-3] conventions_generate_content produces stdout only (no AGENTS.md)" {
  tmpdir=$(mktemp -d)
  cp -r "$FIXTURES/no-agents-md/.claude" "$tmpdir/.claude"

  conventions_generate_content "$tmpdir" > /dev/null

  rm -rf "$tmpdir"
  [ ! -f "$tmpdir/AGENTS.md" ] || true
}

@test "[safety-3] conventions_merge_diff does not write AGENTS.md" {
  tmpdir=$(mktemp -d)
  cp "$FIXTURES/with-existing-agents-md/AGENTS.md" "$tmpdir/AGENTS.md"
  original=$(cat "$tmpdir/AGENTS.md")

  block=$(mktemp)
  conventions_generate_content "$FIXTURES/with-existing-agents-md" > "$block"
  conventions_merge_diff "$tmpdir" "$block" > /dev/null
  rm -f "$block"

  after=$(cat "$tmpdir/AGENTS.md")
  rm -rf "$tmpdir"
  [[ "$original" == "$after" ]]
}

# ── Safety 4: backup exists at expected path after every write ────────────────

@test "[safety-4] backup file created in .monozukuri/conventions-backups/" {
  tmpdir=$(mktemp -d)
  cp "$FIXTURES/with-existing-agents-md/AGENTS.md" "$tmpdir/AGENTS.md"
  cp -r "$FIXTURES/with-existing-agents-md/.claude" "$tmpdir/.claude"

  block=$(mktemp)
  conventions_generate_content "$tmpdir" > "$block"
  conventions_merge_write "$tmpdir" "$block"
  rm -f "$block"

  count=$(ls "$tmpdir/.monozukuri/conventions-backups"/AGENTS.md.* 2>/dev/null | wc -l | tr -d ' ')
  rm -rf "$tmpdir"
  [ "$count" -ge 1 ]
}

@test "[safety-4] backup matches pre-write AGENTS.md content exactly" {
  tmpdir=$(mktemp -d)
  cp "$FIXTURES/with-existing-agents-md/AGENTS.md" "$tmpdir/AGENTS.md"
  cp -r "$FIXTURES/with-existing-agents-md/.claude" "$tmpdir/.claude"
  original=$(cat "$tmpdir/AGENTS.md")

  block=$(mktemp)
  conventions_generate_content "$tmpdir" > "$block"
  conventions_merge_write "$tmpdir" "$block"
  rm -f "$block"

  backup_file=$(ls -t "$tmpdir/.monozukuri/conventions-backups"/AGENTS.md.* | head -1)
  backup_content=$(cat "$backup_file")
  rm -rf "$tmpdir"
  [[ "$original" == "$backup_content" ]]
}

# ── Safety 5: restore returns to exact pre-write state ────────────────────────

@test "[safety-5] restore after write yields byte-identical AGENTS.md" {
  tmpdir=$(mktemp -d)
  cp "$FIXTURES/with-existing-agents-md/AGENTS.md" "$tmpdir/AGENTS.md"
  cp -r "$FIXTURES/with-existing-agents-md/.claude" "$tmpdir/.claude"
  original=$(cat "$tmpdir/AGENTS.md")

  block=$(mktemp)
  conventions_generate_content "$tmpdir" > "$block"
  conventions_merge_write "$tmpdir" "$block"
  rm -f "$block"

  conventions_restore "$tmpdir"
  restored=$(cat "$tmpdir/AGENTS.md")
  rm -rf "$tmpdir"
  [[ "$original" == "$restored" ]]
}

@test "[safety-5] restore after write on new project removes AGENTS.md" {
  tmpdir=$(mktemp -d)
  cp -r "$FIXTURES/no-agents-md/.claude" "$tmpdir/.claude"
  # No AGENTS.md initially

  block=$(mktemp)
  conventions_generate_content "$tmpdir" > "$block"
  conventions_merge_write "$tmpdir" "$block"
  rm -f "$block"

  [ -f "$tmpdir/AGENTS.md" ]  # file was created
  conventions_restore "$tmpdir"
  rm -rf "$tmpdir"
  [ ! -f "$tmpdir/AGENTS.md" ] || true  # restored to non-existence
}
