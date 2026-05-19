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

_write_scoring_backlog() {
  cat > "$BACKLOG" <<'JSON'
[
  {
    "id": "dep-done",
    "priority": "low",
    "effort": "S",
    "status": "done",
    "title": "Completed dependency",
    "created_at": "2026-01-01T00:00:00Z"
  },
  {
    "id": "medium-old-small",
    "priority": "medium",
    "effort": "S",
    "status": "ready",
    "title": "Medium old small",
    "created_at": "2026-03-01T00:00:00Z"
  },
  {
    "id": "high-new-xxl",
    "priority": "high",
    "effort": "XXL",
    "status": "ready",
    "title": "High new huge",
    "created_at": "2026-05-01T00:00:00Z"
  },
  {
    "id": "high-blocked",
    "priority": "high",
    "effort": "S",
    "status": "ready",
    "title": "High blocked",
    "dependencies": ["dep-open"],
    "created_at": "2026-01-01T00:00:00Z"
  },
  {
    "id": "dep-open",
    "priority": "low",
    "effort": "S",
    "status": "ready",
    "title": "Open dependency",
    "created_at": "2026-01-01T00:00:00Z"
  },
  {
    "id": "high-ready",
    "priority": "high",
    "effort": "S",
    "status": "ready",
    "title": "High ready",
    "dependencies": ["dep-done"],
    "created_at": "2026-01-01T00:00:00Z"
  },
  {
    "id": "numeric-effort",
    "priority": "medium",
    "effort": "8",
    "status": "ready",
    "title": "Numeric effort",
    "created_at": "2026-05-01T00:00:00Z"
  }
]
JSON
}

@test "backlog list ranks default ready items by priority desc then age asc" {
  _write_backlog
  run node "$LIST_JS" --file "$BACKLOG" --format json
  [ "$status" -eq 0 ]
  ids=$(printf '%s' "$output" | _ids_from_json)
  [ "$ids" = "high-new,low-old" ]
}

@test "backlog list scores priority age and effort with default weights" {
  _write_scoring_backlog
  run env MONOZUKURI_SCORE_NOW=2026-05-18T00:00:00Z node "$LIST_JS" --file "$BACKLOG" --format json
  [ "$status" -eq 0 ]
  ids=$(printf '%s' "$output" | _ids_from_json)
  [[ "$ids" == high-ready,medium-old-small,* ]]
  [[ "$ids" == *",high-new-xxl,"* ]]
}

@test "backlog list sends unsatisfied dependencies to the end" {
  _write_scoring_backlog
  run env MONOZUKURI_SCORE_NOW=2026-05-18T00:00:00Z node "$LIST_JS" --file "$BACKLOG" --format json --limit 20
  [ "$status" -eq 0 ]
  ids=$(printf '%s' "$output" | _ids_from_json)
  [ "${ids##*,}" = "high-blocked" ]
}

@test "backlog pick emits JSON objects with id score priority effort and title" {
  _write_scoring_backlog
  run env MONOZUKURI_SCORE_NOW=2026-05-18T00:00:00Z node "$LIST_JS" --file "$BACKLOG" --pick --top 2
  [ "$status" -eq 0 ]
  node -e '
    const d = JSON.parse(process.argv[1]);
    if (d.length !== 2) process.exit(1);
    for (const item of d) {
      const keys = Object.keys(item).sort().join(",");
      if (keys !== "effort,id,priority,score,title") process.exit(2);
      if (typeof item.score !== "number") process.exit(3);
    }
  ' "$output"
}

@test "backlog pick-card emits rich objects for interactive TUI" {
  _write_scoring_backlog
  run env MONOZUKURI_SCORE_NOW=2026-05-18T00:00:00Z node "$LIST_JS" --file "$BACKLOG" --pick-card --top 1
  [ "$status" -eq 0 ]
  node -e '
    const d = JSON.parse(process.argv[1]);
    if (d.length !== 1) process.exit(1);
    const keys = Object.keys(d[0]).sort().join(",");
    if (keys !== "deps,description,effort,id,priority,score,status,title") process.exit(2);
    if (!Array.isArray(d[0].deps)) process.exit(3);
    if (typeof d[0].description !== "string") process.exit(4);
  ' "$output"
}

@test "backlog pick returns empty JSON array for no matches" {
  _write_scoring_backlog
  run node "$LIST_JS" --file "$BACKLOG" --pick --label missing
  [ "$status" -eq 0 ]
  [ "$output" = "[]" ]
}

@test "backlog pick enforces max top 50" {
  _write_scoring_backlog
  run node "$LIST_JS" --file "$BACKLOG" --pick --top 51
  [ "$status" -eq 2 ]
  [[ "$output" == *"Invalid --top"* ]]
}

@test "backlog list supports numeric effort story points" {
  _write_scoring_backlog
  run env MONOZUKURI_SCORE_NOW=2026-05-18T00:00:00Z node "$LIST_JS" --file "$BACKLOG" --score-explain numeric-effort
  [ "$status" -eq 0 ]
  [[ "$output" == *"Effort: 8 => E=8"* ]]
  [[ "$output" == *"contribution=-16"* ]]
}

@test "backlog list score-explain shows dependency penalty breakdown" {
  _write_scoring_backlog
  run env MONOZUKURI_SCORE_NOW=2026-05-18T00:00:00Z node "$LIST_JS" --file "$BACKLOG" --score-explain high-blocked
  [ "$status" -eq 0 ]
  [[ "$output" == *"Score:"* ]]
  [[ "$output" == *"Formula:"* ]]
  [[ "$output" == *"unsatisfied=dep-open"* ]]
  [[ "$output" == *"penalty=-100"* ]]
}

@test "backlog list accepts custom scoring weights" {
  _write_scoring_backlog
  run env MONOZUKURI_SCORE_NOW=2026-05-18T00:00:00Z \
    MONOZUKURI_SCORING_PRIORITY_WEIGHT=1 \
    MONOZUKURI_SCORING_AGE_WEIGHT=10 \
    MONOZUKURI_SCORING_EFFORT_WEIGHT=1 \
    node "$LIST_JS" --file "$BACKLOG" --format json
  [ "$status" -eq 0 ]
  ids=$(printf '%s' "$output" | _ids_from_json)
  first=${ids%%,*}
  [ "$first" = "high-ready" ]
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
