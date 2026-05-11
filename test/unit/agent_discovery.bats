#!/usr/bin/env bats
# test/unit/agent_discovery.bats — unit tests for scripts/agent-discovery.sh
#
# Covers both the existing surface (root AGENTS.md, .claude/agents/) and the
# new nested-AGENTS.md walk added in this PR.

setup() {
  REPO_ROOT="$(cd "$(dirname "$BATS_TEST_FILENAME")/../.." && pwd)"
  DISCOVERY="$REPO_ROOT/scripts/agent-discovery.sh"
  TMP=$(mktemp -d)
  MANIFEST="$TMP/.monozukuri/agents-manifest.json"
  export REPO_ROOT DISCOVERY TMP MANIFEST
}

teardown() {
  rm -rf "$TMP"
}

# Convenience: run discovery + load resulting manifest into $MANIFEST_JSON
_run_discovery() {
  bash "$DISCOVERY" "$TMP" "$MANIFEST" >/dev/null 2>&1
  MANIFEST_JSON=$(cat "$MANIFEST" 2>/dev/null || echo '{}')
}

@test "empty project produces an empty agents array" {
  _run_discovery
  jq -e '.agents | length == 0' <<<"$MANIFEST_JSON"
}

@test "root AGENTS.md sections are discovered" {
  cat > "$TMP/AGENTS.md" <<'EOF'
# AGENTS.md

## backend

Handles backend tasks.

## frontend

Handles frontend tasks.
EOF
  _run_discovery
  jq -e '.agents | length == 2' <<<"$MANIFEST_JSON"
  jq -e '.agents | map(.source) | all(. == "agents-md")' <<<"$MANIFEST_JSON"
}

@test ".claude/agents/*.md files take precedence over AGENTS.md collisions" {
  mkdir -p "$TMP/.claude/agents"
  cat > "$TMP/.claude/agents/backend.md" <<'EOF'
---
name: backend
description: Backend agent from .claude/agents
phase: code
---
EOF
  cat > "$TMP/AGENTS.md" <<'EOF'
## backend

Different backend description in AGENTS.md.
EOF
  _run_discovery
  jq -e '.agents | length == 1' <<<"$MANIFEST_JSON"
  jq -e '.agents[0].source == "agents-dir"' <<<"$MANIFEST_JSON"
}

# ── new in this PR: nested AGENTS.md walk ─────────────────────────────────────

@test "nested ui/AGENTS.md is discovered" {
  mkdir -p "$TMP/ui"
  cat > "$TMP/ui/AGENTS.md" <<'EOF'
## ui-builder

Builds the Ink TUI.
EOF
  _run_discovery
  jq -e '.agents | length == 1' <<<"$MANIFEST_JSON"
  jq -e '.agents[0].source == "agents-md-nested"' <<<"$MANIFEST_JSON"
  jq -e '.agents[0].path | startswith("ui/AGENTS.md#")' <<<"$MANIFEST_JSON"
}

@test "nested AGENTS.md adds to (not replaces) root AGENTS.md" {
  cat > "$TMP/AGENTS.md" <<'EOF'
## backend

Root backend.
EOF
  mkdir -p "$TMP/ios"
  cat > "$TMP/ios/AGENTS.md" <<'EOF'
## ios-builder

Handles iOS-specific tasks.
EOF
  _run_discovery
  jq -e '.agents | length == 2' <<<"$MANIFEST_JSON"
  jq -e '.agents | map(.name) | sort == ["backend","ios-builder"]' <<<"$MANIFEST_JSON"
}

@test "ignored dirs (node_modules, dist, .git, .monozukuri) are skipped" {
  for ignored in node_modules dist .git .monozukuri build .claude .qa coverage; do
    mkdir -p "$TMP/$ignored"
    printf '## should-not-appear\nIgnored.\n' > "$TMP/$ignored/AGENTS.md"
  done
  _run_discovery
  jq -e '.agents | length == 0' <<<"$MANIFEST_JSON"
}

@test "depth limit prevents pathological deep walks" {
  # Build a 5-deep path; only depth ≤ 3 is scanned.
  mkdir -p "$TMP/a/b/c/d/e"
  printf '## too-deep\nIgnored.\n' > "$TMP/a/b/c/d/e/AGENTS.md"
  printf '## just-right\nKept.\n'   > "$TMP/a/b/c/AGENTS.md"
  _run_discovery
  jq -e '.agents | length == 1' <<<"$MANIFEST_JSON"
  jq -e '.agents[0].name == "just-right"' <<<"$MANIFEST_JSON"
}

@test "first-seen wins for nested collisions" {
  cat > "$TMP/AGENTS.md" <<'EOF'
## backend

Root backend (wins).
EOF
  mkdir -p "$TMP/api"
  cat > "$TMP/api/AGENTS.md" <<'EOF'
## backend

Nested backend (loses).
EOF
  _run_discovery
  jq -e '.agents | length == 1' <<<"$MANIFEST_JSON"
  jq -e '.agents[0].path == "AGENTS.md#backend"' <<<"$MANIFEST_JSON"
}

@test "manifest source field distinguishes root vs nested vs agents-dir" {
  mkdir -p "$TMP/.claude/agents" "$TMP/mobile"
  cat > "$TMP/.claude/agents/coder.md" <<'EOF'
---
name: coder
description: From agents dir
---
EOF
  printf '## doc-writer\nFrom root.\n' > "$TMP/AGENTS.md"
  printf '## mobile-builder\nFrom mobile subpkg.\n' > "$TMP/mobile/AGENTS.md"

  _run_discovery
  jq -e '.agents | length == 3' <<<"$MANIFEST_JSON"
  jq -e '[.agents[].source] | sort == ["agents-dir","agents-md","agents-md-nested"]' <<<"$MANIFEST_JSON"
}
