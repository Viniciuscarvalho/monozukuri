#!/usr/bin/env bats
# test/unit/conventions_promote.bats — conventions_promote unit tests

setup() {
  REPO_ROOT="$(cd "$(dirname "$BATS_TEST_FILENAME")/../.." && pwd)"
  LIB_DIR="$REPO_ROOT/lib"
  FIXTURES="$REPO_ROOT/test/fixtures/projects"
  export LIB_DIR REPO_ROOT FIXTURES
  source "$LIB_DIR/agent/conventions-promote.sh"
}

# ── conventions_list_candidates ───────────────────────────────────────────────

@test "returns empty array when no learning store exists" {
  tmpdir=$(mktemp -d)
  result=$(conventions_list_candidates "$tmpdir")
  rm -rf "$tmpdir"
  [[ "$result" == "[]" ]]
}

@test "returns empty array when all entries are archived" {
  tmpdir=$(mktemp -d)
  mkdir -p "$tmpdir/.claude/feature-state"
  cat > "$tmpdir/.claude/feature-state/learned.json" <<'EOF'
[{"id":"l1","pattern":"p","fix":"f","archived":true,"confidence":0.9,
  "hits":5,"success_count":4,"failure_count":1,"ttl_days":90,
  "promotion_candidate":true,"tier":"project",
  "created_at":"2026-01-01T00:00:00Z","last_seen":"2026-01-01T00:00:00Z"}]
EOF
  result=$(conventions_list_candidates "$tmpdir")
  rm -rf "$tmpdir"
  [[ "$result" == "[]" ]]
}

@test "returns empty array when no entries are promotion candidates" {
  tmpdir=$(mktemp -d)
  mkdir -p "$tmpdir/.claude/feature-state"
  cat > "$tmpdir/.claude/feature-state/learned.json" <<'EOF'
[{"id":"l1","pattern":"some error","fix":"some fix","archived":false,"confidence":0.6,
  "hits":2,"success_count":1,"failure_count":1,"ttl_days":90,
  "promotion_candidate":false,"tier":"project",
  "created_at":"2026-01-01T00:00:00Z","last_seen":"2026-01-01T00:00:00Z"}]
EOF
  result=$(conventions_list_candidates "$tmpdir")
  rm -rf "$tmpdir"
  [[ "$result" == "[]" ]]
}

@test "returns one record for each promotion candidate" {
  result=$(conventions_list_candidates "$FIXTURES/no-agents-md")
  count=$(jq 'length' <<<"$result")
  [[ "$count" -eq 1 ]]
}

@test "candidate record has kind=convention" {
  result=$(conventions_list_candidates "$FIXTURES/no-agents-md")
  kind=$(jq -r '.[0].kind' <<<"$result")
  [[ "$kind" == "convention" ]]
}

@test "candidate record summary matches pattern" {
  result=$(conventions_list_candidates "$FIXTURES/no-agents-md")
  summary=$(jq -r '.[0].summary' <<<"$result")
  [[ "$summary" == *"kysely migration"* ]]
}

@test "candidate record body contains fix text" {
  result=$(conventions_list_candidates "$FIXTURES/no-agents-md")
  body=$(jq -r '.[0].body' <<<"$result")
  [[ "$body" == *"defaultTo(null)"* ]]
}

@test "candidate record source file references learning-store" {
  result=$(conventions_list_candidates "$FIXTURES/no-agents-md")
  source_file=$(jq -r '.[0].source.file' <<<"$result")
  [[ "$source_file" == "learning-store:"* ]]
}

@test "candidate record confidence matches learning entry" {
  result=$(conventions_list_candidates "$FIXTURES/no-agents-md")
  confidence=$(jq '.[0].confidence' <<<"$result")
  [[ "$confidence" == "0.8" ]]
}

