#!/bin/bash
# cmd/init.sh — sub_init(): scaffold project config and starter files
# Sourced by orchestrate.sh; inherits SCRIPT_DIR, LIB_DIR, CMD_DIR,
# SCRIPTS_DIR, TEMPLATES_DIR, PROJECT_ROOT, ROOT_DIR, CONFIG_DIR,
# STATE_DIR, RESULTS_DIR, and all OPT_* variables.

sub_init() {
  # Interactive setup (TTY only; skipped when piped or --non-interactive)
  local _adapter="markdown" _autonomy="checkpoint" _model="opusplan" _agent="claude-code"

  # Detect which agents are installed
  source "$LIB_DIR/agent/contract.sh" 2>/dev/null || true
  local _available_agents
  _available_agents=$(agent_list 2>/dev/null || echo "claude-code")
  local _installed_agents=""
  local _ag
  while IFS= read -r _ag; do
    local _bin
    case "$_ag" in
      claude-code) _bin="claude" ;;
      codex)       _bin="codex" ;;
      gemini)      _bin="gemini" ;;
      kiro)        _bin="kiro" ;;
      *)           _bin="$_ag" ;;
    esac
    command -v "$_bin" &>/dev/null && _installed_agents="${_installed_agents:+$_installed_agents }$_ag"
  done <<< "$_available_agents"
  # Default to first installed agent (or claude-code if none detected)
  _agent="${_installed_agents%% *}"
  _agent="${_agent:-claude-code}"

  if [ -t 0 ] && [ "${OPT_NON_INTERACTIVE:-false}" != "true" ]; then
    if command -v gum >/dev/null 2>&1; then
      _adapter=$(gum choose --header "Which backlog adapter?" "markdown" "github" "linear")
      _autonomy=$(gum choose --header "Default autonomy level?" "checkpoint" "supervised" "full_auto")
      _model=$(gum choose --header "Default model?" "opusplan" "opus" "sonnet" "haiku")
      # Offer only installed agents; fall back to full list if detection found nothing
      local _agent_choices="${_installed_agents:-claude-code codex gemini kiro}"
      # shellcheck disable=SC2086
      _agent=$(gum choose --header "Which coding agent?" $_agent_choices)
    else
      printf "Adapter [markdown/github/linear] (default: markdown): "
      read -r _adapter; _adapter=${_adapter:-markdown}
      printf "Autonomy [supervised/checkpoint/full_auto] (default: checkpoint): "
      read -r _autonomy; _autonomy=${_autonomy:-checkpoint}
      printf "Model [opusplan/opus/sonnet/haiku] (default: opusplan): "
      read -r _model; _model=${_model:-opusplan}
      printf "Agent [claude-code/codex/gemini/kiro] (detected: %s, default: %s): " \
        "${_installed_agents:-none}" "$_agent"
      read -r _agent_input
      _agent="${_agent_input:-$_agent}"
    fi
  fi

  banner "Initializing orchestrator in $(basename "$PROJECT_ROOT")"

  mkdir -p .monozukuri/{results,context,logs}

  # Copy templates from wherever the orchestrator is installed
  if [ ! -f .monozukuri/config.yaml ]; then
    if [ -f "$TEMPLATES_DIR/config.yaml" ]; then
      cp "$TEMPLATES_DIR/config.yaml" .monozukuri/config.yaml
      # Patch adapter/autonomy/model into the copied template
      if command -v sed >/dev/null 2>&1; then
        sed -i.bak \
          -e "s/^  adapter: .*/  adapter: $_adapter/" \
          -e "s/^autonomy: .*/autonomy: $_autonomy/" \
          -e "s/^  default: .*/  default: $_model/" \
          -e "s/^agent: .*/agent: $_agent/" \
          .monozukuri/config.yaml && rm -f .monozukuri/config.yaml.bak
      fi
    else
      cat > .monozukuri/config.yaml <<EOCFG
source:
  adapter: $_adapter
  output: orchestration-backlog.json
  markdown:
    file: features.md

autonomy: $_autonomy

execution:
  base_branch: main
  skip_done: true
  skip_blocked: true

worktrees:
  base_path: .worktrees
  branch_prefix: feat
  auto_cleanup: true

memory:
  carry_forward_from: global-context.md
  error_pattern_window: 5
  env_refresh: true

safety:
  breaking_change_pause: true
  schema_migration_review: true
  max_file_changes: 50

pr_creation:
  strategy: draft
  auto_assign: true

discovery:
  enabled: true

model:
  default: $_model

agent: $_agent

routing:
  prefer_agents: true
EOCFG
    fi
    info "Created .monozukuri/config.yaml"
  else
    echo "  .monozukuri/config.yaml already exists"
  fi

  # .env.example
  if [ ! -f ".env.example" ]; then
    if [ -f "$TEMPLATES_DIR/env.example" ]; then
      cp "$TEMPLATES_DIR/env.example" .env.example
    else
      cat > .env.example <<'EOENV'
