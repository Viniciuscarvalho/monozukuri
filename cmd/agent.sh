#!/bin/bash
# cmd/agent.sh — sub_agent(): manage coding-agent adapters
# Sourced by orchestrate.sh; inherits SCRIPT_DIR, LIB_DIR, CMD_DIR,
# SCRIPTS_DIR, TEMPLATES_DIR, PROJECT_ROOT, ROOT_DIR, CONFIG_DIR,
# STATE_DIR, RESULTS_DIR, and all OPT_* variables.
#
# Subcommands:
#   monozukuri agent list            — list all available adapters and their status
#   monozukuri agent doctor [name]   — check install/auth for all or one adapter
#   monozukuri agent enable <name>   — write agent: <name> into .monozukuri/config.yaml

sub_agent() {
  local agent_subcmd="${OPT_AGENT_SUBCMD:-list}"
  local agent_name_arg="${OPT_AGENT_NAME:-}"

  source "$LIB_DIR/core/modules.sh"
  modules_init "$LIB_DIR"
  module_require core/util
  module_require cli/output
  source "$LIB_DIR/agent/contract.sh"

  case "$agent_subcmd" in
    list)   _agent_list ;;
    doctor) _agent_doctor "${agent_name_arg:-}" ;;
    enable) _agent_enable "${agent_name_arg:?'Usage: monozukuri agent enable <name>'}" ;;
    *)
      err "Unknown agent subcommand: $agent_subcmd"
      info "Available: list, doctor [name], enable <name>"
      exit 1
      ;;
  esac
}

# ── list ─────────────────────────────────────────────────────────────────────

_agent_list() {
  local active="${MONOZUKURI_AGENT:-claude-code}"
  printf '%-15s %-10s %s\n' "AGENT" "STATUS" "BINARY"
  printf '%-15s %-10s %s\n' "-----" "------" "------"

  local name
  while IFS= read -r name; do
    local status="unknown" binary=""
    case "$name" in
      claude-code) binary="claude" ;;
      codex)       binary="codex" ;;
      gemini)      binary="gemini" ;;
      kiro)        binary="kiro" ;;
      *)           binary="$name" ;;
    esac

    if command -v "$binary" &>/dev/null; then
      status="installed"
    else
      status="not found"
    fi

    local marker=""
    [ "$name" = "$active" ] && marker=" *"
    printf '%-15s %-10s %s%s\n' "$name" "$status" "$binary" "$marker"
  done < <(agent_list)

  echo ""
  echo "(* = active agent from config)"
}

# ── doctor ────────────────────────────────────────────────────────────────────

_agent_doctor() {
  local target="$1"
  local names

  if [ -n "$target" ]; then
    names="$target"
  else
    names=$(agent_list)
  fi

  local any_fail=0
  local name
  while IFS= read -r name; do
    [ -z "$name" ] && continue
    printf "Checking %s ... " "$name"
    if agent_load "$name" 2>/dev/null && agent_doctor 2>/dev/null; then
      printf "ok\n"
    else
      printf "FAILED\n"
      any_fail=1
    fi
    # Reset adapter functions for next iteration
    unset -f agent_name agent_capabilities agent_doctor \
              agent_estimate_tokens agent_run_phase agent_report_cost 2>/dev/null || true
  done <<< "$names"

  return "$any_fail"
}

# ── enable ────────────────────────────────────────────────────────────────────

_agent_enable() {
  local name="$1"
  local config_file="${OPT_CONFIG:-.monozukuri/config.yaml}"

  if [ ! -f "$config_file" ]; then
    err "No config found at $config_file — run 'monozukuri init' first"
    exit 1
  fi

  local available_agents
  available_agents=$(agent_list)
  if ! echo "$available_agents" | grep -qx "$name"; then
    err "Unknown agent: $name"
    info "Available: $(echo "$available_agents" | tr '\n' ' ')"
    exit 1
  fi

  if grep -q "^agent:" "$config_file"; then
    sed -i.bak "s|^agent:.*|agent: $name|" "$config_file" && rm -f "${config_file}.bak"
  else
    printf '\nagent: %s\n' "$name" >> "$config_file"
  fi

  info "Active agent set to: $name"
  info "Run 'monozukuri agent doctor $name' to verify the installation."
}
