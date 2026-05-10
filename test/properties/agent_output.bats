#!/usr/bin/env bats
# test/properties/agent_output.bats — structural assertions on recorded agent
# fixtures. Runs on every PR; zero network calls, zero API spend.
#
# These properties are the contract the validator depends on. If a recording
# stops satisfying a property here, downstream phase validation will break in
# production — re-record (`make rerecord-fixtures`) is required.

setup() {
  REPO_ROOT="$(cd "$(dirname "$BATS_TEST_FILENAME")/../.." && pwd)"
  RECORDINGS_DIR="$REPO_ROOT/.qa/fixtures/recordings"
  REPLAY_BIN="$REPO_ROOT/.qa/fixtures/mocks/replay-claude"
}

# ── recording inventory ──────────────────────────────────────────────────────

@test "recordings dir exists" {
  [ -d "$RECORDINGS_DIR" ]
}

@test "every supported agent has a recordings subdirectory" {
  for agent in claude-code codex gemini; do
    [ -d "$RECORDINGS_DIR/$agent" ] || {
      echo "missing recordings dir for $agent" >&2
      return 1
    }
  done
}

@test "metadata.json is valid JSON with all expected agents" {
  [ -f "$RECORDINGS_DIR/metadata.json" ]
  node -e "
    const d = JSON.parse(require('fs').readFileSync('$RECORDINGS_DIR/metadata.json','utf-8'));
    if (d.schema_version !== 1) throw new Error('bad schema_version: ' + d.schema_version);
    for (const a of ['claude-code','codex','gemini']) {
      if (!d.agents[a]) throw new Error('missing agent: ' + a);
    }
  "
}

# ── PRD recordings ────────────────────────────────────────────────────────────

@test "every PRD recording has the required headings" {
  for f in "$RECORDINGS_DIR"/*/prd.md; do
    grep -qE '^## (Problem|Background|Overview|Motivation)' "$f" || {
      echo "PRD recording $f lacks problem-framing heading" >&2
      return 1
    }
    grep -qE '^## (Solution|Approach)' "$f" || {
      echo "PRD recording $f lacks solution heading" >&2
      return 1
    }
    grep -qE '^## (Functional requirements|Requirements|Acceptance)' "$f" || {
      echo "PRD recording $f lacks requirements heading" >&2
      return 1
    }
    grep -qE '^## (Out of scope|Non-goals)' "$f" || {
      echo "PRD recording $f lacks out-of-scope heading" >&2
      return 1
    }
  done
}

# ── TechSpec recordings ───────────────────────────────────────────────────────

@test "every TechSpec recording has approach + file-list sections" {
  for f in "$RECORDINGS_DIR"/*/techspec.md; do
    grep -qE '^## (Approach|Technical Approach)' "$f" || {
      echo "TechSpec recording $f lacks Approach heading" >&2
      return 1
    }
    grep -qE '^## (File change map|Files Likely Touched|Files|Implementation Files)' "$f" || {
      echo "TechSpec recording $f lacks file-list heading" >&2
      return 1
    }
  done
}

# ── tasks.json recordings ─────────────────────────────────────────────────────

@test "every tasks.json recording is valid JSON with required fields" {
  for f in "$RECORDINGS_DIR"/*/tasks.json; do
    node -e "
      const d = JSON.parse(require('fs').readFileSync('$f','utf-8'));
      if (!Array.isArray(d)) throw new Error('not an array: $f');
      if (d.length === 0) throw new Error('empty array: $f');
      for (const t of d) {
        for (const k of ['id','title','description','files_touched','acceptance_criteria']) {
          if (!(k in t)) throw new Error('missing key '+k+' in $f');
        }
        if (!Array.isArray(t.files_touched)) throw new Error('files_touched not array: $f');
        if (!Array.isArray(t.acceptance_criteria)) throw new Error('acceptance_criteria not array: $f');
      }
    "
  done
}

# ── stream-json recordings ────────────────────────────────────────────────────

@test "every stream-json recording is line-delimited JSON" {
  for f in "$RECORDINGS_DIR"/*/*.stream-json; do
    while IFS= read -r line; do
      [ -z "$line" ] && continue
      printf '%s' "$line" | node -e "JSON.parse(require('fs').readFileSync(0,'utf-8'))" || {
        echo "invalid JSON line in $f: $line" >&2
        return 1
      }
    done < "$f"
  done
}

