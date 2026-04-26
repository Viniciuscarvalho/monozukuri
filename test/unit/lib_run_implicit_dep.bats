#!/usr/bin/env bats
# test/unit/lib_run_implicit_dep.bats — unit tests for lib/run/implicit-dep.sh

setup() {
  REPO_ROOT="$(cd "$(dirname "$BATS_TEST_FILENAME")/../.." && pwd)"
  LIB_DIR="$REPO_ROOT/lib"
  export LIB_DIR

  TMPDIR_TEST="$(mktemp -d)"
  ROOT_DIR="$TMPDIR_TEST"
  export TMPDIR_TEST ROOT_DIR

  # Create worktree structure
  WORKTREE_DIR="$ROOT_DIR/.monozukuri/worktrees"
  mkdir -p "$WORKTREE_DIR"

  # Source the module under test
  source "$LIB_DIR/run/implicit-dep.sh"
}

teardown() {
  rm -rf "$TMPDIR_TEST"
}

_create_worktree_state() {
  local feat_id="$1"
  local status="$2"
  shift 2
  local files=("$@")

  local wt_dir="$WORKTREE_DIR/$feat_id"
  mkdir -p "$wt_dir"

  local files_json="["
  local first=1
  for file in "${files[@]}"; do
    [ $first -eq 0 ] && files_json+=","
    files_json+="\"$file\""
    first=0
  done
  files_json+="]"

  cat > "$wt_dir/state.json" <<EOF
{
  "feat_id": "$feat_id",
  "status": "$status",
  "files_likely_touched": $files_json
}
EOF
}

_init_git_worktree() {
  local feat_id="$1"
  local wt_dir="$WORKTREE_DIR/$feat_id"

  # Initialize a minimal git repo for testing git diff
  cd "$wt_dir"
  git init -q
  git config user.email "test@test.com"
  git config user.name "Test"

  # Create base commit
  echo "base" > base.txt
  git add base.txt
  git commit -q -m "base"

  cd "$ROOT_DIR"
}

# ── overlap_check tests ───────────────────────────────────────────────────────

@test "overlap_check: no worktrees returns empty" {
  run overlap_check "feat-001" '["src/auth.ts"]'
  [ "$status" -eq 0 ]
  [ -z "$output" ]
}

@test "overlap_check: no in_progress features returns empty" {
  _create_worktree_state "feat-002" "completed" "src/auth.ts"

  run overlap_check "feat-001" '["src/auth.ts"]'
  [ "$status" -eq 0 ]
  [ -z "$output" ]
}

@test "overlap_check: overlapping files returns feature ID" {
  _create_worktree_state "feat-002" "in_progress" "src/auth.ts" "src/types.ts"

  run overlap_check "feat-001" '["src/auth.ts", "src/profile.ts"]'
  [ "$status" -eq 0 ]
  [[ "$output" == *"feat-002"* ]]
}

@test "overlap_check: disjoint files returns empty" {
  _create_worktree_state "feat-002" "in_progress" "src/profile.ts" "src/settings.ts"

  run overlap_check "feat-001" '["src/auth.ts", "src/types.ts"]'
  [ "$status" -eq 0 ]
  [ -z "$output" ]
}

@test "overlap_check: multiple overlapping features returns all IDs" {
  _create_worktree_state "feat-002" "in_progress" "src/auth.ts"
  _create_worktree_state "feat-003" "in_progress" "src/auth.ts"
  _create_worktree_state "feat-004" "in_progress" "src/profile.ts"  # no overlap

  run overlap_check "feat-001" '["src/auth.ts"]'
  [ "$status" -eq 0 ]
  [[ "$output" == *"feat-002"* ]]
  [[ "$output" == *"feat-003"* ]]
  [[ "$output" != *"feat-004"* ]]
}

@test "overlap_check: excludes self from check" {
  _create_worktree_state "feat-001" "in_progress" "src/auth.ts"
  _create_worktree_state "feat-002" "in_progress" "src/auth.ts"

  run overlap_check "feat-001" '["src/auth.ts"]'
  [ "$status" -eq 0 ]
  [[ "$output" == *"feat-002"* ]]
  [[ "$output" != *"feat-001"* ]]
}

@test "overlap_check: empty files array returns empty" {
  _create_worktree_state "feat-002" "in_progress" "src/auth.ts"

  run overlap_check "feat-001" '[]'
  [ "$status" -eq 0 ]
  [ -z "$output" ]
}

@test "overlap_check: null files returns empty" {
  _create_worktree_state "feat-002" "in_progress" "src/auth.ts"

  run overlap_check "feat-001" 'null'
  [ "$status" -eq 0 ]
  [ -z "$output" ]
}

