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

Body.

## [FEAT] feat-high-old: High priority older feature with a very long title that should be truncated by the list command
- priority: high
- effort: M

Body.

## [FEAT] feat-high-new: High priority newer feature
- priority: high
- effort: L

Body.
EOF
}

@test "monozukuri backlog list prints ranked table by default" {
  _write_features
  run bash "$ORCHESTRATE" backlog list
  [ "$status" -eq 0 ]
  [[ "$output" == *"ID"*"PRIORITY"*"EFFORT"*"STATUS"*"TITLE"* ]]
  first_id=$(printf '%s\n' "$output" | awk 'NR==2 {print $1}')
  [ "$first_id" = "feat-high-old" ]
  [[ "$output" == *"feat-high-new"* ]]
  [[ "$output" == *"feat-low"* ]]
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
