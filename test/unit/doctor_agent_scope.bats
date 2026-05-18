#!/usr/bin/env bats
# test/unit/doctor_agent_scope.bats — doctor should only block on the active agent.

setup() {
  REPO_ROOT="$(cd "$(dirname "$BATS_TEST_FILENAME")/../.." && pwd)"
  TMPDIR_TEST="$(mktemp -d)"
  ORIG_DIR="$(pwd)"
  export LIB_DIR="$REPO_ROOT/lib"
  export HOME="$TMPDIR_TEST/home"
  mkdir -p "$HOME" "$TMPDIR_TEST/project/.monozukuri"
  cd "$TMPDIR_TEST/project"

  STUB_DIR="$TMPDIR_TEST/stubs"
  mkdir -p "$STUB_DIR"

  cat > "$STUB_DIR/node" <<'EOF'
#!/bin/bash
echo "20.0.0"
EOF
  cat > "$STUB_DIR/jq" <<'EOF'
#!/bin/bash
[ "${1:-}" = "--version" ] && echo "jq-1.7" && exit 0
echo "0"
EOF
  cat > "$STUB_DIR/gh" <<'EOF'
#!/bin/bash
exit 0
EOF
  cat > "$STUB_DIR/git" <<'EOF'
#!/bin/bash
exit 0
EOF
  cat > "$STUB_DIR/gum" <<'EOF'
#!/bin/bash
echo "0.17.0"
EOF
  cat > "$STUB_DIR/codex" <<'EOF'
#!/bin/bash
if [ "${1:-}" = "login" ] && [ "${2:-}" = "status" ]; then
  exit 0
fi
echo "codex 0.0.0"
EOF
  cat > "$STUB_DIR/gemini" <<'EOF'
#!/bin/bash
echo "gemini 0.0.0"
EOF
  chmod +x "$STUB_DIR"/node "$STUB_DIR"/jq "$STUB_DIR"/gh "$STUB_DIR"/git \
    "$STUB_DIR"/gum "$STUB_DIR"/codex "$STUB_DIR"/gemini

  export PATH="$STUB_DIR:/usr/bin:/bin"
  export OPT_CONFIG=".monozukuri/config.yaml"
}

teardown() {
  cd "$ORIG_DIR"
  rm -rf "$TMPDIR_TEST"
}

@test "doctor passes without claude when no project config selects claude-code" {
  mkdir -p "$HOME/.codex"

  run bash -c "source '$REPO_ROOT/cmd/doctor.sh' && sub_doctor 2>&1"

  [ "$status" -eq 0 ]
  [[ "$output" == *"agent CLI checks are advisory"* ]]
  [[ "$output" == *"claude-code CLI not installed (optional)"* ]]
}

@test "doctor does not require mz-* native skills for active codex agent" {
  mkdir -p "$HOME/.codex" "$HOME/.cursor" "$HOME/.gemini"
  printf '%s\n' 'agent: codex' > .monozukuri/config.yaml

  run bash -c "source '$REPO_ROOT/cmd/doctor.sh' && sub_doctor 2>&1"

  [ "$status" -eq 0 ]
  [[ "$output" == *"OpenAI Codex CLI ready"* ]]
  [[ "$output" == *"OpenAI Codex CLI uses rendered prompts; mz-* native skills not required"* ]]
}
