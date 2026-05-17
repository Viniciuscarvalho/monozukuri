#!/usr/bin/env bats
# test/unit/backlog_list.bats — unit tests for lib/backlog/list.js

setup() {
  REPO_ROOT="$(cd "$(dirname "$BATS_TEST_FILENAME")/../.." && pwd)"
  LIST_JS="$REPO_ROOT/lib/backlog/list.js"
  TMP_DIR="$(mktemp -d)"
  BACKLOG="$TMP_DIR/backlog.json"
}

teardown() {
  rm -rf "$TMP_DIR"
}

_write_backlog() {
  cat > "$BACKLOG" <<'JSON'
[
  {
    "id": "low-old",
    "priority": "low",
    "effort": "S",
    "status": "backlog",
    "title": "Low old item",
    "labels": ["docs"],
    "agents": ["gemini"],
    "created_at": "2026-01-01T00:00:00Z"
  },
  {
    "id": "high-new",
    "priority": "high",
    "effort": "M",
    "status": "ready",
    "title": "High new item",
    "labels": ["cli", "ux"],
    "agents": ["codex", "claude-code"],
    "created_at": "2026-03-01T00:00:00Z"
  },
  {
    "id": "high-old",
    "priority": "high",
    "effort": "L",
    "status": "blocked",
    "title": "High old item with a title that is intentionally longer than sixty characters for truncation",
    "labels": ["cli"],
    "agents": ["codex"],
    "created_at": "2026-02-01T00:00:00Z"
  },
  {
    "id": "medium",
    "priority": "medium",
    "effort": "S",
    "status": "done",
    "title": "Medium item",
    "labels": ["docs"],
    "agents": ["claude-code"],
    "created_at": "2026-01-15T00:00:00Z"
  },
  {
    "id": "wip-agentless",
    "priority": "medium",
    "effort": "M",
    "status": "in-progress",
    "title": "In progress item",
    "labels": ["ops"],
    "created_at": "2026-01-20T00:00:00Z"
  }
]
JSON
}

_ids_from_json() {
  node -e "const d=JSON.parse(require('fs').readFileSync(0,'utf8')); console.log(d.map(i=>i.id).join(','));"
}

@test "backlog list ranks default ready items by priority desc then age asc" {
  _write_backlog
  run node "$LIST_JS" --file "$BACKLOG" --format json
  [ "$status" -eq 0 ]
  ids=$(printf '%s' "$output" | _ids_from_json)
  [ "$ids" = "high-new,low-old" ]
}

@test "backlog list table prints required columns and truncates title to 60 chars" {
  _write_backlog
  run node "$LIST_JS" --file "$BACKLOG" --format table --status blocked
  [ "$status" -eq 0 ]
  [[ "$output" == *"ID"*"PRIORITY"*"EFFORT"*"STATUS"*"TITLE"* ]]
  [[ "$output" == *"high-old"*"high"*"L"*"blocked"* ]]
  [[ "$output" == *"..."* ]]
}

@test "backlog list supports csv format" {
  _write_backlog
  run node "$LIST_JS" --file "$BACKLOG" --format csv --limit 2
  [ "$status" -eq 0 ]
  [ "$(printf '%s\n' "$output" | wc -l | tr -d ' ')" -eq 3 ]
  [[ "$output" == id,priority,effort,status,title* ]]
}

@test "backlog list filters by label with OR semantics" {
  _write_backlog
  run node "$LIST_JS" --file "$BACKLOG" --format json --label docs,ux
  [ "$status" -eq 0 ]
  ids=$(printf '%s' "$output" | _ids_from_json)
  [ "$ids" = "high-new,low-old" ]
}

@test "backlog list filters by status" {
  _write_backlog
  run node "$LIST_JS" --file "$BACKLOG" --format json --status done
  [ "$status" -eq 0 ]
  ids=$(printf '%s' "$output" | _ids_from_json)
  [ "$ids" = "medium" ]
}

@test "backlog list excludes blocked through ready shortcut" {
  _write_backlog
  run node "$LIST_JS" --file "$BACKLOG" --format json --exclude-blocked
  [ "$status" -eq 0 ]
  ids=$(printf '%s' "$output" | _ids_from_json)
  [ "$ids" = "high-new,low-old" ]
}

@test "backlog list filters by compatible agent" {
  _write_backlog
  run node "$LIST_JS" --file "$BACKLOG" --format json --agent codex
  [ "$status" -eq 0 ]
  ids=$(printf '%s' "$output" | _ids_from_json)
  [ "$ids" = "high-new" ]
}

@test "backlog list combines label and agent filters with AND" {
  _write_backlog
  run node "$LIST_JS" --file "$BACKLOG" --format json --label docs,cli --agent codex
  [ "$status" -eq 0 ]
  ids=$(printf '%s' "$output" | _ids_from_json)
  [ "$ids" = "high-new" ]
}

@test "backlog list combines status and label filters with AND" {
  _write_backlog
  run node "$LIST_JS" --file "$BACKLOG" --format json --status done --label docs
  [ "$status" -eq 0 ]
  ids=$(printf '%s' "$output" | _ids_from_json)
  [ "$ids" = "medium" ]
}

@test "backlog list returns success and friendly message for no matches" {
  _write_backlog
  run node "$LIST_JS" --file "$BACKLOG" --label nonexistent
  [ "$status" -eq 0 ]
  [[ "$output" == *"No backlog items match the selected filters"* ]]
}

@test "backlog list enforces max limit 500" {
  _write_backlog
  run node "$LIST_JS" --file "$BACKLOG" --limit 501
  [ "$status" -eq 2 ]
  [[ "$output" == *"Invalid --limit"* ]]
}

@test "backlog list empty table prints init suggestion" {
  printf '[]\n' > "$BACKLOG"
  run node "$LIST_JS" --file "$BACKLOG"
  [ "$status" -eq 0 ]
  [[ "$output" == *"No backlog items found"* ]]
  [[ "$output" == *"monozukuri init"* ]]
}
