#!/usr/bin/env bash
# docs/assets/record-hero.sh — wrapper that sets up the demo environment and
# runs VHS to regenerate docs/assets/hero.gif.
#
# Usage:
#   docs/assets/record-hero.sh
#
# Prerequisites:
#   brew install vhs     (https://github.com/charmbracelet/vhs)
#   monozukuri installed (brew, npm, or repo-dev)
#
# This script:
#   1. Creates (or resets) ~/mz-hero-demo with a two-feature backlog
#   2. Puts the mock claude binary on PATH (MOCK_CLAUDE_MODE=normal)
#   3. Runs vhs docs/assets/hero.tape from the repo root
#      → writes docs/assets/hero.gif

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
MOCK_DIR="$REPO_ROOT/.qa/fixtures/mocks/claude"
DEMO_DIR="$HOME/mz-hero-demo"

# ── guard: vhs must be installed ─────────────────────────────────────────────
if ! command -v vhs &>/dev/null; then
  echo "ERROR: vhs not found — install with: brew install vhs" >&2
  exit 1
fi

# ── guard: mock must exist ────────────────────────────────────────────────────
if [ ! -x "$MOCK_DIR/claude" ]; then
  echo "ERROR: mock binary not found at $MOCK_DIR/claude" >&2
  exit 1
fi

# ── (re)create demo repo ──────────────────────────────────────────────────────
echo "→ Creating demo repo at $DEMO_DIR"
rm -rf "$DEMO_DIR"
mkdir -p "$DEMO_DIR"
cd "$DEMO_DIR"
git init --quiet
git config user.email "demo@example.com"
git config user.name "Demo User"
git commit --allow-empty -m "chore: initial commit" --quiet

# ── features.md with two realistic features ───────────────────────────────────
cat > features.md << 'EOF'
## [FEAT] add-dry-run-colors: Color-coded dry-run output

- priority: medium

As a CLI user I want colored output in `--dry-run` mode so I can quickly
tell which features are ready (green), blocked (yellow), or done (dim)
without reading every word.

Acceptance criteria:
- Ready features shown in green with a ✓ prefix
- Blocked features shown in yellow with a ⚠ prefix
- Done features shown in dim text with a · prefix
- Color is suppressed when NO_COLOR=1 or when stdout is not a TTY

## [FEAT] add-max-tokens-flag: --max-tokens CLI override

- priority: low

As a user running quick experiments I want to pass `--max-tokens 20000` on
the command line to override the config's `max_feature_tokens`, so I can
cap spend without editing config.yaml for every short run.

Acceptance criteria:
- `monozukuri run --max-tokens 20000` sets MONOZUKURI_MAX_FEATURE_TOKENS=20000
- Value is validated (positive integer, minimum 5000)
- Precedence: CLI flag > env var > config.yaml > default (80000)
- Shown in the dry-run summary: "token ceiling: 20 000 (from --max-tokens)"
EOF

# Initial git commit so the worktree-diff gate doesn't reject a clean tree
git add features.md
git commit -m "feat: initial backlog" --quiet

echo "→ Demo repo ready"

# ── mock environment ──────────────────────────────────────────────────────────
export PATH="$MOCK_DIR:$PATH"
export MOCK_CLAUDE_MODE=normal
export MONOZUKURI_AGENT=claude-code

# ── record ────────────────────────────────────────────────────────────────────
echo "→ Starting VHS recording (output: $REPO_ROOT/docs/assets/hero.gif)"
cd "$REPO_ROOT"
vhs docs/assets/hero.tape

echo "→ Done: docs/assets/hero.gif"
echo "   Size: $(du -sh docs/assets/hero.gif | cut -f1)"
echo ""
echo "   Commit with:"
echo "   git add docs/assets/hero.tape docs/assets/hero.gif"
echo "   git commit -m 'docs(assets): add hero GIF via VHS mock recording'"
