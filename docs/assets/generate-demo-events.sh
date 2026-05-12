#!/usr/bin/env bash
# docs/assets/generate-demo-events.sh — Synthesizes a realistic events.jsonl
# for the dashboard screenshot (docs/assets/dashboard.png).
#
# Usage:
#   docs/assets/generate-demo-events.sh
#
# What it does:
#   1. Writes ~/.monozukuri/runs/demo-screenshot/events.jsonl
#   2. Launches monozukuri ui demo-screenshot (opens browser automatically)
#   3. Prints a reminder to take the screenshot and save it
#
# After the browser opens:
#   - Wait for the dashboard to render fully (~1s)
#   - Window size: 1440x900 (or full-screen the browser, then trim)
#   - Capture: Cmd+Shift+4 (macOS) or screencapture -i docs/assets/dashboard.png
#   - Close the dashboard with Ctrl-C when done

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

RUN_ID="demo-screenshot"
RUN_DIR="$HOME/.monozukuri/runs/$RUN_ID"
EVENTS_FILE="$RUN_DIR/events.jsonl"

mkdir -p "$RUN_DIR"

# ── timestamp helpers ─────────────────────────────────────────────────────────
# Events span the last ~8 minutes to look like an active full_auto run.
now=$(date -u +%s)

ts() {
  # ts <seconds-ago>
  date -u -r $(( now - $1 )) +"%Y-%m-%dT%H:%M:%SZ" 2>/dev/null \
    || date -u -d "@$(( now - $1 ))" +"%Y-%m-%dT%H:%M:%SZ"
}