@test "deduplicates candidates with same pattern across tiers" {
  tmpdir=$(mktemp -d)
  mkdir -p "$tmpdir/.claude/feature-state"
  # Same pattern in project tier
  cat > "$tmpdir/.claude/feature-state/learned.json" <<'EOF'
[{"id":"l1","pattern":"duplicate pattern","fix":"fix a","archived":false,"confidence":0.9,
  "hits":5,"success_count":4,"failure_count":1,"ttl_days":90,
  "promotion_candidate":true,"tier":"project",
  "created_at":"2026-01-01T00:00:00Z","last_seen":"2026-01-01T00:00:00Z"}]
EOF
  # Same pattern in global tier (simulate via HOME override)
  local old_home="$HOME"
  local fake_home; fake_home=$(mktemp -d)
  mkdir -p "$fake_home/.claude/monozukuri/learned"
  cat > "$fake_home/.claude/monozukuri/learned/learned.json" <<'EOF'
[{"id":"l2","pattern":"duplicate pattern","fix":"fix b","archived":false,"confidence":0.85,
  "hits":4,"success_count":3,"failure_count":1,"ttl_days":90,
  "promotion_candidate":true,"tier":"global",
  "created_at":"2026-01-01T00:00:00Z","last_seen":"2026-01-01T00:00:00Z"}]
EOF
  HOME="$fake_home" result=$(conventions_list_candidates "$tmpdir")
  count=$(jq 'length' <<<"$result")
  HOME="$old_home"
  rm -rf "$tmpdir" "$fake_home"
  [[ "$count" -eq 1 ]]
}

# ── conventions_write_promoted ────────────────────────────────────────────────

@test "returns 1 when learn_id not found" {
  tmpdir=$(mktemp -d)
  mkdir -p "$tmpdir/.claude/feature-state"
  printf '[]' > "$tmpdir/.claude/feature-state/learned.json"
  run conventions_write_promoted "$tmpdir" "learn-nonexistent"
  rm -rf "$tmpdir"
  [ "$status" -eq 1 ]
}

@test "returns 1 when entry is not a promotion candidate" {
  tmpdir=$(mktemp -d)
  mkdir -p "$tmpdir/.claude/feature-state"
  cat > "$tmpdir/.claude/feature-state/learned.json" <<'EOF'
[{"id":"learn-notcand","pattern":"p","fix":"f","archived":false,"confidence":0.6,
  "hits":2,"success_count":1,"failure_count":1,"ttl_days":90,
  "promotion_candidate":false,"tier":"project",
  "created_at":"2026-01-01T00:00:00Z","last_seen":"2026-01-01T00:00:00Z"}]
EOF
  run conventions_write_promoted "$tmpdir" "learn-notcand"
  rm -rf "$tmpdir"
  [ "$status" -eq 1 ]
}

@test "creates AGENTS.md when it does not exist" {
  tmpdir=$(mktemp -d)
  cp -r "$FIXTURES/no-agents-md/.claude" "$tmpdir/.claude"
  conventions_write_promoted "$tmpdir" "learn-a1b2c3"
  result=false
  [ -f "$tmpdir/AGENTS.md" ] && result=true
  rm -rf "$tmpdir"
  [[ "$result" == "true" ]]
}

@test "AGENTS.md contains the pattern heading after promote" {
  tmpdir=$(mktemp -d)
  cp -r "$FIXTURES/no-agents-md/.claude" "$tmpdir/.claude"
  conventions_write_promoted "$tmpdir" "learn-a1b2c3"
  content=$(cat "$tmpdir/AGENTS.md")
  rm -rf "$tmpdir"
  [[ "$content" == *"kysely migration"* ]]
}

@test "AGENTS.md contains the fix text after promote" {
  tmpdir=$(mktemp -d)
  cp -r "$FIXTURES/no-agents-md/.claude" "$tmpdir/.claude"
  conventions_write_promoted "$tmpdir" "learn-a1b2c3"
  content=$(cat "$tmpdir/AGENTS.md")
  rm -rf "$tmpdir"
  [[ "$content" == *"defaultTo(null)"* ]]
}

