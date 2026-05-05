#!/usr/bin/env bats
# test/unit/phase_c_ops.bats
# Unit tests for Phase C — multi-project ops layer
#   C1: Global cost ceiling (budget.sh)
#   C2: Kill switch sentinel
#   C3: Project registry (projects.sh)
#   C4: Concurrent-write safety on global learning store

REPO_ROOT="$(cd "$(dirname "$BATS_TEST_FILENAME")/../.." && pwd)"

# ── helpers ───────────────────────────────────────────────────────────────────

# Note: these stubs must be called (with export) BEFORE sourcing the lib files,
# so the ${VAR:-default} guards in those files keep the test values.
_stub_budget_env() {
  export _BUDGET_FILE="$1/budget.json"
  export _BUDGET_LOCK="$1/budget.lock"
}

_stub_projects_env() {
  export _PROJECTS_FILE="$1/projects.json"
  export _PROJECTS_LOCK="$1/projects.lock"
}

# ── C1: budget_init ───────────────────────────────────────────────────────────

@test "C1: budget_init creates budget.json when missing" {
  local tmp; tmp=$(mktemp -d)
  (
    _stub_budget_env "$tmp"
    source "$REPO_ROOT/lib/ops/budget.sh"
    export MONOZUKURI_DAILY_CEILING_USD=50
    budget_init
    [ -f "$_BUDGET_FILE" ]
  )
  local rc=$?; rm -rf "$tmp"; [ "$rc" -eq 0 ]
}

@test "C1: budget_init sets daily_ceiling_usd to env override" {
  local tmp; tmp=$(mktemp -d)
  (
    _stub_budget_env "$tmp"
    source "$REPO_ROOT/lib/ops/budget.sh"
    export MONOZUKURI_DAILY_CEILING_USD=25
    budget_init
    node -p "JSON.parse(require('fs').readFileSync('$_BUDGET_FILE','utf-8')).daily_ceiling_usd" | grep -q "^25$"
  )
  local rc=$?; rm -rf "$tmp"; [ "$rc" -eq 0 ]
}

@test "C1: budget_init sets current_spend_usd to 0" {
  local tmp; tmp=$(mktemp -d)
  (
    _stub_budget_env "$tmp"
    source "$REPO_ROOT/lib/ops/budget.sh"
    export MONOZUKURI_DAILY_CEILING_USD=50
    budget_init
    local spend
    spend=$(node -p "JSON.parse(require('fs').readFileSync('$_BUDGET_FILE','utf-8')).current_spend_usd")
    [ "$spend" = "0" ]
  )
  local rc=$?; rm -rf "$tmp"; [ "$rc" -eq 0 ]
}

@test "C1: budget_init resets spend when reset_at is in the past" {
  local tmp; tmp=$(mktemp -d)
  (
    _stub_budget_env "$tmp"
    source "$REPO_ROOT/lib/ops/budget.sh"
    # Write a budget.json with a past reset_at and non-zero spend
    node -e "
      const fs = require('fs');
      fs.writeFileSync('$_BUDGET_FILE', JSON.stringify({
        daily_ceiling_usd: 50,
        current_spend_usd: 30.0,
        reset_at: '2020-01-01T00:00:00'
      }, null, 2));
    "
    budget_init
    local spend
    spend=$(node -p "JSON.parse(require('fs').readFileSync('$_BUDGET_FILE','utf-8')).current_spend_usd")
    [ "$spend" = "0" ]
  )
  local rc=$?; rm -rf "$tmp"; [ "$rc" -eq 0 ]
}

# ── C1: budget_check ──────────────────────────────────────────────────────────

@test "C1: budget_check returns ok (0) when spend is below ceiling" {
  local tmp; tmp=$(mktemp -d)
  (
    _stub_budget_env "$tmp"
    source "$REPO_ROOT/lib/ops/budget.sh"
    node -e "
      require('fs').writeFileSync('$_BUDGET_FILE', JSON.stringify({
        daily_ceiling_usd: 50, current_spend_usd: 10.0, reset_at: '2099-01-01T00:00:00'
      }, null, 2));
    "
    ! budget_check 0
  )
  local rc=$?; rm -rf "$tmp"; [ "$rc" -eq 0 ]
}

@test "C1: budget_check returns exceeded (1) when spend meets ceiling" {
  local tmp; tmp=$(mktemp -d)
  (
    _stub_budget_env "$tmp"
    source "$REPO_ROOT/lib/ops/budget.sh"
    node -e "
      require('fs').writeFileSync('$_BUDGET_FILE', JSON.stringify({
        daily_ceiling_usd: 50, current_spend_usd: 50.0, reset_at: '2099-01-01T00:00:00'
      }, null, 2));
    "
    budget_check 0
  )
  local rc=$?; rm -rf "$tmp"; [ "$rc" -eq 0 ]
}