emit() {
  # emit <type> <feature_id> [extra key=value pairs...]
  local type="$1" feat="$2"; shift 2
  local extra=""
  while [ $# -ge 2 ]; do
    extra="${extra},\"$1\":\"$2\""
    shift 2
  done
  printf '{"type":"%s","ts":"%s","run_id":"%s","agent":"claude-code","feature_id":"%s"%s}\n' \
    "$type" "$(ts "${_ts:-0}")" "$RUN_ID" "$feat" "$extra"
}

# ── write events ──────────────────────────────────────────────────────────────
{

# ─── feature 1: add-dry-run-colors ────────────────────────────────────────────
_ts=480; emit feature.queued   add-dry-run-colors
_ts=479; emit feature.started  add-dry-run-colors

_ts=478; emit phase.started    add-dry-run-colors phase prd
_ts=462; emit tool.invoked     add-dry-run-colors tool Write
_ts=461; emit file.touched     add-dry-run-colors path "tasks/prd-add-dry-run-colors/prd.md"
_ts=460; emit tool.completed   add-dry-run-colors tool Write
_ts=458; emit phase.completed  add-dry-run-colors phase prd   duration_ms 20000 tokens_used 4200

_ts=457; emit phase.started    add-dry-run-colors phase techspec
_ts=440; emit tool.invoked     add-dry-run-colors tool Write
_ts=439; emit file.touched     add-dry-run-colors path "tasks/prd-add-dry-run-colors/techspec.md"
_ts=438; emit tool.completed   add-dry-run-colors tool Write
_ts=436; emit phase.completed  add-dry-run-colors phase techspec duration_ms 21000 tokens_used 5800

_ts=435; emit phase.started    add-dry-run-colors phase tasks
_ts=420; emit tool.invoked     add-dry-run-colors tool Write
_ts=419; emit file.touched     add-dry-run-colors path "tasks/prd-add-dry-run-colors/tasks.json"
_ts=418; emit tool.completed   add-dry-run-colors tool Write
_ts=416; emit phase.completed  add-dry-run-colors phase tasks   duration_ms 19000 tokens_used 3100

_ts=415; emit phase.started    add-dry-run-colors phase code
_ts=400; emit tool.invoked     add-dry-run-colors tool Write
_ts=390; emit file.touched     add-dry-run-colors path "lib/cli/output.sh"
_ts=385; emit tool.invoked     add-dry-run-colors tool Write
_ts=380; emit file.touched     add-dry-run-colors path "lib/cli/colors.sh"
_ts=375; emit tool.invoked     add-dry-run-colors tool Edit
_ts=370; emit file.touched     add-dry-run-colors path "cmd/run.sh"

# feature 1 is currently in the code phase (still running)

# ─── feature 2: add-max-tokens-flag ───────────────────────────────────────────
_ts=370; emit feature.queued   add-max-tokens-flag
_ts=365; emit feature.started  add-max-tokens-flag

_ts=364; emit phase.started    add-max-tokens-flag phase prd
_ts=348; emit tool.invoked     add-max-tokens-flag tool Write
_ts=347; emit file.touched     add-max-tokens-flag path "tasks/prd-add-max-tokens-flag/prd.md"
_ts=346; emit tool.completed   add-max-tokens-flag tool Write
_ts=344; emit phase.completed  add-max-tokens-flag phase prd   duration_ms 20000 tokens_used 3900

_ts=343; emit phase.started    add-max-tokens-flag phase techspec
_ts=320; emit tool.invoked     add-max-tokens-flag tool Write
_ts=319; emit file.touched     add-max-tokens-flag path "tasks/prd-add-max-tokens-flag/techspec.md"
_ts=318; emit tool.completed   add-max-tokens-flag tool Write
_ts=316; emit phase.completed  add-max-tokens-flag phase techspec duration_ms 27000 tokens_used 6100

_ts=315; emit phase.started    add-max-tokens-flag phase tasks

# feature 2 is currently in the tasks phase (still running)

# ─── a few recent cross-feature events to populate the log ────────────────────
_ts=60;  emit tool.invoked     add-dry-run-colors  tool Bash
_ts=55;  emit tool.completed   add-dry-run-colors  tool Bash
_ts=45;  emit tool.invoked     add-max-tokens-flag tool Write
_ts=42;  emit file.touched     add-max-tokens-flag path "tasks/prd-add-max-tokens-flag/tasks.json"
_ts=38;  emit tool.completed   add-max-tokens-flag tool Write
_ts=30;  emit tool.invoked     add-dry-run-colors  tool Edit
_ts=25;  emit file.touched     add-dry-run-colors  path "test/unit/output.bats"
_ts=20;  emit tool.completed   add-dry-run-colors  tool Edit
_ts=12;  emit tool.invoked     add-max-tokens-flag tool Write
_ts=8;   emit file.touched     add-max-tokens-flag path "tasks/prd-add-max-tokens-flag/tasks.json"
_ts=5;   emit tool.completed   add-max-tokens-flag tool Write

} > "$EVENTS_FILE"

echo "→ Wrote $(wc -l < "$EVENTS_FILE") events to $EVENTS_FILE"
echo ""

# ── launch dashboard ──────────────────────────────────────────────────────────
MZ_CMD=""
if command -v monozukuri &>/dev/null; then
  MZ_CMD=monozukuri
elif [ -x "$REPO_ROOT/orchestrate.sh" ]; then
  MZ_CMD="$REPO_ROOT/orchestrate.sh"
else
  echo "ERROR: monozukuri not found — install first" >&2
  exit 1
fi

echo "→ Launching dashboard for run: $RUN_ID"
echo "   (browser will open automatically)"
echo ""
echo "   To capture the screenshot:"
echo "   1. Wait for the dashboard to render (~1 second)"
echo "   2. Resize the browser to approximately 1440×900"
echo "   3. Run in a second terminal:"
echo "      screencapture -w $REPO_ROOT/docs/assets/dashboard.png"
echo "      (or use Cmd+Shift+4, then move to docs/assets/dashboard.png)"
echo ""
echo "   Press Ctrl-C here when done."
echo ""

$MZ_CMD ui "$RUN_ID"
