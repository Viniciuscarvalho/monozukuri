#!/bin/bash
# cmd/pick.sh — backlog selection for JSON scripts and interactive TUI

set -euo pipefail

_pick_help() {
  cat <<'EOF'
Usage:
  monozukuri pick
  monozukuri pick --top N [filters]
  monozukuri pick --json [--top N] [filters]

Pick top-ranked backlog items for scripts and CI.

Flags:
  --json                    Emit JSON array output instead of TUI
  --top N                   Emit top-ranked IDs without opening TUI (max: 50)
  --label foo,bar           Include items with any listed label
  --status ready|blocked|in-progress|done
                            Include items by status (default: ready)
  --exclude-blocked         Shortcut for --status ready
  --agent claude-code|codex|gemini
                            Include items explicitly compatible with an agent
  --help                    Show this help
EOF
}

sub_pick() {
  local json="${OPT_JSON:-false}"
  local default_top="30"
  [ "$json" = "true" ] && default_top="5"
  local requested_top="${OPT_PICK_TOP:-}"
  local top="${OPT_PICK_TOP:-$default_top}"
  local label="${OPT_BACKLOG_LABEL:-}"
  local status="${OPT_BACKLOG_STATUS:-ready}"
  local agent="${OPT_BACKLOG_AGENT:-}"

  if ! [[ "$top" =~ ^[0-9]+$ ]] || [ "$top" -lt 1 ] || [ "$top" -gt 50 ]; then
    err "Invalid --top: expected integer from 1 to 50"
    return 2
  fi
  case "$status" in
    ready|blocked|in-progress|done) ;;
    *)
      err "Invalid --status: $status (expected: ready, blocked, in-progress, done)"
      return 2
      ;;
  esac
  case "$agent" in
    ""|claude-code|codex|gemini) ;;
    *)
      err "Invalid --agent: $agent (expected: claude-code, codex, gemini)"
      return 2
      ;;
  esac

  # Reuse backlog adapter resolution and config/scoring exports.
  # shellcheck source=cmd/backlog.sh
  source "$CMD_DIR/backlog.sh"
  _backlog_adapter_output_file

  local args=(--file "$BACKLOG_ADAPTER_OUTPUT_FILE" --top "$top" --status "$status")
  [ -n "$label" ] && args+=(--label "$label")
  [ -n "$agent" ] && args+=(--agent "$agent")

  if [ "$json" = "true" ]; then
    node "$LIB_DIR/backlog/list.js" --pick "${args[@]}"
    return
  fi

  if [ -n "$requested_top" ]; then
    node "$LIB_DIR/backlog/list.js" --pick "${args[@]}" |
      node -e 'const fs = require("fs"); const items = JSON.parse(fs.readFileSync(0, "utf8")); process.stdout.write(items.map((item) => item.id).join("\n")); if (items.length) process.stdout.write("\n");'
    return
  fi

  local tui_script="${MONOZUKURI_HOME:-$SCRIPT_DIR}/ui/dist/pick.js"
  if [ ! -f "$tui_script" ]; then
    err "Interactive pick TUI is not built. Run: npm run build --prefix ui"
    return 11
  fi

  local tmpfile
  tmpfile="$(mktemp -t monozukuri-pick.XXXXXX.json)"
  trap "rm -f '$tmpfile'" RETURN
  node "$LIB_DIR/backlog/list.js" --pick-card "${args[@]}" > "$tmpfile"

  if [ ! -t 0 ] && [ -z "${MONOZUKURI_PICK_TEST_KEYS:-}" ]; then
    err "Interactive pick requires a TTY. Use: monozukuri pick --json"
    return 2
  fi

  node "$tui_script" "$tmpfile"
}
