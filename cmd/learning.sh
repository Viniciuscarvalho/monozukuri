#!/bin/bash
# cmd/learning.sh — sub_learning() and sub_promote_learning() (ADR-008 PR-C)
# Sourced by orchestrate.sh; inherits SCRIPT_DIR, LIB_DIR, CMD_DIR,
# SCRIPTS_DIR, TEMPLATES_DIR, PROJECT_ROOT, ROOT_DIR, CONFIG_DIR,
# STATE_DIR, RESULTS_DIR, and all OPT_* variables.

sub_learning() {
  source "$LIB_DIR/config/load.sh"
  source "$LIB_DIR/memory/learning.sh"

  local config_file="$OPT_CONFIG"
  if [ ! -f "$config_file" ]; then
    [ -f ".monozukuri/config.yaml" ] && config_file=".monozukuri/config.yaml"
    [ -f ".monozukuri/config.yml"  ] && config_file=".monozukuri/config.yml"
    [ -f "$TEMPLATES_DIR/config.yaml" ] && config_file="$TEMPLATES_DIR/config.yaml"
  fi
  load_config "$config_file" 2>/dev/null || true

  local project_path="$ROOT_DIR/.claude/feature-state/learned.json"
  local global_path="$HOME/.claude/monozukuri/learned/learned.json"

  _learning_ensure_file "$global_path"

  case "${OPT_LEARNING_ACTION:-list}" in
    list)
      banner "Learning Entries (project tier)"
      learning_list "$project_path" "$OPT_LEARNING_CANDIDATES"
      ;;
    archive)
      if [ -z "$OPT_LEARNING_ID" ]; then
        err "Usage: learning archive <id>"
        exit 1
      fi
      banner "Archive Learning Entry"
      learning_archive "$OPT_LEARNING_ID" "$project_path"
      ;;
    promote)
      if [ -z "$OPT_LEARNING_ID" ]; then
        err "Usage: learning promote <id>"
        exit 1
      fi
      banner "Promote Learning Entry to Global"
      learning_promote "$OPT_LEARNING_ID" "$project_path" "$global_path"
      ;;
    *)
      err "Unknown learning action: $OPT_LEARNING_ACTION"
      err "Available: list, archive <id>, promote <id>"
      exit 1
      ;;
  esac
}

sub_promote_learning() {
  if [ -z "$OPT_LEARNING_ID" ]; then
    err "Usage: promote-learning <id>"
    exit 1
  fi
  OPT_LEARNING_ACTION="promote"
  sub_learning
}