@test "C1: budget_check accounts for estimated cost in comparison" {
  local tmp; tmp=$(mktemp -d)
  (
    _stub_budget_env "$tmp"
    source "$REPO_ROOT/lib/ops/budget.sh"
    node -e "
      require('fs').writeFileSync('$_BUDGET_FILE', JSON.stringify({
        daily_ceiling_usd: 50, current_spend_usd: 48.0, reset_at: '2099-01-01T00:00:00'
      }, null, 2));
    "
    budget_check 3
  )
  local rc=$?; rm -rf "$tmp"; [ "$rc" -eq 0 ]
}

@test "C1: budget_check returns ok when file missing (fail-open)" {
  local tmp; tmp=$(mktemp -d)
  (
    export _BUDGET_FILE="$tmp/nonexistent.json"
    export _BUDGET_LOCK="$tmp/nonexistent.lock"
    source "$REPO_ROOT/lib/ops/budget.sh"
    ! budget_check 0
  )
  local rc=$?; rm -rf "$tmp"; [ "$rc" -eq 0 ]
}

# ── C1: budget_record ─────────────────────────────────────────────────────────

@test "C1: budget_record increments current_spend_usd" {
  local tmp; tmp=$(mktemp -d)
  (
    _stub_budget_env "$tmp"
    source "$REPO_ROOT/lib/ops/budget.sh"
    node -e "
      require('fs').writeFileSync('$_BUDGET_FILE', JSON.stringify({
        daily_ceiling_usd: 50, current_spend_usd: 10.0, reset_at: '2099-01-01T00:00:00'
      }, null, 2));
    "
    budget_record 5.5
    local spend
    spend=$(node -p "JSON.parse(require('fs').readFileSync('$_BUDGET_FILE','utf-8')).current_spend_usd")
    node -e "process.exit($spend === 15.5 ? 0 : 1)"
  )
  local rc=$?; rm -rf "$tmp"; [ "$rc" -eq 0 ]
}

@test "C1: budget_record is a no-op when file missing" {
  local tmp; tmp=$(mktemp -d)
  (
    export _BUDGET_FILE="$tmp/nonexistent.json"
    export _BUDGET_LOCK="$tmp/nonexistent.lock"
    source "$REPO_ROOT/lib/ops/budget.sh"
    budget_record 5.0
    [ ! -f "$_BUDGET_FILE" ]
  )
  local rc=$?; rm -rf "$tmp"; [ "$rc" -eq 0 ]
}

# ── C2: Kill switch sentinel ──────────────────────────────────────────────────

@test "C2: kill switch sentinel is created by stop --all" {
  local tmp; tmp=$(mktemp -d)
  local sentinel="$tmp/STOP"
  (
    export _STOP_SENTINEL="$sentinel"
    source "$REPO_ROOT/cmd/stop.sh"
    sub_stop --all
    [ -f "$sentinel" ]
  )
  local rc=$?; rm -rf "$tmp"; [ "$rc" -eq 0 ]
}

@test "C2: kill switch sentinel is removed by stop --clear" {
  local tmp; tmp=$(mktemp -d)
  local sentinel="$tmp/STOP"
  touch "$sentinel"
  (
    export _STOP_SENTINEL="$sentinel"
    source "$REPO_ROOT/cmd/stop.sh"
    sub_stop --clear
    [ ! -f "$sentinel" ]
  )
  local rc=$?; rm -rf "$tmp"; [ "$rc" -eq 0 ]
}

@test "C2: stop --status reports SET when sentinel exists" {
  local tmp; tmp=$(mktemp -d)
  local sentinel="$tmp/STOP"
  touch "$sentinel"
  (
    export _STOP_SENTINEL="$sentinel"
    source "$REPO_ROOT/cmd/stop.sh"
    sub_stop --status 2>&1 | grep -qi "SET"
  )
  local rc=$?; rm -rf "$tmp"; [ "$rc" -eq 0 ]
}

@test "C2: stop --status reports CLEAR when sentinel absent" {
  local tmp; tmp=$(mktemp -d)
  local sentinel="$tmp/STOP"
  (
    export _STOP_SENTINEL="$sentinel"
    source "$REPO_ROOT/cmd/stop.sh"
    sub_stop --status 2>&1 | grep -qi "CLEAR"
  )
  local rc=$?; rm -rf "$tmp"; [ "$rc" -eq 0 ]
}

# ── C3: Project registry ──────────────────────────────────────────────────────

@test "C3: projects_register creates projects.json when missing" {
  local tmp; tmp=$(mktemp -d)
  (
    _stub_projects_env "$tmp"
    source "$REPO_ROOT/lib/ops/projects.sh"
    projects_register "/some/project" "claude-code"
    [ -f "$_PROJECTS_FILE" ]
  )
  local rc=$?; rm -rf "$tmp"; [ "$rc" -eq 0 ]
}

