#!/usr/bin/env bats
# test/integration/backlog_list.bats — end-to-end backlog list command tests

setup() {
  REPO_ROOT="$(cd "$(dirname "$BATS_TEST_FILENAME")/../.." && pwd)"
  ORCHESTRATE="$REPO_ROOT/orchestrate.sh"
  TMP_PROJECT="$(mktemp -d)"
  export MONOZUKURI_HOME="$REPO_ROOT"

  cd "$TMP_PROJECT"
  git init -b main -q 2>/dev/null || git init -q
  git config user.email test@example.com
  git config user.name "Test"
  mkdir -p .monozukuri
  cat > .monozukuri/config.yaml <<'YAML'
source:
  adapter: markdown
  markdown:
    file: features.md
  output: orchestration-backlog.json
autonomy: checkpoint
execution:
  base_branch: main
YAML
}

teardown() {
  rm -rf "$TMP_PROJECT"
}

_write_features() {
  cat > features.md <<'EOF'
# Backlog

## [FEAT] feat-low: Low priority feature
- priority: low
- effort: S
- labels: docs
- agents: gemini

Body.

## [FEAT] feat-high-old: High priority older feature with a very long title that should be truncated by the list command
- priority: high
- effort: M
- labels: cli, ux
- agents: codex, claude-code

Body.

## [FEAT] feat-high-new: High priority newer feature
- priority: high
- effort: L
- labels: cli
- agents: claude-code

Body.

## [BLOCKED] feat-blocked: Blocked feature
- priority: high
- effort: L
- labels: ops
- agents: codex

Body.

## [WIP] feat-wip: In progress feature
- priority: medium
- effort: M
- labels: ops
- agents: gemini

Body.

## [DONE] feat-done: Done feature
- priority: medium
- effort: S
- labels: docs
- agents: claude-code

Body.
EOF
}

_ids_from_json() {
  node -e "const d=JSON.parse(require('fs').readFileSync(0,'utf8')); console.log(d.map(i=>i.id).join(','));"
}

@test "monozukuri backlog list prints ranked ready table by default" {
  _write_features
  run bash "$ORCHESTRATE" backlog list
  [ "$status" -eq 0 ]
  [[ "$output" == *"ID"*"PRIORITY"*"EFFORT"*"STATUS"*"TITLE"* ]]
  first_id=$(printf '%s\n' "$output" | awk 'NR==2 {print $1}')
  [ "$first_id" = "feat-high-old" ]
  [[ "$output" == *"feat-high-new"* ]]
  [[ "$output" == *"feat-low"* ]]
  [[ "$output" != *"feat-blocked"* ]]
}

@test "monozukuri backlog list supports json and limit" {
  _write_features
  run bash "$ORCHESTRATE" backlog list --format json --limit 2
  [ "$status" -eq 0 ]
  count=$(printf '%s' "$output" | node -e "const d=JSON.parse(require('fs').readFileSync(0,'utf8')); console.log(d.length)")
  [ "$count" -eq 2 ]
}

@test "monozukuri pick emits top ranked JSON for CI scripts" {
  _write_features
  run bash "$ORCHESTRATE" pick --top 2 --json
  [ "$status" -eq 0 ]
  ids=$(printf '%s' "$output" | _ids_from_json)
  [ "$ids" = "feat-high-old,feat-high-new" ]
  node -e '
    const d = JSON.parse(require("fs").readFileSync(0, "utf8"));
    if (d.length !== 2) process.exit(1);
    for (const item of d) {
      const keys = Object.keys(item).sort().join(",");
      if (keys !== "effort,id,priority,score,title") process.exit(2);
    }
  ' <<< "$output"
}

@test "monozukuri pick --json records top selection history" {
  _write_features
  run bash "$ORCHESTRATE" pick --top 2 --json
  [ "$status" -eq 0 ]
  node -e '
    const fs = require("fs");
    const lines = fs.readFileSync(".monozukuri/state/pick-history.jsonl", "utf8").trim().split("\n");
    const entry = JSON.parse(lines.at(-1));
    if (entry.source !== "top") process.exit(1);
    if (entry.ids.join(",") !== "feat-high-old,feat-high-new") process.exit(2);
  '
}

@test "monozukuri pick --top emits ranked IDs without opening TUI" {
  _write_features
  run bash "$ORCHESTRATE" pick --top 2
  [ "$status" -eq 0 ]
  [ "$output" = $'feat-high-old\nfeat-high-new' ]
}

@test "monozukuri pick --top records selection history" {
  _write_features
  run env USER=tester bash "$ORCHESTRATE" pick --top 2
  [ "$status" -eq 0 ]
  [ -f .monozukuri/state/pick-history.jsonl ]
  node -e '
    const fs = require("fs");
    const lines = fs.readFileSync(".monozukuri/state/pick-history.jsonl", "utf8").trim().split("\n");
    const entry = JSON.parse(lines.at(-1));
    if (!entry.timestamp) process.exit(1);
    if (entry.source !== "top") process.exit(2);
    if (entry.user !== "tester") process.exit(3);
    if (entry.ids.join(",") !== "feat-high-old,feat-high-new") process.exit(4);
  '
}

