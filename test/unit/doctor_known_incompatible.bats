#!/usr/bin/env bats
# test/unit/doctor_known_incompatible.bats — tests for known-incompatible skill
# warning in lib/agent/known-incompatible.sh and cmd/doctor.sh

setup() {
  REPO_ROOT="$(cd "$(dirname "$BATS_TEST_FILENAME")/../.." && pwd)"
  REAL_LIB_DIR="$REPO_ROOT/lib"
  export REPO_ROOT

  TMPDIR_TEST="$(mktemp -d)"
  ORIG_DIR="$(pwd)"

  # Minimal fake project dir with git repo
  mkdir -p "$TMPDIR_TEST/project/.monozukuri"
  cd "$TMPDIR_TEST/project"
  git init -q
  git config user.email "test@example.com"
  git config user.name "Test"

  # Fake LIB_DIR: contains agent/known-incompatible.sh but NOT setup/detect.sh,
  # so doctor's mz-* skills section is skipped (avoids hitting real agent installs).
  FAKE_LIB="$TMPDIR_TEST/lib"
  mkdir -p "$FAKE_LIB/agent" "$FAKE_LIB/cli"
  cp "$REAL_LIB_DIR/agent/known-incompatible.sh" "$FAKE_LIB/agent/known-incompatible.sh"
  cat > "$FAKE_LIB/agent/adapter-claude-code.sh" <<'EOF'
agent_doctor() {
  command -v claude >/dev/null 2>&1
}
agent_login_hint() {
  printf 'claude login\n'
}
EOF
  # colors.sh sources tokens.sh via [ -f ] && source; under set -e the [ -f ]
  # returns 1 (missing file) aborts — copy both files to avoid that trap.
  cp "$REAL_LIB_DIR/cli/colors.sh" "$FAKE_LIB/cli/colors.sh"
  cp "$REAL_LIB_DIR/cli/tokens.sh" "$FAKE_LIB/cli/tokens.sh"
  export LIB_DIR="$FAKE_LIB"

  # Stub external CLIs so doctor's dependency checks pass cleanly
  STUB_DIR="$TMPDIR_TEST/stubs"
  mkdir -p "$STUB_DIR"

  cat > "$STUB_DIR/node" <<'EOF'
#!/bin/bash
echo "20.0.0"
EOF
  cat > "$STUB_DIR/jq" <<'EOF'
#!/bin/bash
[ "${1:-}" = "--version" ] && echo "jq-1.7" && exit 0
exec "$(command -v jq 2>/dev/null || echo /usr/bin/jq)" "$@"
EOF
  cat > "$STUB_DIR/gh" <<'EOF'
#!/bin/bash
exit 0
EOF
  cat > "$STUB_DIR/git" <<'EOF'
#!/bin/bash
exit 0
EOF
  cat > "$STUB_DIR/claude" <<'EOF'
#!/bin/bash
exit 0
EOF
  cat > "$STUB_DIR/gum" <<'EOF'
#!/bin/bash
echo "0.17.0"
EOF
  chmod +x "$STUB_DIR"/node "$STUB_DIR"/jq "$STUB_DIR"/gh "$STUB_DIR"/git "$STUB_DIR"/claude "$STUB_DIR"/gum

  export PATH="$STUB_DIR:$PATH"
}

teardown() {
  cd "$ORIG_DIR"
  rm -rf "$TMPDIR_TEST"
}

# ── known-incompatible.sh unit tests ─────────────────────────────────────────

@test "is_skill_known_incompatible: feature-marker returns true" {
  source "$REAL_LIB_DIR/agent/known-incompatible.sh"
  is_skill_known_incompatible "feature-marker"
}

@test "is_skill_known_incompatible: mz-create-prd returns false" {
  source "$REAL_LIB_DIR/agent/known-incompatible.sh"
  ! is_skill_known_incompatible "mz-create-prd"
}

