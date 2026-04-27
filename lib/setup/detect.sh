#!/bin/bash
# lib/setup/detect.sh — Agent detection for monozukuri setup
#
# Pure filesystem detection — no PATH lookups. Mirrors Compozy's agents.go
# approach: check directory existence only; binary presence is not required.
#
# Public interface:
#   setup_all_agents               → "claude-code cursor gemini-cli codex"
#   setup_agent_name <id>          → display name
#   setup_agent_type <id>          → "specific" | "universal"
#   setup_agent_detected <id>      → exit 0 if present, 1 otherwise
#   setup_detected_agents          → space-separated list of detected agent ids
#   setup_agent_project_path <id>  → base install dir for project-local install
#   setup_agent_global_path <id>   → base install dir for global install

# Returns all supported agent IDs, space-separated.
setup_all_agents() {
  echo "claude-code cursor gemini-cli codex"
}

# Returns the human-readable name for an agent ID.
setup_agent_name() {
  case "$1" in
    claude-code) echo "Claude Code" ;;
    cursor)      echo "Cursor" ;;
    gemini-cli)  echo "Google Gemini CLI" ;;
    codex)       echo "OpenAI Codex CLI" ;;
    *) echo "$1" ;;
  esac
}

# Returns "specific" (agent has its own config dir) or "universal" (uses
# .agents/skills/ canonical root alongside other universal agents).
setup_agent_type() {
  case "$1" in
    claude-code) echo "specific" ;;
    cursor|gemini-cli|codex) echo "universal" ;;
    *) echo "unknown" ;;
  esac
}

# Returns 0 if the agent appears to be installed on this machine.
# Detection uses directory existence only — no binary checks.
setup_agent_detected() {
  local agent="$1"
  case "$agent" in
    claude-code)
      [ -d "$HOME/.claude" ] || [ -d ".claude" ]
      ;;
    cursor)
      [ -d "$HOME/.cursor" ] || [ -d ".cursor" ]
      ;;
    gemini-cli)
      [ -d "$HOME/.gemini" ]
      ;;
    codex)
      [ -d "${CODEX_HOME:-$HOME/.codex}" ]
      ;;
    *)
      return 1
      ;;
  esac
}

# Prints the space-separated list of detected agent IDs.
setup_detected_agents() {
  local found=""
  local id
  for id in $(setup_all_agents); do
    setup_agent_detected "$id" 2>/dev/null && found="${found:+$found }$id"
  done
  echo "${found:-}"
}

# Returns the base project-local install directory for the named agent.
# Caller appends /<skill_name>/ to get the per-skill path.
setup_agent_project_path() {
  local agent="$1"
  case "$agent" in
    claude-code)       echo ".claude/skills" ;;
    cursor|gemini-cli|codex) echo ".agents/skills" ;;
    *) return 1 ;;
  esac
}

# Returns the base global install directory for the named agent.
setup_agent_global_path() {
  local agent="$1"
  case "$agent" in
    claude-code)
      echo "${CLAUDE_CONFIG_DIR:-$HOME/.claude}/skills"
      ;;
    cursor)
      echo "$HOME/.cursor/skills"
      ;;
    gemini-cli)
      echo "$HOME/.gemini/skills"
      ;;
    codex)
      echo "${CODEX_HOME:-$HOME/.codex}/skills"
      ;;
    *) return 1 ;;
  esac
}
