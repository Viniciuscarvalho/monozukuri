#!/bin/bash
# cmd/pick.sh — non-interactive JSON backlog selection

set -euo pipefail

_pick_help() {
  cat <<'EOF'
Usage:
  monozukuri pick [--json] [--top N] [filters]

Pick top-ranked backlog items for scripts and CI.

Flags:
  --json                    Emit JSON array output (default: IDs, one per line)
  --top N                   Maximum items to print (default: 5, max: 50)
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
  local top="${OPT_PICK_TOP:-5}"
  local label="${OPT_BACKLOG_LABEL:-}"
  local status="${OPT_BACKLOG_STATUS:-ready}"
  local agent="${OPT_BACKLOG_AGENT:-}"
  local pick_format="ids"
  [ "${OPT_JSON:-false}" = "true" ] && pick_format="json"

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

  local args=(--file "$BACKLOG_ADAPTER_OUTPUT_FILE" --pick --pick-format "$pick_format" --top "$top" --status "$status")
  [ -n "$label" ] && args+=(--label "$label")
  [ -n "$agent" ] && args+=(--agent "$agent")

  node "$LIB_DIR/backlog/list.js" "${args[@]}"
}
