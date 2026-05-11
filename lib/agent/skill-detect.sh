#!/bin/bash
# lib/agent/skill-detect.sh — Phase-to-skill mapping and installation detection.
#
# Used by adapter-*.sh to decide whether to invoke a native mz-* skill
# or fall back to the template-render path.
#
# Public functions:
#   phase_to_skill <phase> [agent_id]            → skill name or ""
#   skill_installed <agent-id> <skill> <wt-path> → exit 0 if installed, 1 otherwise
#   skill_allowed_tools <skill-name>             → comma-separated tools or ""

# Look up a project-installed skill mapped to the given phase.
# Reads MONOZUKURI_SKILLS_MANIFEST (or .monozukuri/skills-manifest.json under
# ROOT_DIR / PWD) produced by scripts/skill-discovery.sh. First skill whose
# `phases` array contains the requested phase wins.
# Empty output means "no matching skill in manifest" — callers fall through.
_skill_lookup_in_manifest() {
  local phase="$1" agent_id="${2:-claude-code}"
  local manifest="${MONOZUKURI_SKILLS_MANIFEST:-${ROOT_DIR:-$PWD}/.monozukuri/skills-manifest.json}"
  [ -f "$manifest" ] || return 0
  command -v node >/dev/null 2>&1 || return 0
  node -e "
    const fs = require('fs');
    let m;
    try { m = JSON.parse(fs.readFileSync('$manifest','utf-8')); } catch { process.exit(0); }
    const skills = Array.isArray(m.skills) ? m.skills : [];
    const phase = '$phase';
    const agent = '$agent_id';
    const match = skills.find(s =>
      Array.isArray(s.phases) && s.phases.includes(phase) &&
      (s.agent === agent || s.agent === 'any' || !s.agent)
    );
    if (match) process.stdout.write(match.name);
  " 2>/dev/null
}

# Map pipeline phase name to a skill name.
# Precedence (highest to lowest):
#   1. CFG_AGENTS_<AGENT>_SKILLS_<PHASE> config override
#   2. Project skill manifest (.monozukuri/skills-manifest.json)
#   3. Hardcoded mz-* defaults
# Returns empty string for unknown or unmapped phases.
phase_to_skill() {
  local phase="$1" agent_id="${2:-claude-code}"

  local agent_norm="${agent_id//-/_}"
  agent_norm="${agent_norm^^}"
  local cfg_var="CFG_AGENTS_${agent_norm}_SKILLS_${phase^^}"
  local override="${!cfg_var:-}"
  [ -n "$override" ] && { echo "$override"; return; }

  local from_manifest
  from_manifest=$(_skill_lookup_in_manifest "$phase" "$agent_id")
  [ -n "$from_manifest" ] && { echo "$from_manifest"; return; }

  case "$phase" in
    prd)      echo "mz-create-prd" ;;
    techspec) echo "mz-create-techspec" ;;
    tasks)    echo "mz-create-tasks" ;;
    code)     echo "mz-execute-task" ;;
    tests)    echo "mz-run-tests" ;;
    pr)       echo "mz-open-pr" ;;
    *)        echo "" ;;
  esac
}

# skill_allowed_tools <skill-name>
# Returns the comma-separated allowed-tools list from the skill's manifest
# entry, or empty if the skill isn't in the manifest or declares no tools.
# Reads MONOZUKURI_SKILLS_MANIFEST (or .monozukuri/skills-manifest.json under
# ROOT_DIR / PWD). Useful for adapters / logging that want to show which
# tools a skill is authorised to use.
skill_allowed_tools() {
  local skill_name="$1"
  local manifest="${MONOZUKURI_SKILLS_MANIFEST:-${ROOT_DIR:-$PWD}/.monozukuri/skills-manifest.json}"
  [ -f "$manifest" ] || return 0
  command -v node >/dev/null 2>&1 || return 0
  node -e "
    const fs = require('fs');
    let m;
    try { m = JSON.parse(fs.readFileSync('$manifest','utf-8')); } catch { process.exit(0); }
    const skills = Array.isArray(m.skills) ? m.skills : [];
    const match = skills.find(s => s.name === '$skill_name');
    if (match && Array.isArray(match.allowed_tools) && match.allowed_tools.length > 0) {
      process.stdout.write(match.allowed_tools.join(','));
    }
  " 2>/dev/null
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
