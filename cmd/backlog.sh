#!/bin/bash
# cmd/backlog.sh — backlog inspection commands

_backlog_help() {
  cat <<'EOF'
Usage: monozukuri backlog list [--format table|json|csv] [--limit N]

List backlog items ranked by priority, then age.

Flags:
  --format table|json|csv   Output format (default: table)
  --limit N                 Maximum items to print (default: 50, max: 500)
  --help                    Show this help
EOF
}

sub_backlog() {
  local action="${OPT_BACKLOG_ACTION:-list}"
  case "$action" in
    list) sub_backlog_list ;;
    ""|help|--help|-h) _backlog_help ;;
    *)
      err "Unknown backlog action: $action"
      _backlog_help >&2
      return 2
      ;;
  esac
}

sub_backlog_list() {
  local format="${OPT_BACKLOG_FORMAT:-table}"
  local limit="${OPT_BACKLOG_LIMIT:-50}"

  case "$format" in
    table|json|csv) ;;
    *)
      err "Invalid --format: $format (expected: table, json, csv)"
      return 2
      ;;
  esac
  if ! [[ "$limit" =~ ^[0-9]+$ ]] || [ "$limit" -lt 1 ] || [ "$limit" -gt 500 ]; then
    err "Invalid --limit: expected integer from 1 to 500"
    return 2
  fi

  source "$LIB_DIR/core/modules.sh"
  modules_init "$LIB_DIR"
  module_require config/load

  local config_file="$OPT_CONFIG"
  if [ ! -f "$config_file" ]; then
    if [ -f ".monozukuri/config.yaml" ]; then
      config_file=".monozukuri/config.yaml"
    elif [ -f ".monozukuri/config.yml" ]; then
      config_file=".monozukuri/config.yml"
    elif [ -f "$TEMPLATES_DIR/config.yaml" ]; then
      config_file="$TEMPLATES_DIR/config.yaml"
    fi
  fi

  if [ ! -f "$config_file" ]; then
    err "Config not found: $OPT_CONFIG"
    info "Run: monozukuri init"
    return 1
  fi

  load_config "$config_file"

  local adapter_out count backlog_file
  adapter_out=$(run_adapter)
  count=$(echo "$adapter_out" | grep -Eo '^[0-9]+$' | tail -1 || true)
  backlog_file="$ROOT_DIR/$BACKLOG_OUTPUT"

  if [ "${count:-0}" -eq 0 ] && [ "$format" = "table" ]; then
    node "$LIB_DIR/backlog/list.js" --file "$backlog_file" --format "$format" --limit "$limit"
    return 0
  fi

  node "$LIB_DIR/backlog/list.js" --file "$backlog_file" --format "$format" --limit "$limit"
}