@test "every stream-json recording emits a tool_use event" {
  for f in "$RECORDINGS_DIR"/*/*.stream-json; do
    grep -q '"type":"tool_use"' "$f" || {
      echo "stream-json recording $f has no tool_use events" >&2
      return 1
    }
  done
}

@test "every stream-json recording ends with message_stop" {
  for f in "$RECORDINGS_DIR"/*/*.stream-json; do
    tail -1 "$f" | grep -q '"type":"message_stop"' || {
      echo "stream-json recording $f doesn't end with message_stop" >&2
      return 1
    }
  done
}

# ── replay binary contract ────────────────────────────────────────────────────

@test "replay-claude exists and is executable" {
  [ -x "$REPLAY_BIN" ]
}

@test "replay-claude --version succeeds" {
  run "$REPLAY_BIN" --version
  [ "$status" -eq 0 ]
  [[ "$output" == *replay-mock* ]]
}

@test "replay-claude auth status succeeds" {
  run "$REPLAY_BIN" auth status
  [ "$status" -eq 0 ]
}

@test "replay-claude normal mode replays PRD recording verbatim" {
  local wt; wt=$(mktemp -d)
  run env MONOZUKURI_WORKTREE="$wt" MONOZUKURI_FEATURE_ID="canary-001" \
      MONOZUKURI_PHASE=prd MONOZUKURI_AGENT=claude-code \
      "$REPLAY_BIN" -p "render"
  [ "$status" -eq 0 ]
  diff <(echo "$output") "$RECORDINGS_DIR/claude-code/prd.md"
  rm -rf "$wt"
}

@test "replay-claude auth-expired mode exits non-zero" {
  run env MOCK_CLAUDE_MODE=auth-expired \
      MONOZUKURI_WORKTREE=/tmp MONOZUKURI_FEATURE_ID=x MONOZUKURI_PHASE=prd \
      "$REPLAY_BIN" -p "x"
  [ "$status" -ne 0 ]
  [[ "$output" == *expired* || "$output" == *Authentication* ]]
}

@test "replay-claude diverge mode drops a heading from PRD recording" {
  local wt; wt=$(mktemp -d)
  run env MOCK_CLAUDE_MODE=diverge MONOZUKURI_WORKTREE="$wt" \
      MONOZUKURI_FEATURE_ID=canary-001 MONOZUKURI_PHASE=prd \
      MONOZUKURI_AGENT=claude-code "$REPLAY_BIN" -p "render"
  [ "$status" -eq 0 ]
  local heading_count
  heading_count=$(printf '%s\n' "$output" | grep -c '^## ' || true)
  local original_count
  original_count=$(grep -c '^## ' "$RECORDINGS_DIR/claude-code/prd.md")
  [ "$heading_count" -lt "$original_count" ]
  rm -rf "$wt"
}

@test "replay-claude build-fail mode writes no artifacts but exits 0" {
  local wt; wt=$(mktemp -d)
  run env MOCK_CLAUDE_MODE=build-fail MONOZUKURI_WORKTREE="$wt" \
      MONOZUKURI_FEATURE_ID=canary-001 MONOZUKURI_PHASE=prd \
      MONOZUKURI_AGENT=claude-code "$REPLAY_BIN" --agent prd-skill
  [ "$status" -eq 0 ]
  [ ! -d "$wt/tasks" ]
  rm -rf "$wt"
}

@test "replay-claude tier-1 invocation writes artifact files" {
  local wt; wt=$(mktemp -d)
  run env MONOZUKURI_WORKTREE="$wt" MONOZUKURI_FEATURE_ID=canary-001 \
      MONOZUKURI_PHASE=prd MONOZUKURI_AGENT=claude-code \
      "$REPLAY_BIN" --agent prd-skill
  [ "$status" -eq 0 ]
  [ -f "$wt/tasks/prd-canary-001/prd.md" ]
  rm -rf "$wt"
}