@test "overlap_check: missing state.json treated as no files" {
  mkdir -p "$WORKTREE_DIR/feat-002"
  # No state.json created

  run overlap_check "feat-001" '["src/auth.ts"]'
  [ "$status" -eq 0 ]
  [ -z "$output" ]
}

# ── capture_actual_files tests ────────────────────────────────────────────────

@test "capture_actual_files: populates state.json with actual files" {
  _create_worktree_state "feat-001" "in_progress" "src/auth.ts"
  _init_git_worktree "feat-001"

  local wt_dir="$WORKTREE_DIR/feat-001"
  cd "$wt_dir"

  # Get base SHA
  local base_sha
  base_sha=$(git rev-parse HEAD)

  # Make changes
  mkdir -p src
  echo "new" > src/auth.ts
  git add src/auth.ts
  git commit -q -m "update auth"

  cd "$ROOT_DIR"

  run capture_actual_files "feat-001" "$base_sha"
  [ "$status" -eq 0 ]

  # Check state.json was updated
  local actual_files
  actual_files=$(node -e "
    const state = JSON.parse(require('fs').readFileSync('$wt_dir/state.json', 'utf-8'));
    console.log(JSON.stringify(state.files_actually_touched));
  ")
  [[ "$actual_files" == *"src/auth.ts"* ]]
}

@test "capture_actual_files: computes overlap stats correctly" {
  _create_worktree_state "feat-001" "in_progress" "src/auth.ts" "src/types.ts"
  _init_git_worktree "feat-001"

  local wt_dir="$WORKTREE_DIR/feat-001"
  cd "$wt_dir"

  local base_sha
  base_sha=$(git rev-parse HEAD)

  # Touch only one predicted file + one unpredicted file
  mkdir -p src
  echo "new" > src/auth.ts
  echo "new" > src/profile.ts
  git add src/auth.ts src/profile.ts
  git commit -q -m "update"

  cd "$ROOT_DIR"

  run capture_actual_files "feat-001" "$base_sha"
  [ "$status" -eq 0 ]

  # Check stats
  local stats
  stats=$(node -e "
    const state = JSON.parse(require('fs').readFileSync('$wt_dir/state.json', 'utf-8'));
    console.log(JSON.stringify(state.overlap_stats));
  ")

  [[ "$stats" == *'"predicted":2'* ]]  # 2 files predicted
  [[ "$stats" == *'"actual":2'* ]]     # 2 files actually touched
  [[ "$stats" == *'"confirmed":1'* ]]  # 1 file in both sets (auth.ts)
  [[ "$stats" == *'"false_positives":1'* ]]  # types.ts predicted but not touched
  [[ "$stats" == *'"false_negatives":1'* ]]  # profile.ts touched but not predicted
}

@test "capture_actual_files: handles empty git diff" {
  _create_worktree_state "feat-001" "in_progress" "src/auth.ts"
  _init_git_worktree "feat-001"

  local wt_dir="$WORKTREE_DIR/feat-001"
  cd "$wt_dir"

  local base_sha
  base_sha=$(git rev-parse HEAD)

  # No changes made

  cd "$ROOT_DIR"

  run capture_actual_files "feat-001" "$base_sha"
  [ "$status" -eq 0 ]
  [[ "$output" == *"no files changed"* ]]

  # Should still have stats
  local stats
  stats=$(node -e "
    const state = JSON.parse(require('fs').readFileSync('$wt_dir/state.json', 'utf-8'));
    console.log(JSON.stringify(state.overlap_stats));
  ")
  [[ "$stats" == *'"actual":0'* ]]
}

@test "capture_actual_files: missing worktree fails gracefully" {
  run capture_actual_files "feat-nonexistent" "abc123"
  [ "$status" -eq 1 ]
  [[ "$output" == *"worktree not found"* ]]
}

@test "capture_actual_files: perfect prediction has zero false positives/negatives" {
  _create_worktree_state "feat-001" "in_progress" "src/auth.ts" "src/types.ts"
  _init_git_worktree "feat-001"

  local wt_dir="$WORKTREE_DIR/feat-001"
  cd "$wt_dir"

  local base_sha
  base_sha=$(git rev-parse HEAD)

  # Touch exactly predicted files
  mkdir -p src
  echo "new" > src/auth.ts
  echo "new" > src/types.ts
  git add src/auth.ts src/types.ts
  git commit -q -m "update"

  cd "$ROOT_DIR"

  run capture_actual_files "feat-001" "$base_sha"
  [ "$status" -eq 0 ]

  local stats
  stats=$(node -e "
    const state = JSON.parse(require('fs').readFileSync('$wt_dir/state.json', 'utf-8'));
    console.log(JSON.stringify(state.overlap_stats));
  ")

  [[ "$stats" == *'"false_positives":0'* ]]
  [[ "$stats" == *'"false_negatives":0'* ]]
  [[ "$stats" == *'"confirmed":2'* ]]
}
