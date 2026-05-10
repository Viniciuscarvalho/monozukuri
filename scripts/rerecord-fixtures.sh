#!/usr/bin/env bash
# scripts/rerecord-fixtures.sh — capture real agent output as test fixtures.
#
# Local-only: NEVER run this in CI. Each invocation costs roughly $0.50 per
# agent (3 phases × ~1k tokens × claude-sonnet pricing). The fixtures it
# writes get committed and replayed by .qa/fixtures/mocks/replay-claude
# during property tests and Layer 2/7 of the release gate.
#
# Usage:
#   scripts/rerecord-fixtures.sh                    # claude-code only
#   scripts/rerecord-fixtures.sh --agent codex      # one specific agent
#   scripts/rerecord-fixtures.sh --agent all        # every supported agent
#   scripts/rerecord-fixtures.sh --dry-run          # show what would happen
#
# Requires the relevant agent CLI to be installed and authenticated.

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
RECORDINGS_DIR="$REPO_ROOT/.qa/fixtures/recordings"
CONTEXT_FILE="$REPO_ROOT/.qa/fixtures/contexts/canary-feature.json"

AGENT="claude-code"
DRY_RUN=false

while [ $# -gt 0 ]; do
  case "$1" in
    --agent) AGENT="$2"; shift 2 ;;
    --dry-run) DRY_RUN=true; shift ;;
    -h|--help)
      sed -n '2,15p' "$0" | sed 's/^# \{0,1\}//'
      exit 0
      ;;
    *) echo "unknown arg: $1" >&2; exit 2 ;;
  esac
done

[ -f "$CONTEXT_FILE" ] || {
  echo "missing canary context: $CONTEXT_FILE" >&2
  exit 1
}

# ── prompts (kept tiny — total cost ~ $0.50 per full agent re-record) ─────────
_prompt_for_phase() {
  case "$1" in
    prd)
      cat <<'EOF'
Output a PRD-style markdown document for this canary feature: 'Add a
--version CLI flag that prints a static string.' Use exactly these
top-level headings, in this order: '## Problem', '## Solution',
'## Functional requirements', '## Out of scope'. Keep total length
under 120 words. No preamble, no code blocks.
EOF
      ;;
    techspec)
      cat <<'EOF'
Output a TechSpec-style markdown document for: 'Add a --version CLI
flag that prints a static string.' Use exactly these top-level
headings, in this order: '## Approach', '## File change map',
'## Components', '## Testing'. Keep total length under 120 words.
No preamble, no code blocks.
EOF
      ;;
    tasks)
      cat <<'EOF'
Output a JSON array of task objects (no preamble, no code fences) for
the canary feature 'Add --version CLI flag.' Each task object must have
keys: id (string), title (string), description (string), files_touched
(string[]), acceptance_criteria (string[]). Output 1–2 tasks total.
EOF
      ;;
  esac
}

_record_phase_claude() {
  local phase="$1" out_md="$2" out_stream="$3"
  local prompt; prompt=$(_prompt_for_phase "$phase")

  if [ "$DRY_RUN" = true ]; then
    printf '  [dry-run] would record %s/%s\n' "claude-code" "$phase"
    return 0
  fi

  printf '  recording claude-code/%s ...\n' "$phase"
  # Plain markdown body
  claude --print --model "${ANTHROPIC_MODEL:-claude-sonnet-4-6}" "$prompt" > "$out_md"
  # Stream-json companion (best-effort — older CLIs may not support it)
  if claude --output-format stream-json --print "$prompt" > "$out_stream" 2>/dev/null; then
    :
  else
    printf '  [warn] stream-json capture failed for %s — preserving previous\n' "$phase"
    rm -f "$out_stream"
    git checkout -- "$out_stream" 2>/dev/null || true
  fi
}

_record_agent() {
  local agent="$1"
  local agent_dir="$RECORDINGS_DIR/$agent"
  mkdir -p "$agent_dir"

  case "$agent" in
    claude-code)
      command -v claude >/dev/null || {
        echo "claude CLI not found — install: npm install -g @anthropic-ai/claude-code" >&2
        return 1
      }
      claude auth status >/dev/null 2>&1 || {
        echo "claude not authenticated — run: claude auth login" >&2
        return 1
      }
      _record_phase_claude prd      "$agent_dir/prd.md"      "$agent_dir/prd.stream-json"
      _record_phase_claude techspec "$agent_dir/techspec.md" "$agent_dir/techspec.stream-json"
      # tasks is JSON, not markdown — capture body only
      if [ "$DRY_RUN" = false ]; then
        printf '  recording claude-code/tasks ...\n'
        claude --print "$(_prompt_for_phase tasks)" > "$agent_dir/tasks.json"
      fi
      ;;
    codex|gemini)
      echo "  [todo] re-record for $agent — implement when adapter records land"
      return 0
      ;;
    *)
      echo "unknown agent: $agent" >&2
      return 2
      ;;
  esac
}

# ── main ──────────────────────────────────────────────────────────────────────
echo "Re-recording fixtures for: $AGENT"

if [ "$AGENT" = "all" ]; then
  for a in claude-code codex gemini; do
    _record_agent "$a" || echo "  [skip] $a"
  done
else
  _record_agent "$AGENT"
fi

# Update metadata
if [ "$DRY_RUN" = false ]; then
  node -e "
    const fs = require('fs');
    const p = '$RECORDINGS_DIR/metadata.json';
    const d = JSON.parse(fs.readFileSync(p,'utf-8'));
    const now = new Date().toISOString();
    const a = '$AGENT' === 'all' ? ['claude-code','codex','gemini'] : ['$AGENT'];
    for (const k of a) {
      if (d.agents[k]) {
        d.agents[k].captured_at = now;
        d.agents[k].captured_with = 'rerecord-fixtures.sh';
        d.agents[k].model = process.env.ANTHROPIC_MODEL || 'claude-sonnet-4-6';
      }
    }
    fs.writeFileSync(p, JSON.stringify(d, null, 2) + '\n');
  "
fi

echo "Done. Run \`bats test/properties\` to verify the new recordings still satisfy the property contract."
