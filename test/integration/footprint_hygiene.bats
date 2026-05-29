#!/usr/bin/env bats
# test/integration/footprint_hygiene.bats
# Guards the files Monozukuri makes trackable in a consumer repository.

setup() {
  REPO_ROOT="$(cd "$(dirname "$BATS_TEST_FILENAME")/../.." && pwd)"
  ORCHESTRATE="$REPO_ROOT/orchestrate.sh"
  TMP_PROJECT="$(mktemp -d)"
  MOCK_BIN="$(mktemp -d)"
  cat > "$MOCK_BIN/claude" <<'EOF'
#!/usr/bin/env bash
exit 0
EOF
  chmod +x "$MOCK_BIN/claude"
  export PATH="$MOCK_BIN:$PATH"

  cd "$TMP_PROJECT"
  git init -q -b main 2>/dev/null || git init -q
  git checkout -B main >/dev/null 2>&1 || true
  git -c user.email=qa@test.local -c user.name=qa -c commit.gpgsign=false \
    commit --allow-empty -q -m init
}

teardown() {
  rm -rf "$TMP_PROJECT"
  rm -rf "$MOCK_BIN"
}

_git_status_files() {
  git -C "$TMP_PROJECT" status --porcelain --untracked-files=all \
    | sed 's/^...//' \
    | sort
}

@test "init and dry-run keep generated manifests/runtime files untrackable" {
  run bash "$ORCHESTRATE" init --non-interactive
  [ "$status" -eq 0 ]

  run bash "$ORCHESTRATE" run --dry-run --non-interactive --no-ui
  [ "$status" -eq 0 ]

  # These runtime files are intentionally still written for doctor/status and
  # prompt routing, but they can contain machine-local paths and must stay
  # ignored in consumer repositories.
  [ -f "$TMP_PROJECT/.monozukuri/agents-manifest.json" ]
  [ -f "$TMP_PROJECT/.monozukuri/skills-manifest.json" ]
  [ -f "$TMP_PROJECT/.monozukuri/environment.manifest.json" ]

  run _git_status_files
  [ "$status" -eq 0 ]

  cat <<'EOF' > "$TMP_PROJECT/expected-status.txt"
.env.example
.gitignore
.monozukuri/config.yaml
AGENTS.md
CLAUDE.md
features.md
EOF
  diff -u "$TMP_PROJECT/expected-status.txt" <(printf '%s\n' "$output")
}
