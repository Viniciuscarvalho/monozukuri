#!/usr/bin/env bats
# test/unit/conventions_suppress.bats — suppression logic in context_pack_build

setup() {
  REPO_ROOT="$(cd "$(dirname "$BATS_TEST_FILENAME")/../.." && pwd)"
  LIB_DIR="$REPO_ROOT/lib"
  FIXTURES="$REPO_ROOT/test/fixtures/conventions"
  export LIB_DIR FIXTURES REPO_ROOT
  source "$LIB_DIR/agent/conventions.sh"
  source "$LIB_DIR/prompt/context-pack.sh"
  unset MONOZUKURI_READ_CONVENTIONS MANIFEST_RUN_ID
  # Reset contract functions so tests can inject their own
  unset -f agent_native_context_files 2>/dev/null || true
}

# ── no adapter declares native files (fallback) ───────────────────────────────

@test "without agent_native_context_files all conventions are injected" {
  ROOT_DIR="$FIXTURES/with-agents-md"
  tmpout=$(mktemp)
  context_pack_build "feat-test" "$tmpout"
  count=$(jq '.project_learnings | length' "$tmpout")
  rm -f "$tmpout"
  [ "$count" -gt 0 ]
}

# ── claude-code adapter: suppresses CLAUDE.md, injects AGENTS.md ─────────────

@test "claude-code adapter: CLAUDE.md conventions are suppressed" {
  # Build a project with both AGENTS.md and CLAUDE.md
  tmpdir=$(mktemp -d)
  cp "$FIXTURES/agents-simple.md" "$tmpdir/AGENTS.md"
  cp "$FIXTURES/claude-md.md"     "$tmpdir/CLAUDE.md"
  ROOT_DIR="$tmpdir"

  # Simulate claude-code adapter being loaded
  agent_native_context_files() { printf '%s\n' '["CLAUDE.md", ".claude/CLAUDE.md"]'; }

  tmpout=$(mktemp)
  context_pack_build "feat-test" "$tmpout"

  # CLAUDE.md sections should appear only as a reference line, not their body content
  claude_body_in_prompt=$(jq '[.project_learnings[].summary] |
    any(contains("Prefer explicit types"))' "$tmpout")
  has_reference=$(jq '[.project_learnings[].summary] |
    any(contains("See CLAUDE.md"))' "$tmpout")

  rm -rf "$tmpdir" "$tmpout"
  [[ "$claude_body_in_prompt" == "false" ]]
  [[ "$has_reference" == "true" ]]
}

@test "claude-code adapter: AGENTS.md conventions are still injected" {
  tmpdir=$(mktemp -d)
  cp "$FIXTURES/agents-simple.md" "$tmpdir/AGENTS.md"
  cp "$FIXTURES/claude-md.md"     "$tmpdir/CLAUDE.md"
  ROOT_DIR="$tmpdir"

  agent_native_context_files() { printf '%s\n' '["CLAUDE.md", ".claude/CLAUDE.md"]'; }

  tmpout=$(mktemp)
  context_pack_build "feat-test" "$tmpout"

  kysely_injected=$(jq '[.project_learnings[].summary] | any(contains("kysely"))' "$tmpout")

  rm -rf "$tmpdir" "$tmpout"
  [[ "$kysely_injected" == "true" ]]
}

# ── codex adapter: suppresses AGENTS.md entirely ─────────────────────────────

@test "codex adapter: AGENTS.md conventions are suppressed with reference" {
  tmpdir=$(mktemp -d)
  cp "$FIXTURES/agents-simple.md" "$tmpdir/AGENTS.md"
  ROOT_DIR="$tmpdir"

  agent_native_context_files() { printf '%s\n' '["AGENTS.md"]'; }

  tmpout=$(mktemp)
  context_pack_build "feat-test" "$tmpout"

  body_in_prompt=$(jq '[.project_learnings[].summary] | any(contains("kysely"))' "$tmpout")
  has_reference=$(jq '[.project_learnings[].summary] | any(contains("See AGENTS.md"))' "$tmpout")

  rm -rf "$tmpdir" "$tmpout"
  [[ "$body_in_prompt" == "false" ]]
  [[ "$has_reference" == "true" ]]
}

# ── no double-injection of native-file reference lines ───────────────────────

@test "reference line appears exactly once per suppressed file" {
  tmpdir=$(mktemp -d)
  cp "$FIXTURES/agents-simple.md" "$tmpdir/AGENTS.md"
  ROOT_DIR="$tmpdir"

  agent_native_context_files() { printf '%s\n' '["AGENTS.md"]'; }

  tmpout=$(mktemp)
  context_pack_build "feat-test" "$tmpout"

  ref_count=$(jq '[.project_learnings[].summary | select(contains("See AGENTS.md"))] | length' "$tmpout")

  rm -rf "$tmpdir" "$tmpout"
  [ "$ref_count" -eq 1 ]
}

# ── no-convention project is unaffected ──────────────────────────────────────

@test "adapter with no native files: all conventions injected (no suppression)" {
  tmpdir=$(mktemp -d)
  cp "$FIXTURES/agents-simple.md" "$tmpdir/AGENTS.md"
  ROOT_DIR="$tmpdir"

  agent_native_context_files() { printf '%s\n' '[]'; }

  tmpout=$(mktemp)
  context_pack_build "feat-test" "$tmpout"

  kysely_injected=$(jq '[.project_learnings[].summary] | any(contains("kysely"))' "$tmpout")

  rm -rf "$tmpdir" "$tmpout"
  [[ "$kysely_injected" == "true" ]]
}

# ── registry: adapter loaded before context_pack_build ───────────────────────

@test "registry_dispatch loads adapter before registry_prepare_phase" {
  source "$LIB_DIR/agent/contract.sh"
  source "$LIB_DIR/agent/registry.sh"

  # Verify the function order: agent_load must be called before context_pack_build
  # We test this indirectly by checking that registry.sh source is correct
  run grep -n "agent_load\|registry_prepare_phase" "$LIB_DIR/agent/registry.sh"
  [ "$status" -eq 0 ]
  # agent_load line must appear before registry_prepare_phase line
  load_line=$(grep -n "agent_load" "$LIB_DIR/agent/registry.sh" | grep -v "^#" | head -1 | cut -d: -f1)
  prep_line=$(grep -n "registry_prepare_phase" "$LIB_DIR/agent/registry.sh" | grep -v "^#\|registry_prepare_phase()" | tail -1 | cut -d: -f1)
  [ "$load_line" -lt "$prep_line" ]
}
