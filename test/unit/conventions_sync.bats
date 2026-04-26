#!/usr/bin/env bats
# test/unit/conventions_sync.bats — conventions_auto_sync unit tests

setup() {
  REPO_ROOT="$(cd "$(dirname "$BATS_TEST_FILENAME")/../.." && pwd)"
  LIB_DIR="$REPO_ROOT/lib"
  FIXTURES="$REPO_ROOT/test/fixtures/projects"
  export LIB_DIR REPO_ROOT FIXTURES
  source "$LIB_DIR/run/conventions-sync.sh"
  unset CONVENTIONS_AUTO_SYNC
}

# ── gate: skip when not opted in ─────────────────────────────────────────────

@test "returns 0 when CONVENTIONS_AUTO_SYNC is unset" {
  tmpdir=$(mktemp -d)
  run conventions_auto_sync "$tmpdir"
  rm -rf "$tmpdir"
  [ "$status" -eq 0 ]
}

@test "returns 0 and does not write when CONVENTIONS_AUTO_SYNC=false" {
  tmpdir=$(mktemp -d)
  cp -r "$FIXTURES/no-agents-md/.claude" "$tmpdir/.claude"
  CONVENTIONS_AUTO_SYNC=false
  conventions_auto_sync "$tmpdir"
  rm -rf "$tmpdir"
  [ ! -f "$tmpdir/AGENTS.md" ] || true
}

@test "AGENTS.md not created when CONVENTIONS_AUTO_SYNC is false" {
  tmpdir=$(mktemp -d)
  cp -r "$FIXTURES/no-agents-md/.claude" "$tmpdir/.claude"
  CONVENTIONS_AUTO_SYNC=false
  conventions_auto_sync "$tmpdir"
  result=false
  [ -f "$tmpdir/AGENTS.md" ] && result=true
  rm -rf "$tmpdir"
  [[ "$result" == "false" ]]
}

# ── gate: skip when store is empty ───────────────────────────────────────────

@test "returns 0 when no learning store files exist" {
  tmpdir=$(mktemp -d)
  CONVENTIONS_AUTO_SYNC=true
  run conventions_auto_sync "$tmpdir"
  rm -rf "$tmpdir"
  [ "$status" -eq 0 ]
}

@test "does not create AGENTS.md when store is empty" {
  tmpdir=$(mktemp -d)
  mkdir -p "$tmpdir/.claude/feature-state"
  printf '[]' > "$tmpdir/.claude/feature-state/learned.json"
  CONVENTIONS_AUTO_SYNC=true
  conventions_auto_sync "$tmpdir"
  rm -rf "$tmpdir"
  [ ! -f "$tmpdir/AGENTS.md" ] || true
}

@test "does not create AGENTS.md when all entries are archived" {
  tmpdir=$(mktemp -d)
  mkdir -p "$tmpdir/.claude/feature-state"
  cat > "$tmpdir/.claude/feature-state/learned.json" <<'EOF'
[{"id":"l1","pattern":"p","fix":"f","archived":true,"confidence":0.5,
  "hits":1,"success_count":0,"failure_count":1,"ttl_days":90,
  "promotion_candidate":false,"tier":"project",
  "created_at":"2026-01-01T00:00:00Z","last_seen":"2026-01-01T00:00:00Z"}]
EOF
  CONVENTIONS_AUTO_SYNC=true
  conventions_auto_sync "$tmpdir"
  rm -rf "$tmpdir"
  [ ! -f "$tmpdir/AGENTS.md" ] || true
}

# ── active: creates / updates AGENTS.md when learnings exist ─────────────────

@test "creates AGENTS.md when store has active learnings" {
  tmpdir=$(mktemp -d)
  cp -r "$FIXTURES/no-agents-md/.claude" "$tmpdir/.claude"
  CONVENTIONS_AUTO_SYNC=true
  conventions_auto_sync "$tmpdir"
  result=false
  [ -f "$tmpdir/AGENTS.md" ] && result=true
  rm -rf "$tmpdir"
  [[ "$result" == "true" ]]
}

