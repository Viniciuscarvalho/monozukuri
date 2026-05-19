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