LINEAR_API_KEY=
JIRA_URL=
JIRA_EMAIL=
JIRA_TOKEN=
NOTION_TOKEN=
EOENV
    fi
    info "Created .env.example"
  fi

  # .env from template
  if [ ! -f ".env" ]; then
    cp .env.example .env 2>/dev/null || true
    info "Created .env from template"
  fi

  # Gitignore entries
  touch .gitignore
  if [ -f "$TEMPLATES_DIR/gitignore-entries.txt" ]; then
    while IFS= read -r entry; do
      [ -z "$entry" ] && continue
      [[ "$entry" == \#* ]] && continue
      grep -qxF "$entry" .gitignore || echo "$entry" >> .gitignore
    done < "$TEMPLATES_DIR/gitignore-entries.txt"
  else
    for entry in ".env" "orchestration-backlog.json" ".monozukuri/" ".worktrees/"; do
      grep -qxF "$entry" .gitignore || echo "$entry" >> .gitignore
    done
  fi
  info "Updated .gitignore"

  # Starter features.md
  if [ ! -f features.md ]; then
    cat > features.md <<'STARTER'
# Feature Backlog

## [FEAT] feat-001: Example feature
Describe what this feature should do.
- labels: example
- priority: high
STARTER
    info "Created features.md (starter)"
  fi

  _init_bootstrap_context "$_agent"

  echo ""
  echo "Next steps:"
  echo "  1. Fill in secrets: vim .env"
  echo "  2. Add features:    vim features.md"
  echo "  3. Preview plan:    monozukuri run --dry-run"
  echo "  4. Run:             monozukuri run"
}

# _init_bootstrap_context <agent>
# Detects the project stack and seeds per-adapter context files so agents
# are not blind on first run.  Called at the end of sub_init.
#
# Creates:
#   AGENTS.md          — always (marker-based merge; safe to re-run)
#   CLAUDE.md          — only if agent=claude-code and file is missing
#   GEMINI.md          — only if agent=gemini and file is missing
_init_bootstrap_context() {
  local agent="$1"
  local project_root="${PROJECT_ROOT:-.}"

  declare -f stack_profile_init &>/dev/null || \
    source "$LIB_DIR/core/stack-profile.sh" 2>/dev/null || true
  declare -f conventions_merge_write &>/dev/null || \
    source "$LIB_DIR/agent/conventions.sh" 2>/dev/null || true

  stack_profile_init "$project_root" 2>/dev/null || true
  local stack="${PROJECT_STACK:-unknown}"
  local test_cmd="${PROJECT_TEST_CMD:-}"
  local build_cmd="${PROJECT_BUILD_CMD:-}"
  local pkg_mgr="${PROJECT_PACKAGE_MANAGER:-unknown}"

  local tmp_block; tmp_block=$(mktemp)
  {
    printf '%s\n' '<!-- monozukuri:generated-start v1 -->'
    printf '%s\n\n' '<!-- Generated by monozukuri init -->'
    printf '%s\n\n' '## Project Stack'
    printf -- '- **Stack:** %s\n' "$stack"
    [ "$pkg_mgr" != "unknown" ] && printf -- '- **Package manager:** %s\n' "$pkg_mgr"
    [ -n "$test_cmd"  ] && printf -- '- **Test:** `%s`\n' "$test_cmd"
    [ -n "$build_cmd" ] && printf -- '- **Build:** `%s`\n' "$build_cmd"
    printf '\n%s\n' '<!-- monozukuri:generated-end -->'
  } > "$tmp_block"

  if declare -f conventions_merge_write &>/dev/null; then
    conventions_merge_write "$project_root" "$tmp_block" 2>/dev/null || true
    info "Created/updated AGENTS.md (stack: $stack)"
  fi
  rm -f "$tmp_block"

  case "$agent" in
    claude-code)
      if [ ! -f "$project_root/CLAUDE.md" ]; then
        _init_write_context_file "$project_root/CLAUDE.md" "$stack" "$test_cmd" "$build_cmd"
        info "Created CLAUDE.md"
      fi
      ;;
    gemini)
      if [ ! -f "$project_root/GEMINI.md" ]; then
        _init_write_context_file "$project_root/GEMINI.md" "$stack" "$test_cmd" "$build_cmd"
        info "Created GEMINI.md"
      fi
      ;;
  esac
}

# _init_write_context_file <path> <stack> <test_cmd> <build_cmd>
# Writes a minimal agent context file seeded with detected stack profile.
_init_write_context_file() {
  local path="$1" stack="$2" test_cmd="$3" build_cmd="$4"
  {
    printf '# Project Context\n\n'
    printf '<!-- Generated by monozukuri init — edit freely. -->\n\n'
    printf '## Stack\n\n'
    printf -- '- **Primary:** %s\n' "$stack"
    [ -n "$test_cmd"  ] && printf -- '- **Test:** `%s`\n' "$test_cmd"
    [ -n "$build_cmd" ] && printf -- '- **Build:** `%s`\n' "$build_cmd"
    printf '\n## Notes\n\nAdd project-specific conventions here.\n'
  } > "$path"
}
