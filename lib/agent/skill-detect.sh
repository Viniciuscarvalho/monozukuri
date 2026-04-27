#!/bin/bash
# lib/agent/skill-detect.sh — Phase-to-skill mapping and installation detection.
#
# Used by adapter-*.sh to decide whether to invoke a native mz-* skill
# or fall back to the template-render or legacy feature-marker paths.
#
# Public functions:
#   phase_to_skill <phase>                       → mz-* skill name or ""
#   skill_installed <agent-id> <skill> <wt-path> → exit 0 if installed, 1 otherwise

# Map pipeline phase name to its mz-* skill name.
# Returns empty string for unknown or unmapped phases.
phase_to_skill() {
  case "$1" in
    prd)      echo "mz-create-prd" ;;
    techspec) echo "mz-create-techspec" ;;
    tasks)    echo "mz-create-tasks" ;;
    code)     echo "mz-execute-task" ;;
    tests)    echo "mz-run-tests" ;;
    pr)       echo "mz-open-pr" ;;
    *)        echo "" ;;
  esac
}

# skill_installed <agent-id> <skill-name> <wt-path>
# Exit 0 if SKILL.md is present at the project-local or global install path.
# Exit 1 otherwise.
# Detection mirrors the install paths from lib/setup/detect.sh.
skill_installed() {
  local agent_id="$1" skill="$2" wt_path="${3:-$(pwd)}"

  case "$agent_id" in
    claude-code)
      [ -f "${wt_path}/.claude/skills/${skill}/SKILL.md" ] && return 0
      local global_dir="${CLAUDE_CONFIG_DIR:-${HOME}/.claude}"
      [ -f "${global_dir}/skills/${skill}/SKILL.md" ] && return 0
      ;;
    cursor|gemini-cli|codex)
      [ -f "${wt_path}/.agents/skills/${skill}/SKILL.md" ] && return 0
      [ -f "${HOME}/.agents/skills/${skill}/SKILL.md" ] && return 0
      ;;
  esac
  return 1
}