@test "AGENTS.md contains promoted marker comment" {
  tmpdir=$(mktemp -d)
  cp -r "$FIXTURES/no-agents-md/.claude" "$tmpdir/.claude"
  conventions_write_promoted "$tmpdir" "learn-a1b2c3"
  content=$(cat "$tmpdir/AGENTS.md")
  rm -rf "$tmpdir"
  [[ "$content" == *"promoted from learning-store:learn-a1b2c3"* ]]
}

@test "backup file created in .monozukuri/conventions-backups/" {
  tmpdir=$(mktemp -d)
  cp -r "$FIXTURES/no-agents-md/.claude" "$tmpdir/.claude"
  conventions_write_promoted "$tmpdir" "learn-a1b2c3"
  count=$(ls "$tmpdir/.monozukuri/conventions-backups"/AGENTS.md.* 2>/dev/null | wc -l | tr -d ' ')
  rm -rf "$tmpdir"
  [ "$count" -ge 1 ]
}

@test "marks entry promotion_candidate=false after write" {
  tmpdir=$(mktemp -d)
  cp -r "$FIXTURES/no-agents-md/.claude" "$tmpdir/.claude"
  conventions_write_promoted "$tmpdir" "learn-a1b2c3"
  still_candidate=$(jq '[.[] | select(.id == "learn-a1b2c3")] | .[0].promotion_candidate' \
    "$tmpdir/.claude/feature-state/learned.json")
  rm -rf "$tmpdir"
  [[ "$still_candidate" == "false" ]]
}

@test "promoted section inserted before generated marker block" {
  tmpdir=$(mktemp -d)
  cp -r "$FIXTURES/no-agents-md/.claude" "$tmpdir/.claude"
  # Pre-create AGENTS.md with a generated block
  cat > "$tmpdir/AGENTS.md" <<'EOF'
# Existing content

<!-- monozukuri:generated-start v1 -->
## Conventions

- `old pattern` → old fix
<!-- monozukuri:generated-end -->
EOF
  conventions_write_promoted "$tmpdir" "learn-a1b2c3"
  # The new section should appear before the start marker
  start_line=$(grep -n "generated-start" "$tmpdir/AGENTS.md" | cut -d: -f1)
  heading_line=$(grep -n "kysely migration" "$tmpdir/AGENTS.md" | head -1 | cut -d: -f1)
  rm -rf "$tmpdir"
  [ "$heading_line" -lt "$start_line" ]
}

@test "existing content outside markers is preserved after promote" {
  tmpdir=$(mktemp -d)
  cp -r "$FIXTURES/no-agents-md/.claude" "$tmpdir/.claude"
  cat > "$tmpdir/AGENTS.md" <<'EOF'
# Existing content

<!-- monozukuri:generated-start v1 -->
<!-- monozukuri:generated-end -->
EOF
  conventions_write_promoted "$tmpdir" "learn-a1b2c3"
  content=$(cat "$tmpdir/AGENTS.md")
  rm -rf "$tmpdir"
  [[ "$content" == *"# Existing content"* ]]
}

# ── integration: read_project_conventions includes candidates ─────────────────

@test "read_project_conventions includes candidates when promote module is loaded" {
  source "$LIB_DIR/agent/conventions.sh"
  result=$(read_project_conventions "$FIXTURES/no-agents-md")
  count=$(jq 'length' <<<"$result")
  [[ "$count" -ge 1 ]]
}

@test "convention record from candidate has kind=convention in read_project_conventions" {
  source "$LIB_DIR/agent/conventions.sh"
  result=$(read_project_conventions "$FIXTURES/no-agents-md")
  kinds=$(jq -r '.[].kind' <<<"$result" | sort -u)
  [[ "$kinds" == "convention" ]]
}