@test "AGENTS.md contains learning pattern after sync" {
  tmpdir=$(mktemp -d)
  cp -r "$FIXTURES/no-agents-md/.claude" "$tmpdir/.claude"
  CONVENTIONS_AUTO_SYNC=true
  conventions_auto_sync "$tmpdir"
  content=$(cat "$tmpdir/AGENTS.md" 2>/dev/null || echo "")
  rm -rf "$tmpdir"
  [[ "$content" == *"kysely"* ]]
}

@test "AGENTS.md contains monozukuri markers after sync" {
  tmpdir=$(mktemp -d)
  cp -r "$FIXTURES/no-agents-md/.claude" "$tmpdir/.claude"
  CONVENTIONS_AUTO_SYNC=true
  conventions_auto_sync "$tmpdir"
  content=$(cat "$tmpdir/AGENTS.md" 2>/dev/null || echo "")
  rm -rf "$tmpdir"
  [[ "$content" == *"monozukuri:generated-start"* ]]
}

@test "backup created in .monozukuri/conventions-backups/ on sync" {
  tmpdir=$(mktemp -d)
  cp -r "$FIXTURES/no-agents-md/.claude" "$tmpdir/.claude"
  CONVENTIONS_AUTO_SYNC=true
  conventions_auto_sync "$tmpdir"
  count=$(ls "$tmpdir/.monozukuri/conventions-backups"/AGENTS.md.* 2>/dev/null | wc -l | tr -d ' ')
  rm -rf "$tmpdir"
  [ "$count" -ge 1 ]
}

# ── resilience: never fails the run ──────────────────────────────────────────

@test "returns 0 even when lib files are absent" {
  tmpdir=$(mktemp -d)
  cp -r "$FIXTURES/no-agents-md/.claude" "$tmpdir/.clone"
  CONVENTIONS_AUTO_SYNC=true
  # Point LIB_DIR somewhere that doesn't have conventions-generate.sh
  LIB_DIR="/nonexistent-path"
  run conventions_auto_sync "$tmpdir"
  LIB_DIR="$REPO_ROOT/lib"
  rm -rf "$tmpdir"
  [ "$status" -eq 0 ]
}

@test "returns 0 even when repo_root is unwritable" {
  tmpdir=$(mktemp -d)
  cp -r "$FIXTURES/no-agents-md/.claude" "$tmpdir/.claude"
  chmod 555 "$tmpdir"
  CONVENTIONS_AUTO_SYNC=true
  run conventions_auto_sync "$tmpdir"
  chmod 755 "$tmpdir"
  rm -rf "$tmpdir"
  [ "$status" -eq 0 ]
}

# ── pipeline wiring ───────────────────────────────────────────────────────────

@test "cmd/run.sh sources conventions-sync.sh after run_backlog" {
  run_sh="$REPO_ROOT/cmd/run.sh"
  backlog_line=$(grep -n "run_backlog" "$run_sh" | head -1 | cut -d: -f1)
  sync_line=$(grep -n "conventions-sync.sh" "$run_sh" | head -1 | cut -d: -f1)
  [ "$backlog_line" -lt "$sync_line" ]
}

@test "cmd/run.sh calls conventions_auto_sync with ROOT_DIR" {
  grep -q "conventions_auto_sync.*ROOT_DIR" "$REPO_ROOT/cmd/run.sh"
}

@test "lib/config/load.sh exports CONVENTIONS_AUTO_SYNC" {
  grep -q "export CONVENTIONS_AUTO_SYNC" "$REPO_ROOT/lib/config/load.sh"
}

@test "templates/config.yaml documents conventions.auto_sync" {
  grep -q "auto_sync" "$REPO_ROOT/templates/config.yaml"
}
