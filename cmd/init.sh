#!/bin/bash
# cmd/init.sh — sub_init(): scaffold project config and starter files
# Sourced by orchestrate.sh; inherits SCRIPT_DIR, LIB_DIR, CMD_DIR,
# SCRIPTS_DIR, TEMPLATES_DIR, PROJECT_ROOT, ROOT_DIR, CONFIG_DIR,
# STATE_DIR, RESULTS_DIR, and all OPT_* variables.

sub_init() {
  banner "Initializing orchestrator in $(basename "$PROJECT_ROOT")"

  mkdir -p .monozukuri/{results,context,logs}

  # Copy templates from wherever the orchestrator is installed
  if [ ! -f .monozukuri/config.yaml ]; then
    if [ -f "$TEMPLATES_DIR/config.yaml" ]; then
      cp "$TEMPLATES_DIR/config.yaml" .monozukuri/config.yaml
    else
      cat > .monozukuri/config.yaml <<'EOCFG'
source:
  adapter: markdown
  output: orchestration-backlog.json
  markdown:
    file: features.md

autonomy: checkpoint

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

skill:
  command: feature-marker

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

  echo ""
  echo "Next steps:"
  echo "  1. cp .env.example .env && vim .env"
  echo "  2. vim .monozukuri/config.yaml"
  echo "  3. vim features.md"
  echo "  4. monozukuri --dry-run"
  echo "  5. monozukuri"
}
