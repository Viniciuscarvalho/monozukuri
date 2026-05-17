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
    "created_at": "2026-01-01T00:00:00Z"
  },
  {
    "id": "high-new",
    "priority": "high",
    "effort": "M",
    "status": "backlog",
    "title": "High new item",
    "created_at": "2026-03-01T00:00:00Z"
  },
  {
    "id": "high-old",
    "priority": "high",
    "effort": "L",
    "status": "blocked",
    "title": "High old item with a title that is intentionally longer than sixty characters for truncation",
    "created_at": "2026-02-01T00:00:00Z"
  },
  {
    "id": "medium",
    "priority": "medium",
    "effort": "S",
    "status": "done",
    "title": "Medium item",
    "created_at": "2026-01-15T00:00:00Z"
  }
]
JSON
}

@test "backlog list ranks by priority desc then age asc" {
  _write_backlog
  run node "$LIST_JS" --file "$BACKLOG" --format json
  [ "$status" -eq 0 ]
  first=$(printf '%s' "$output" | node -e "const d=JSON.parse(require('fs').readFileSync(0,'utf8')); console.log(d.map(i=>i.id).join(','));")
  [ "$first" = "high-old,high-new,medium,low-old" ]
}

@test "backlog list table prints required columns and truncates title to 60 chars" {
  _write_backlog
  run node "$LIST_JS" --file "$BACKLOG" --format table
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