@test "monozukuri pick explicit IDs records selection history" {
  _write_features
  run env USER=tester bash "$ORCHESTRATE" pick feat-high-old feat-low
  [ "$status" -eq 0 ]
  [ "$output" = $'feat-high-old\nfeat-low' ]
  node -e '
    const fs = require("fs");
    const lines = fs.readFileSync(".monozukuri/state/pick-history.jsonl", "utf8").trim().split("\n");
    const entry = JSON.parse(lines.at(-1));
    if (entry.source !== "explicit") process.exit(1);
    if (entry.user !== "tester") process.exit(2);
    if (entry.ids.join(",") !== "feat-high-old,feat-low") process.exit(3);
  '
}

@test "monozukuri pick --replay prints the latest recorded selection" {
  _write_features
  run bash "$ORCHESTRATE" pick --top 2
  [ "$status" -eq 0 ]
  run bash "$ORCHESTRATE" pick --replay
  [ "$status" -eq 0 ]
  [ "$output" = $'feat-high-old\nfeat-high-new' ]
}

@test "monozukuri pick --replay N prints the Nth latest selection" {
  _write_features
  run bash "$ORCHESTRATE" pick --top 2
  [ "$status" -eq 0 ]
  run bash "$ORCHESTRATE" pick --top 3 --label docs
  [ "$status" -eq 0 ]
  run bash "$ORCHESTRATE" pick --replay 2
  [ "$status" -eq 0 ]
  [ "$output" = $'feat-high-old\nfeat-high-new' ]
}

@test "monozukuri pick --history lists recent selections" {
  _write_features
  run env USER=tester bash "$ORCHESTRATE" pick --top 2
  [ "$status" -eq 0 ]
  run bash "$ORCHESTRATE" pick --top 3 --label docs
  [ "$status" -eq 0 ]
  run bash "$ORCHESTRATE" pick --history
  [ "$status" -eq 0 ]
  [[ "$output" == *"WHEN"*"SOURCE"*"USER"*"IDS"* ]]
  [[ "$output" == *"top"*"tester"*"feat-high-old,feat-high-new"* ]]
  [[ "$output" == *"feat-low"* ]]
}

@test "monozukuri pick --history lists only the latest 20 selections" {
  _write_features
  for _ in $(seq 1 21); do
    run bash "$ORCHESTRATE" pick --top 1
    [ "$status" -eq 0 ]
  done
  run bash "$ORCHESTRATE" pick --history
  [ "$status" -eq 0 ]
  row_count=$(printf '%s\n' "$output" | tail -n +2 | wc -l | tr -d ' ')
  [ "$row_count" -eq 20 ]
}

@test "monozukuri pick history rotates at 100 entries" {
  _write_features
  for _ in $(seq 1 101); do
    run bash "$ORCHESTRATE" pick --top 1
    [ "$status" -eq 0 ]
  done
  line_count=$(wc -l < .monozukuri/state/pick-history.jsonl | tr -d ' ')
  [ "$line_count" -eq 100 ]
}

@test "monozukuri pick --top combines with filters" {
  _write_features
  run bash "$ORCHESTRATE" pick --top 3 --label docs
  [ "$status" -eq 0 ]
  [ "$output" = "feat-low" ]
}

@test "monozukuri pick TUI test keys confirm selected IDs on stdout" {
  _write_features
  run env MONOZUKURI_PICK_TEST_KEYS=space,enter bash "$ORCHESTRATE" pick
  [ "$status" -eq 0 ]
  [ "$output" = "feat-high-old" ]
}

@test "monozukuri pick TUI records selection history" {
  _write_features
  run env USER=tester MONOZUKURI_PICK_TEST_KEYS=space,enter bash "$ORCHESTRATE" pick
  [ "$status" -eq 0 ]
  node -e '
    const fs = require("fs");
    const lines = fs.readFileSync(".monozukuri/state/pick-history.jsonl", "utf8").trim().split("\n");
    const entry = JSON.parse(lines.at(-1));
    if (entry.source !== "tui") process.exit(1);
    if (entry.user !== "tester") process.exit(2);
    if (entry.ids.join(",") !== "feat-high-old") process.exit(3);
  '
}

@test "monozukuri pick TUI test keys cancel with exit 130 and empty stdout" {
  _write_features
  run env MONOZUKURI_PICK_TEST_KEYS=q bash "$ORCHESTRATE" pick
  [ "$status" -eq 130 ]
  [ "$output" = "" ]
}

@test "monozukuri pick without TTY suggests json mode" {
  _write_features
  run bash "$ORCHESTRATE" pick
  [ "$status" -eq 2 ]
  [[ "$output" == *"Interactive pick requires a TTY"* ]]
  [[ "$output" == *"monozukuri pick --json"* ]]
}

