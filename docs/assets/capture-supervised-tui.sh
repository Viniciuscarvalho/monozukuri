#!/usr/bin/env bash
# docs/assets/capture-supervised-tui.sh — Runs monozukuri in supervised mode
# with the mock agent and pauses at the TechSpec approval gate so you can
# capture a screenshot for docs/assets/supervised-tui.png.
#
# Usage:
#   docs/assets/capture-supervised-tui.sh
#
# Prerequisites:
#   monozukuri installed (brew, npm, or repo-dev)
#   ~/mz-hero-demo already created by record-hero.sh
#   (if not: cd ~/mz-hero-demo && monozukuri init)
#
# Steps:
#   1. This script starts a supervised run from ~/mz-hero-demo
#   2. The mock agent completes PRD within seconds
#   3. The TUI pauses at the TechSpec approval gate — DO NOT PRESS ANYTHING
#   4. In a second terminal, capture the screenshot:
#
#      screencapture -w /path/to/docs/assets/supervised-tui.png
#      (click the terminal window when the cursor changes)
#
#      Or: Cmd+Shift+4, draw a selection around the terminal window,
#      then move the file to docs/assets/supervised-tui.png
#
#   5. After capturing, come back here and press Enter (or 'y') to continue
#
# What the screenshot should show (per docs/execution.md:44):
#   - Top bar: active feature + current phase (TechSpec)
#   - Center pane: TechSpec output streaming from the mock skill
#   - Bottom bar: approval prompt + elapsed phase budget + token cost

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
MOCK_DIR="$REPO_ROOT/.qa/fixtures/mocks/claude"
DEMO_DIR="$HOME/mz-hero-demo"

# ── guards ────────────────────────────────────────────────────────────────────
if [ ! -x "$MOCK_DIR/claude" ]; then
  echo "ERROR: mock binary not found at $MOCK_DIR/claude" >&2
  exit 1
fi

if [ ! -d "$DEMO_DIR/.monozukuri" ]; then
  echo "ERROR: $DEMO_DIR/.monozukuri not found"
  echo "       Run docs/assets/record-hero.sh first to set up the demo repo." >&2
  exit 1
fi

# ── instructions ─────────────────────────────────────────────────────────────
cat <<'EOF'

  ┌──────────────────────────────────────────────────────────────┐
  │  Supervised TUI screenshot setup                             │
  ├──────────────────────────────────────────────────────────────┤
  │                                                              │
  │  The mock run will:                                          │
  │    1. Complete the PRD phase (a few seconds)                 │
  │    2. PAUSE at the TechSpec approval gate                    │
  │                                                              │
  │  When it pauses:                                             │
  │    • The TUI shows the approval prompt at the bottom         │
  │    • Open a second terminal and run:                         │
  │                                                              │
  │      screencapture -w docs/assets/supervised-tui.png        │
  │      (click this terminal window when prompted)              │
  │                                                              │
  │    • Or: Cmd+Shift+4 to draw a manual selection              │
  │                                                              │
  │  After capturing, press Enter (or y) in THIS terminal        │
  │  to continue the run through completion.                     │
  │                                                              │
  └──────────────────────────────────────────────────────────────┘

EOF

read -rp "  Ready? Press Enter to start the supervised run…" _

# ── run supervised with mock ──────────────────────────────────────────────────
export PATH="$MOCK_DIR:$PATH"
export MOCK_CLAUDE_MODE=normal
export MONOZUKURI_AGENT=claude-code

cd "$DEMO_DIR"

MZ_CMD=""
if command -v monozukuri &>/dev/null; then
  MZ_CMD=monozukuri
elif [ -x "$REPO_ROOT/orchestrate.sh" ]; then
  MZ_CMD="$REPO_ROOT/orchestrate.sh"
else
  echo "ERROR: monozukuri not found — install first" >&2
  exit 1
fi

echo ""
echo "→ Starting: monozukuri run --autonomy supervised"
echo "   Wait for the TechSpec gate, then capture the screenshot."
echo ""

$MZ_CMD run --autonomy supervised

echo ""
echo "→ Run complete."
echo ""
echo "   If you captured the screenshot, move it to:"
echo "   $REPO_ROOT/docs/assets/supervised-tui.png"
echo ""
echo "   Then commit:"
echo "   git add docs/assets/supervised-tui.png"
echo "   git commit -m 'docs(assets): add supervised TUI screenshot'"
