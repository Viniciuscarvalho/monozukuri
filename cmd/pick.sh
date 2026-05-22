#!/bin/bash
# cmd/pick.sh — backlog selection for JSON scripts and interactive TUI

set -euo pipefail

_pick_help() {
  cat <<'EOF'
Usage:
  monozukuri pick
  monozukuri pick --top N [filters]
  monozukuri pick --json [--top N] [filters]
  monozukuri pick --replay [N]
  monozukuri pick --history

Pick top-ranked backlog items for scripts and CI.

Flags:
  --json                    Emit JSON array output instead of TUI
  --top N                   Emit top-ranked IDs without opening TUI (max: 50)
  --replay [N]              Print the Nth latest pick selection (default: 1)
  --history                 List the latest 20 pick selections
  --label foo,bar           Include items with any listed label
  --status ready|blocked|in-progress|done
                            Include items by status (default: ready)
  --exclude-blocked         Shortcut for --status ready
  --agent claude-code|codex|gemini
                            Include items explicitly compatible with an agent
  --help                    Show this help
EOF
}

_pick_history_file() {
  printf '%s\n' "${STATE_DIR:-.monozukuri/state}/pick-history.jsonl"
}

_pick_history_user() {
  printf '%s\n' "${USER:-${LOGNAME:-unknown}}"
}

_pick_history_record() {
  local source="$1"
  shift
  [ "$#" -gt 0 ] || return 0

  local history_file history_dir tmpfile
  history_file="$(_pick_history_file)"
  history_dir="$(dirname "$history_file")"
  mkdir -p "$history_dir"
  local ids_csv
  ids_csv="$(IFS=,; printf '%s' "$*")"

  tmpfile="$(mktemp -t monozukuri-pick-history.XXXXXX)"
  if [ -f "$history_file" ]; then
    tail -n 99 "$history_file" > "$tmpfile"
  fi
  node -e '
    const entry = {
      timestamp: new Date().toISOString(),
      ids: process.argv[1].split(",").filter(Boolean),
      source: process.argv[2],
      user: process.argv[3] || "unknown",
    };
    process.stdout.write(JSON.stringify(entry) + "\n");
  ' "$ids_csv" "$source" "$(_pick_history_user)" >> "$tmpfile"
  mv "$tmpfile" "$history_file"
}

_pick_ids_from_json() {
  node -e 'const fs = require("fs"); const items = JSON.parse(fs.readFileSync(0, "utf8")); const ids = items.map((item) => item.id); process.stdout.write(ids.join("\n")); if (ids.length) process.stdout.write("\n");'
}

_pick_history_replay() {
  local offset="${1:-1}"
  if ! [[ "$offset" =~ ^[0-9]+$ ]] || [ "$offset" -lt 1 ]; then
    err "Invalid --replay: expected positive integer"
    return 2
  fi

  local history_file
  history_file="$(_pick_history_file)"
  if [ ! -s "$history_file" ]; then
    err "No pick history found. Run monozukuri pick --top N or monozukuri pick first."
    return 2
  fi

  node -e '
    const fs = require("fs");
    const offset = Number(process.argv[2]);
    const lines = fs.readFileSync(process.argv[1], "utf8").trim().split("\n").filter(Boolean);
    const raw = lines[lines.length - offset];
    if (!raw) process.exit(3);
    const entry = JSON.parse(raw);
    process.stdout.write((entry.ids || []).join("\n"));
    if ((entry.ids || []).length) process.stdout.write("\n");
  ' "$history_file" "$offset" || {
    err "No pick history entry found for --replay $offset"
    return 2
  }
}

_pick_history_list() {
  local history_file
  history_file="$(_pick_history_file)"
  if [ ! -s "$history_file" ]; then
    printf 'No pick history found. Run monozukuri pick first.\n'
    return 0
  fi

  node -e '
    const fs = require("fs");
    const lines = fs.readFileSync(process.argv[1], "utf8").trim().split("\n").filter(Boolean);
    const entries = lines.slice(-20).map((line) => JSON.parse(line));
    console.log("WHEN                 SOURCE    USER      IDS");
    for (const entry of entries) {
      const when = String(entry.timestamp || "").slice(0, 19).padEnd(20);
      const source = String(entry.source || "").padEnd(9);
      const user = String(entry.user || "").padEnd(9);
      const ids = Array.isArray(entry.ids) ? entry.ids.join(",") : "";
      console.log(`${when} ${source} ${user} ${ids}`);
    }
  ' "$history_file"
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

  if [ -n "${OPT_PICK_REPLAY:-}" ]; then
    _pick_history_replay "$OPT_PICK_REPLAY"
    return
  fi

  if [ "${OPT_PICK_HISTORY:-false}" = "true" ]; then
    _pick_history_list
    return
  fi

  if [ -n "${OPT_PICK_IDS:-}" ]; then
    local explicit_ids
    explicit_ids="${OPT_PICK_IDS//,/ }"
    _pick_history_record "explicit" $explicit_ids
    printf '%s\n' $explicit_ids
    return
  fi

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
    local json_output json_ids
    json_output="$(node "$LIB_DIR/backlog/list.js" --pick "${args[@]}")"
    json_ids="$(printf '%s' "$json_output" | _pick_ids_from_json)"
    if [ -n "$json_ids" ]; then
      _pick_history_record "top" $json_ids
    fi
    printf '%s\n' "$json_output"
    return
  fi

  if [ -n "$requested_top" ]; then
    local ids
    ids="$(node "$LIB_DIR/backlog/list.js" --pick "${args[@]}" | _pick_ids_from_json)"
    if [ -n "$ids" ]; then
      _pick_history_record "top" $ids
      printf '%s\n' "$ids"
    fi
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

  local tui_output tui_exit=0
  tui_output="$(node "$tui_script" "$tmpfile")" || tui_exit=$?
  if [ "$tui_exit" -eq 0 ] && [ -n "$tui_output" ]; then
    _pick_history_record "tui" $tui_output
    printf '%s\n' "$tui_output"
  fi
  return "$tui_exit"
}
