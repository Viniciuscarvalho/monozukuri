#!/bin/bash
# cmd/setup.sh — monozukuri setup: install skills into coding agents
# Contains sub_setup(); sourced by orchestrate.sh and dispatched.
#
# Usage:
#   monozukuri setup                         detect agents, install interactively
#   monozukuri setup --all --yes             install into all detected agents
#   monozukuri setup --agent claude-code     install into one agent
#   monozukuri setup --global                install globally (~/.agent/skills/)
#   monozukuri setup --copy                  copy files instead of symlinking
#   monozukuri setup --list                  list bundled skills, no install
#   monozukuri setup --dry-run               show what would happen
#   monozukuri setup --status                show current install state
#   monozukuri setup --uninstall             remove monozukuri-installed skills
#   monozukuri setup --force                 overwrite foreign/drifted skills

source "$LIB_DIR/setup/detect.sh"
source "$LIB_DIR/setup/install.sh"
source "$LIB_DIR/cli/colors.sh" 2>/dev/null || true

_setup_pass() { printf "  ${C_GREEN:-}✓${C_NC:-} %s\n" "$1"; }
_setup_info() { printf "  ${C_DIM:-}→${C_NC:-} %s\n" "$1"; }
_setup_warn() { printf "  ${C_YELLOW:-}⚠${C_NC:-} %s\n" "$*" >&2; }

sub_setup() {
  # ── action: --list ────────────────────────────────────────────────────
  if [ "${OPT_SETUP_ACTION:-}" = "list" ]; then
    printf "\n${C_BOLD:-}Available skills${C_NC:-}\n\n"
    local skill
    while IFS= read -r skill; do
      local src
      src="$(setup_skills_source_dir)/$skill"
      local desc=""
      desc=$(awk '/^description:/{found=1; next} found && /^---/{exit} found{print; exit}' \
               "$src/SKILL.md" 2>/dev/null | sed 's/^[[:space:]]*//')
      # Fallback: extract description value from frontmatter
      if [ -z "$desc" ]; then
        desc=$(grep '^description:' "$src/SKILL.md" 2>/dev/null | \
               sed 's/^description:[[:space:]]*//' | head -1)
      fi
      printf "  %-30s  %s\n" "$skill" "${desc:-(no description)}"
    done < <(setup_skills_list)
    echo ""
    return 0
  fi

  # ── action: --status ──────────────────────────────────────────────────
  if [ "${OPT_SETUP_ACTION:-}" = "status" ]; then
    local agents
    agents="$(_setup_resolve_agents)"
    [ -z "$agents" ] && { _setup_warn "No agents detected. Use --agent <id> to specify one."; return 1; }
    echo ""
    local flags=()
    [ "${OPT_SETUP_GLOBAL:-false}" = "true" ] && flags+=(--global)
    setup_status "$agents" "all" "${flags[@]}"
    echo ""
    return 0
  fi

  # ── action: --uninstall ───────────────────────────────────────────────
  if [ "${OPT_SETUP_ACTION:-}" = "uninstall" ]; then
    local agents
    agents="$(_setup_resolve_agents)"
    [ -z "$agents" ] && { _setup_warn "No agents detected. Use --agent <id> to specify one."; return 1; }
    _setup_confirm_agents "uninstall from" "$agents" || return 0
    echo ""
    local flags=(--dry-run)
    [ "${OPT_SETUP_GLOBAL:-false}" = "true" ] && flags+=(--global)
    [ "${OPT_DRY_RUN:-false}" = "true" ] && {
      printf "${C_BOLD:-}Dry run — no changes will be made.${C_NC:-}\n\n"
      setup_uninstall "$agents" "all" "${flags[@]}"
      return 0
    }
    flags=()
    [ "${OPT_SETUP_GLOBAL:-false}" = "true" ] && flags+=(--global)
    setup_uninstall "$agents" "all" "${flags[@]}"
    echo ""
    _setup_pass "Uninstall complete."
    return 0
  fi

  # ── default action: install ───────────────────────────────────────────
  banner "monozukuri setup — install skills"

  local agents
  agents="$(_setup_resolve_agents)"
  if [ -z "$agents" ]; then
    _setup_warn "No agents detected on this machine."
    printf "\nSupported agents: %s\n" "$(setup_all_agents)"
    printf "Use --agent <id> to force install for a specific agent.\n\n"
    return 1
  fi

  _setup_confirm_agents "install into" "$agents" || return 0

  local flags=()
  [ "${OPT_SETUP_GLOBAL:-false}" = "true" ] && flags+=(--global)
  [ "${OPT_SETUP_COPY:-false}" = "true" ]   && flags+=(--copy)
  [ "${OPT_DRY_RUN:-false}" = "true" ]      && flags+=(--dry-run)
  [ "${OPT_SETUP_FORCE:-false}" = "true" ]  && flags+=(--force)

  if [ "${OPT_DRY_RUN:-false}" = "true" ]; then
    printf "${C_BOLD:-}Dry run — no changes will be made.${C_NC:-}\n\n"
  fi

  echo ""
  setup_install "$agents" "all" "${flags[@]}"

  echo ""
  if [ "${OPT_DRY_RUN:-false}" = "true" ]; then
    _setup_info "Dry run complete — no changes made."
  else
    _setup_pass "Setup complete."
    _setup_info "Run 'monozukuri setup --status' to verify."
  fi
}

# ── helpers ───────────────────────────────────────────────────────────────────

# Resolve the agents to operate on: --agent flag, --all flag, or auto-detect.
_setup_resolve_agents() {
  local agent_flag="${OPT_SETUP_AGENT:-}"
  local all_flag="${OPT_SETUP_ALL:-false}"

  if [ -n "$agent_flag" ]; then
    # Validate the requested agent ID
    local known
    known="$(setup_all_agents)"
    if echo "$known" | grep -qw "$agent_flag"; then
      echo "$agent_flag"
    else
      _setup_warn "Unknown agent: $agent_flag. Supported: $known"
      return 1
    fi
  elif [ "$all_flag" = "true" ]; then
    setup_all_agents
  else
    setup_detected_agents
  fi
}

# Print the list of agents and ask for confirmation (skipped with --yes).
_setup_confirm_agents() {
  local verb="$1" agents="$2"
  local yes="${OPT_SETUP_YES:-false}"
  local mode="project-local"
  [ "${OPT_SETUP_GLOBAL:-false}" = "true" ] && mode="global"

  printf "\nAgents (%s): " "$mode"
  local ag
  for ag in $agents; do
    printf "  %s (%s)" "$ag" "$(setup_agent_name "$ag")"
  done
  printf "\n\n"

  if [ "$yes" = "true" ] || [ "${OPT_DRY_RUN:-false}" = "true" ]; then
    return 0
  fi

  if [ -t 0 ]; then
    printf "Proceed to %s the agents listed above? [y/N] " "$verb"
    local answer
    read -r answer
    case "$answer" in
      y|Y|yes|YES) return 0 ;;
      *) printf "Aborted.\n"; return 1 ;;
    esac
  fi
  return 0
}