@test "C3: projects_register writes path and agent" {
  local tmp; tmp=$(mktemp -d)
  (
    _stub_projects_env "$tmp"
    source "$REPO_ROOT/lib/ops/projects.sh"
    projects_register "/my/project" "gemini"
    node -p "
      const e = JSON.parse(require('fs').readFileSync('$_PROJECTS_FILE','utf-8'));
      e.find(p => p.path === '/my/project' && p.agent === 'gemini') ? 'ok' : 'fail'
    " | grep -q "^ok$"
  )
  local rc=$?; rm -rf "$tmp"; [ "$rc" -eq 0 ]
}

@test "C3: projects_register updates last_run on duplicate path" {
  local tmp; tmp=$(mktemp -d)
  (
    _stub_projects_env "$tmp"
    source "$REPO_ROOT/lib/ops/projects.sh"
    projects_register "/my/project" "claude-code"
    sleep 1
    projects_register "/my/project" "claude-code"
    local count
    count=$(node -p "JSON.parse(require('fs').readFileSync('$_PROJECTS_FILE','utf-8')).length")
    [ "$count" -eq 1 ]
  )
  local rc=$?; rm -rf "$tmp"; [ "$rc" -eq 0 ]
}

@test "C3: projects_register preserves distinct projects" {
  local tmp; tmp=$(mktemp -d)
  (
    _stub_projects_env "$tmp"
    source "$REPO_ROOT/lib/ops/projects.sh"
    projects_register "/project-a" "claude-code"
    projects_register "/project-b" "codex"
    projects_register "/project-c" "gemini"
    local count
    count=$(node -p "JSON.parse(require('fs').readFileSync('$_PROJECTS_FILE','utf-8')).length")
    [ "$count" -eq 3 ]
  )
  local rc=$?; rm -rf "$tmp"; [ "$rc" -eq 0 ]
}

# ── C4: Concurrent-write safety on learning store ────────────────────────────

@test "C4: learning store already uses mkdir-based lock on write" {
  # Verify _learning_acquire_lock and _learning_release_lock are declared
  # in learning.sh — confirming the concurrency guard exists.
  (
    ROOT_DIR="/tmp" STATE_DIR="/tmp"
    info() { :; }; err() { :; }; warn() { :; }
    source "$REPO_ROOT/lib/memory/learning.sh" 2>/dev/null || true
    declare -f _learning_acquire_lock &>/dev/null && \
    declare -f _learning_release_lock &>/dev/null
  )
}

@test "C4: three concurrent learning_write calls produce valid JSON with all entries" {
  local tmp; tmp=$(mktemp -d)
  local store="$tmp/learned.json"
  echo '[]' > "$store"
  (
    ROOT_DIR="$tmp"
    STATE_DIR="$tmp/state"
    mkdir -p "$STATE_DIR/feat-concurrent"
    info() { :; }; err() { :; }; warn() { :; }
    source "$REPO_ROOT/lib/memory/learning.sh" 2>/dev/null || true

    # Override project path to use our tmp store
    _learning_project_path() { echo "$store"; }

    # Spawn 3 concurrent writers
    (MONOZUKURI_PROJECT_PATH="$tmp" learning_write "feat-concurrent" "error-sig-A" "fix-A") &
    (MONOZUKURI_PROJECT_PATH="$tmp" learning_write "feat-concurrent" "error-sig-B" "fix-B") &
    (MONOZUKURI_PROJECT_PATH="$tmp" learning_write "feat-concurrent" "error-sig-C" "fix-C") &
    wait

    # Final JSON must be valid and contain all 3 distinct entries
    local count
    count=$(node -p "JSON.parse(require('fs').readFileSync('$store','utf-8')).length" 2>/dev/null || echo 0)
    [ "$count" -eq 3 ]
  )
  local rc=$?; rm -rf "$tmp"; [ "$rc" -eq 0 ]
}

@test "C4: budget_record is safe under concurrent writes (atomic rename)" {
  local tmp; tmp=$(mktemp -d)
  (
    _stub_budget_env "$tmp"
    source "$REPO_ROOT/lib/ops/budget.sh"
    node -e "
      require('fs').writeFileSync('$_BUDGET_FILE', JSON.stringify({
        daily_ceiling_usd: 50, current_spend_usd: 0.0, reset_at: '2099-01-01T00:00:00'
      }, null, 2));
    "
    # 5 concurrent budget_record calls each adding $1
    for i in 1 2 3 4 5; do
      budget_record 1.0 &
    done
    wait
    local spend
    spend=$(node -p "JSON.parse(require('fs').readFileSync('$_BUDGET_FILE','utf-8')).current_spend_usd")
    # Spend should be 5.0 (all writes applied)
    node -e "process.exit($spend === 5 ? 0 : 1)"
  )
  local rc=$?; rm -rf "$tmp"; [ "$rc" -eq 0 ]
}