@test "is_skill_known_incompatible: unknown skill returns false" {
  source "$REAL_LIB_DIR/agent/known-incompatible.sh"
  ! is_skill_known_incompatible "some-random-skill"
}

@test "known_incompatible_reason: feature-marker mentions MONOZUKURI_INTERACTIVE" {
  source "$REAL_LIB_DIR/agent/known-incompatible.sh"
  reason="$(known_incompatible_reason "feature-marker")"
  [[ "$reason" == *"MONOZUKURI_INTERACTIVE"* ]]
}

@test "known_incompatible_reason: feature-marker recommends mz-* replacement" {
  source "$REAL_LIB_DIR/agent/known-incompatible.sh"
  reason="$(known_incompatible_reason "feature-marker")"
  [[ "$reason" == *"mz-"* ]]
}

# ── doctor integration tests ──────────────────────────────────────────────────

@test "doctor: exits 0 when config has no known-incompatible skills" {
  printf '%s\n' 'agents:' '  claude-code:' '    skills:' '      prd: mz-create-prd' \
    '      code: mz-execute-task' > .monozukuri/config.yaml
  _proj="$TMPDIR_TEST/project"
  _lib="$FAKE_LIB"
  _repo="$REPO_ROOT"
  run bash -c "cd '$_proj' && export LIB_DIR='$_lib' PATH='$STUB_DIR:$PATH' && source '$_repo/cmd/doctor.sh' && sub_doctor"
  [ "$status" -eq 0 ]
}

@test "doctor: exits 0 (non-blocking) when feature-marker is configured" {
  printf '%s\n' 'agents:' '  claude-code:' '    skills:' '      code: feature-marker' \
    > .monozukuri/config.yaml
  _proj="$TMPDIR_TEST/project"
  _lib="$FAKE_LIB"
  _repo="$REPO_ROOT"
  run bash -c "cd '$_proj' && export LIB_DIR='$_lib' PATH='$STUB_DIR:$PATH' && source '$_repo/cmd/doctor.sh' && sub_doctor" 2>&1
  [ "$status" -eq 0 ]
}

@test "doctor: warns when feature-marker is configured" {
  printf '%s\n' 'agents:' '  claude-code:' '    skills:' '      code: feature-marker' \
    > .monozukuri/config.yaml
  _proj="$TMPDIR_TEST/project"
  _lib="$FAKE_LIB"
  _repo="$REPO_ROOT"
  run bash -c "cd '$_proj' && export LIB_DIR='$_lib' PATH='$STUB_DIR:$PATH' && source '$_repo/cmd/doctor.sh' && sub_doctor 2>&1"
  [[ "$output" == *"feature-marker"* ]]
}

@test "doctor: feature-marker warning mentions incompatibility reason" {
  printf '%s\n' 'agents:' '  claude-code:' '    skills:' '      code: feature-marker' \
    > .monozukuri/config.yaml
  _proj="$TMPDIR_TEST/project"
  _lib="$FAKE_LIB"
  _repo="$REPO_ROOT"
  run bash -c "cd '$_proj' && export LIB_DIR='$_lib' PATH='$STUB_DIR:$PATH' && source '$_repo/cmd/doctor.sh' && sub_doctor 2>&1"
  [[ "$output" == *"known incompatible"* ]] || [[ "$output" == *"MONOZUKURI_INTERACTIVE"* ]]
}

@test "doctor: emits skill compatibility pass when no incompatible skills in config" {
  printf '%s\n' 'agents:' '  claude-code:' '    skills:' '      prd: mz-create-prd' \
    '      techspec: mz-create-techspec' '      tasks: mz-create-tasks' \
    > .monozukuri/config.yaml
  _proj="$TMPDIR_TEST/project"
  _lib="$FAKE_LIB"
  _repo="$REPO_ROOT"
  run bash -c "cd '$_proj' && export LIB_DIR='$_lib' PATH='$STUB_DIR:$PATH' && source '$_repo/cmd/doctor.sh' && sub_doctor 2>&1"
  [[ "$output" == *"skill compatibility"* ]]
}