@test "monozukuri pick accepts SEL-02 filters" {
  _write_features
  run bash "$ORCHESTRATE" pick --json --top 5 --label cli,docs --agent codex
  [ "$status" -eq 0 ]
  ids=$(printf '%s' "$output" | _ids_from_json)
  [ "$ids" = "feat-high-old" ]
}

@test "monozukuri pick returns empty array and exit 0 for no matches" {
  _write_features
  run bash "$ORCHESTRATE" pick --json --label missing
  [ "$status" -eq 0 ]
  [ "$output" = "[]" ]
}

@test "monozukuri pick rejects top above 50" {
  _write_features
  run bash "$ORCHESTRATE" pick --json --top 51
  [ "$status" -eq 2 ]
  [[ "$output" == *"Invalid --top"* ]]
}

@test "README pick pipe example is valid" {
  _write_features
  run bash -c "bash '$ORCHESTRATE' pick --top 3 --json | jq '.[].id'"
  [ "$status" -eq 0 ]
  [[ "$output" == *"feat-high-old"* ]]
  [[ "$output" == *"feat-high-new"* ]]
}

@test "monozukuri backlog list supports csv format" {
  _write_features
  run bash "$ORCHESTRATE" backlog list --format csv --limit 1
  [ "$status" -eq 0 ]
  [[ "$output" == id,priority,effort,status,title* ]]
  [ "$(printf '%s\n' "$output" | wc -l | tr -d ' ')" -eq 2 ]
}

@test "monozukuri backlog list uses scoring weights from config" {
  _write_features
  cat >> .monozukuri/config.yaml <<'YAML'
scoring:
  priority_weight: 0
  age_weight: 0
  effort_weight: 10
YAML
  run bash "$ORCHESTRATE" backlog list --format json
  [ "$status" -eq 0 ]
  ids=$(printf '%s' "$output" | _ids_from_json)
  first=${ids%%,*}
  [ "$first" = "feat-low" ]
}

@test "monozukuri backlog list score-explain prints calculation breakdown" {
  _write_features
  run bash "$ORCHESTRATE" backlog list --score-explain feat-high-old
  [ "$status" -eq 0 ]
  [[ "$output" == *"ID: feat-high-old"* ]]
  [[ "$output" == *"Formula:"* ]]
  [[ "$output" == *"Priority:"* ]]
  [[ "$output" == *"Effort:"* ]]
}

@test "monozukuri backlog list filters by label with OR semantics" {
  _write_features
  run bash "$ORCHESTRATE" backlog list --format json --label docs,ux
  [ "$status" -eq 0 ]
  ids=$(printf '%s' "$output" | _ids_from_json)
  [ "$ids" = "feat-high-old,feat-low" ]
}

@test "monozukuri backlog list filters by status" {
  _write_features
  run bash "$ORCHESTRATE" backlog list --format json --status blocked
  [ "$status" -eq 0 ]
  ids=$(printf '%s' "$output" | _ids_from_json)
  [ "$ids" = "feat-blocked" ]
}

@test "monozukuri backlog list excludes blocked through ready shortcut" {
  _write_features
  run bash "$ORCHESTRATE" backlog list --format json --exclude-blocked
  [ "$status" -eq 0 ]
  ids=$(printf '%s' "$output" | _ids_from_json)
  [ "$ids" = "feat-high-old,feat-high-new,feat-low" ]
}

@test "monozukuri backlog list filters by compatible agent" {
  _write_features
  run bash "$ORCHESTRATE" backlog list --format json --agent codex
  [ "$status" -eq 0 ]
  ids=$(printf '%s' "$output" | _ids_from_json)
  [ "$ids" = "feat-high-old" ]
}

@test "monozukuri backlog list combines label and agent filters with AND" {
  _write_features
  run bash "$ORCHESTRATE" backlog list --format json --label cli --agent codex
  [ "$status" -eq 0 ]
  ids=$(printf '%s' "$output" | _ids_from_json)
  [ "$ids" = "feat-high-old" ]
}

@test "monozukuri backlog list combines status and label filters with AND" {
  _write_features
  run bash "$ORCHESTRATE" backlog list --format json --status done --label docs
  [ "$status" -eq 0 ]
  ids=$(printf '%s' "$output" | _ids_from_json)
  [ "$ids" = "feat-done" ]
}

@test "monozukuri backlog list returns success and friendly message for no matches" {
  _write_features
  run bash "$ORCHESTRATE" backlog list --label missing
  [ "$status" -eq 0 ]
  [[ "$output" == *"No backlog items match the selected filters"* ]]
}

@test "monozukuri backlog list rejects invalid limit" {
  _write_features
  run bash "$ORCHESTRATE" backlog list --limit 501
  [ "$status" -eq 2 ]
  [[ "$output" == *"Invalid --limit"* ]]
}

@test "monozukuri backlog list handles empty backlog with init suggestion" {
  printf '# Empty\n' > features.md
  run bash "$ORCHESTRATE" backlog list
  [ "$status" -eq 0 ]
  [[ "$output" == *"No backlog items found"* ]]
  [[ "$output" == *"monozukuri init"* ]]
}
