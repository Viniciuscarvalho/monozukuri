#!/bin/bash
# lib/setup/install.sh — Skill install/uninstall/status for monozukuri setup
#
# Implements the canonical-root pattern from Compozy's install.go:
#   - Universal agents share .agents/skills/<name>/ (canonical copy)
#   - claude-code gets a relative symlink .claude/skills/<name>/ → canonical
#   - --copy skips symlinks and writes a copy to each agent's path directly
#   - --global writes to ~/.<agent>/skills/ instead of .<agent>/skills/
#
# Public interface:
#   setup_skills_source_dir             → path to skills/ in monozukuri home
#   setup_skills_list                   → mz-* skill names, newline-separated
#   setup_skill_status <src> <dst>      → "current"|"missing"|"drifted"|"foreign"
#   setup_install <agents> <skills> [opts]   → install skills for agents
#   setup_uninstall <agents> <skills> [opts] → remove monozukuri skills
#   setup_status <agents> <skills> [opts]    → print install status table

# Locate the skills/ source directory.
setup_skills_source_dir() {
  local home="${MONOZUKURI_HOME:-}"
  if [ -n "$home" ] && [ -d "$home/skills" ]; then
    echo "$home/skills"
    return
  fi
  local script_dir
  script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" 2>/dev/null && pwd)"
  echo "${script_dir}/../../skills"
}

# List installable skill names (mz-* only — grill-me and to-prd are excluded).
setup_skills_list() {
  local src
  src="$(setup_skills_source_dir)"
  local name
  for d in "$src"/mz-*/; do
    name="$(basename "$d")"
    [ -f "$d/SKILL.md" ] && echo "$name"
  done
}

# _setup_skill_files_match <src_dir> <dst_dir>
# Returns 0 if every file in src_dir exists in dst_dir with identical content.
_setup_skill_files_match() {
  local src="$1" dst="$2"
  local rel
  while IFS= read -r -d '' f; do
    rel="${f#$src/}"
    [ -f "$dst/$rel" ] || return 1
    cmp -s "$f" "$dst/$rel" || return 1
  done < <(find "$src" -type f -print0)
  return 0
}

# setup_skill_status <src_skill_dir> <dst_dir>
# Classifies the install state:
#   current  — dst exists and all files match src byte-for-byte
#   missing  — dst does not exist
#   drifted  — dst exists but files differ from src (monozukuri-installed)
#   foreign  — dst exists but was not installed by monozukuri (no SKILL.md)
setup_skill_status() {
  local src="$1" dst="$2"
  if [ ! -e "$dst" ]; then
    echo "missing"
    return
  fi
  if [ ! -f "$dst/SKILL.md" ]; then
    echo "foreign"
    return
  fi
  if _setup_skill_files_match "$src" "$dst"; then
    echo "current"
  else
    echo "drifted"
  fi
}

# _setup_copy_skill_files <src_dir> <dst_dir> [dry_run]
# Copies all files from src_dir into dst_dir, creating subdirectories.
_setup_copy_skill_files() {
  local src="$1" dst="$2" dry="${3:-false}"
  local rel
  while IFS= read -r -d '' f; do
    rel="${f#$src/}"
    local target="$dst/$rel"
    if [ "$dry" = "true" ]; then
      echo "    copy  $rel"
    else
      mkdir -p "$(dirname "$target")"
      cp "$f" "$target"
    fi
  done < <(find "$src" -type f -print0)
}

# _relpath <target> <from_dir>
# Compute a relative path from from_dir to target (both must be absolute).
# Falls back to absolute path when realpath --relative-to is unavailable.
_relpath() {
  local target="$1" from="$2"
  if realpath --relative-to="$from" "$target" 2>/dev/null; then
    return
  fi
  # POSIX fallback: strip common prefix segments
  local t_parts f_parts common rel_back rel_fwd
  IFS='/' read -ra t_parts <<< "${target#/}"
  IFS='/' read -ra f_parts <<< "${from#/}"
  local i=0
  while [ $((i)) -lt ${#t_parts[@]} ] && [ $((i)) -lt ${#f_parts[@]} ] && \
        [ "${t_parts[$i]}" = "${f_parts[$i]}" ]; do
    i=$((i + 1))
  done
  rel_back=""
  local j
  j=$i
  while [ "$j" -lt "${#f_parts[@]}" ]; do
    rel_back="${rel_back:+$rel_back/}.."
    j=$((j + 1))
  done
  rel_fwd=""
  j=$i
  while [ "$j" -lt "${#t_parts[@]}" ]; do
    rel_fwd="${rel_fwd:+$rel_fwd/}${t_parts[$j]}"
    j=$((j + 1))
  done
  if [ -n "$rel_back" ] && [ -n "$rel_fwd" ]; then
    echo "$rel_back/$rel_fwd"
  elif [ -n "$rel_back" ]; then
    echo "$rel_back"
  elif [ -n "$rel_fwd" ]; then
    echo "$rel_fwd"
  else
    echo "."
  fi
}

# setup_install <agent_list> <skill_list> --global? --copy? --dry-run? --force?
#
# agent_list: space-separated agent IDs
# skill_list: space-separated skill names (or "all")
# Options parsed from remaining args: --global --copy --dry-run --force
#
# Install layout:
#   project (default):
#     Universal agents → .agents/skills/<name>/  (canonical, written once)
#     claude-code      → .claude/skills/<name>/  symlink → ../../../.agents/skills/<name>/
#                        (or copy if --copy, or if only claude-code is selected)
#   global (--global):
#     All agents get their own copy/symlink under ~/.<agent>/skills/<name>/
#     Canonical → ~/.agents/skills/<name>/
#     Agent-specific → symlink to canonical (or copy if --copy)
setup_install() {
  local agents_arg="$1" skills_arg="$2"
  shift 2
  local global=false copy=false dry=false force=false
  while [ $# -gt 0 ]; do
    case "$1" in
      --global)   global=true ;;
      --copy)     copy=true ;;
      --dry-run)  dry=true ;;
      --force)    force=true ;;
    esac
    shift
  done

  local src_dir
  src_dir="$(setup_skills_source_dir)"

  local skills
  if [ "$skills_arg" = "all" ]; then
    skills="$(setup_skills_list | tr '\n' ' ')"
  else
    skills="$skills_arg"
  fi

  # Determine whether we need a canonical root (universal agents are present)
  local has_universal=false has_specific=false
  local ag
  for ag in $agents_arg; do
    case "$(setup_agent_type "$ag")" in
      universal) has_universal=true ;;
      specific)  has_specific=true ;;
    esac
  done

  # Use canonical only for project-local multi-agent installs without --copy
  local use_canonical=false
  if [ "$global" = "false" ] && [ "$has_universal" = "true" ] && [ "$copy" = "false" ]; then
    use_canonical=true
  fi

  local skill
  for skill in $skills; do
    local src="$src_dir/$skill"
    if [ ! -d "$src" ]; then
      printf "  %-30s  SKIP (not found in source)\n" "$skill"
      continue
    fi

    # ── canonical install (project, universal agents, no --copy) ──────────
    if [ "$use_canonical" = "true" ]; then
      local canon_dst=".agents/skills/$skill"
      local status
      status="$(setup_skill_status "$src" "$canon_dst")"
      case "$status" in
        current)
          printf "  %-30s  already current (canonical)\n" "$skill"
          ;;
        foreign)
          if [ "$force" = "false" ]; then
            printf "  %-30s  SKIP — foreign file at %s (use --force to overwrite)\n" "$skill" "$canon_dst" >&2
            continue
          fi
          if [ "$dry" = "true" ]; then
            printf "  %-30s  would install → %s\n" "$skill" "$canon_dst"
          else
            rm -rf "$canon_dst"
            mkdir -p "$canon_dst"
            _setup_copy_skill_files "$src" "$canon_dst" false
            printf "  %-30s  installed → %s\n" "$skill" "$canon_dst"
          fi
          ;;
        missing|drifted)
          if [ "$dry" = "true" ]; then
            printf "  %-30s  would install → %s\n" "$skill" "$canon_dst"
          else
            rm -rf "$canon_dst"
            mkdir -p "$canon_dst"
            _setup_copy_skill_files "$src" "$canon_dst" false
            printf "  %-30s  installed → %s\n" "$skill" "$canon_dst"
          fi
          ;;
      esac
    fi

    # ── per-agent install ──────────────────────────────────────────────────
    for ag in $agents_arg; do
      local base_path
      if [ "$global" = "true" ]; then
        base_path="$(setup_agent_global_path "$ag")"
      else
        base_path="$(setup_agent_project_path "$ag")"
      fi
      local dst="$base_path/$skill"
      local status
      status="$(setup_skill_status "$src" "$dst")"

      # For canonical-mode universal agents: the canonical IS their path
      if [ "$use_canonical" = "true" ] && [ "$(setup_agent_type "$ag")" = "universal" ]; then
        continue  # already handled above
      fi

      case "$status" in
        current)
          printf "  %-22s  %-30s  already current\n" "$ag" "$skill"
          continue
          ;;
        foreign)
          if [ "$force" = "false" ]; then
            printf "  %-22s  %-30s  SKIP — foreign file at %s\n" "$ag" "$skill" "$dst" >&2
            continue
          fi
          ;;
      esac

      if [ "$dry" = "true" ]; then
        printf "  %-22s  %-30s  would install → %s\n" "$ag" "$skill" "$dst"
        continue
      fi

      rm -rf "$dst"

      # claude-code in project canonical-mode: symlink to canonical
      if [ "$use_canonical" = "true" ] && [ "$(setup_agent_type "$ag")" = "specific" ] && [ "$copy" = "false" ]; then
        local canon_abs link_dir rel_target
        canon_abs="$(pwd)/.agents/skills/$skill"
        mkdir -p "$base_path"
        link_dir="$(cd "$base_path" && pwd)"
        rel_target="$(_relpath "$canon_abs" "$link_dir")"
        ln -s "$rel_target" "$dst"
        printf "  %-22s  %-30s  symlink → %s\n" "$ag" "$skill" "$rel_target"

      # global mode with symlinks: symlink each agent path to global canonical
      elif [ "$global" = "true" ] && [ "$copy" = "false" ]; then
        local global_canon="$HOME/.agents/skills/$skill"
        # Write canonical if not yet written
        if [ ! -d "$global_canon" ]; then
          mkdir -p "$global_canon"
          _setup_copy_skill_files "$src" "$global_canon" false
        fi
        mkdir -p "$base_path"
        local link_dir_abs
        link_dir_abs="$(cd "$base_path" 2>/dev/null && pwd || echo "$base_path")"
        local rel_target
        rel_target="$(_relpath "$global_canon" "$link_dir_abs")"
        ln -s "$rel_target" "$dst"
        printf "  %-22s  %-30s  symlink → %s\n" "$ag" "$skill" "$rel_target"

      # copy mode (or single-agent project install)
      else
        mkdir -p "$dst"
        _setup_copy_skill_files "$src" "$dst" false
        printf "  %-22s  %-30s  installed → %s\n" "$ag" "$skill" "$dst"
      fi
    done
  done

  # When a canonical .agents/ root was written in project mode, ensure .gitignore has it.
  if [ "$use_canonical" = "true" ] && [ "$dry" = "false" ]; then
    _setup_install_gitignore_agents
  fi
}

# Add .agents/ to .gitignore idempotently (only if .gitignore already exists).
_setup_install_gitignore_agents() {
  local gitignore=".gitignore"
  [ -f "$gitignore" ] || return 0
  grep -qxF ".agents/" "$gitignore" 2>/dev/null && return 0
  printf "\n.agents/\n" >> "$gitignore"
}

# setup_uninstall <agent_list> <skill_list> --global? --dry-run?
# Removes only monozukuri-managed skills (those with a SKILL.md at root).
# Foreign directories (no SKILL.md) are never removed.
setup_uninstall() {
  local agents_arg="$1" skills_arg="$2"
  shift 2
  local global=false dry=false
  while [ $# -gt 0 ]; do
    case "$1" in
      --global)  global=true ;;
      --dry-run) dry=true ;;
    esac
    shift
  done

  local skills
  if [ "$skills_arg" = "all" ]; then
    skills="$(setup_skills_list | tr '\n' ' ')"
  else
    skills="$skills_arg"
  fi

  # Also clean up canonical root for universal agents (project-local)
  local has_universal=false
  local ag
  for ag in $agents_arg; do
    [ "$(setup_agent_type "$ag")" = "universal" ] && has_universal=true
  done

  local skill
  for skill in $skills; do
    # Remove canonical if any universal agent is in the list
    if [ "$has_universal" = "true" ] && [ "$global" = "false" ]; then
      local canon_dst=".agents/skills/$skill"
      if [ -e "$canon_dst" ]; then
        if [ ! -f "$canon_dst/SKILL.md" ]; then
          printf "  %-30s  SKIP canonical — foreign (no SKILL.md)\n" "$skill" >&2
        elif [ "$dry" = "true" ]; then
          printf "  %-30s  would remove canonical %s\n" "$skill" "$canon_dst"
        else
          rm -rf "$canon_dst"
          printf "  %-30s  removed canonical %s\n" "$skill" "$canon_dst"
        fi
      fi
    fi

    for ag in $agents_arg; do
      local base_path
      if [ "$global" = "true" ]; then
        base_path="$(setup_agent_global_path "$ag")"
      else
        base_path="$(setup_agent_project_path "$ag")"
      fi
      local dst="$base_path/$skill"

      if [ ! -e "$dst" ]; then
        continue
      fi
      # Skip canonicals when iterating universal agents (handled above)
      if [ "$global" = "false" ] && [ "$(setup_agent_type "$ag")" = "universal" ]; then
        continue
      fi
      if [ ! -f "$dst/SKILL.md" ] && [ ! -L "$dst" ]; then
        printf "  %-22s  %-30s  SKIP — foreign (no SKILL.md)\n" "$ag" "$skill" >&2
        continue
      fi
      if [ "$dry" = "true" ]; then
        printf "  %-22s  %-30s  would remove %s\n" "$ag" "$skill" "$dst"
      else
        rm -rf "$dst"
        printf "  %-22s  %-30s  removed %s\n" "$ag" "$skill" "$dst"
      fi
    done

    # Remove canonical for global uninstall
    if [ "$global" = "true" ] && [ "$has_universal" = "true" ]; then
      local global_canon="$HOME/.agents/skills/$skill"
      if [ -d "$global_canon" ] && [ -f "$global_canon/SKILL.md" ]; then
        if [ "$dry" = "true" ]; then
          printf "  %-22s  %-30s  would remove global canonical %s\n" "(canonical)" "$skill" "$global_canon"
        else
          rm -rf "$global_canon"
          printf "  %-22s  %-30s  removed global canonical %s\n" "(canonical)" "$skill" "$global_canon"
        fi
      fi
    fi
  done
}

# setup_status <agent_list> <skill_list> --global?
# Prints a table of install status for each agent × skill combination.
setup_status() {
  local agents_arg="$1" skills_arg="$2"
  shift 2
  local global=false
  while [ $# -gt 0 ]; do
    [ "$1" = "--global" ] && global=true
    shift
  done

  local src_dir
  src_dir="$(setup_skills_source_dir)"

  local skills
  if [ "$skills_arg" = "all" ]; then
    skills="$(setup_skills_list | tr '\n' ' ')"
  else
    skills="$skills_arg"
  fi

  printf "%-22s  %-30s  %s\n" "AGENT" "SKILL" "STATUS"
  printf "%-22s  %-30s  %s\n" "------" "-----" "------"

  local ag skill src dst status
  for ag in $agents_arg; do
    for skill in $skills; do
      src="$src_dir/$skill"
      if [ "$global" = "true" ]; then
        dst="$(setup_agent_global_path "$ag")/$skill"
      else
        dst="$(setup_agent_project_path "$ag")/$skill"
      fi

      if [ ! -d "$src" ]; then
        status="no-source"
      else
        # For project-local universal agents, check canonical
        if [ "$global" = "false" ] && [ "$(setup_agent_type "$ag")" = "universal" ]; then
          dst=".agents/skills/$skill"
        fi
        status="$(setup_skill_status "$src" "$dst")"
        # Annotate symlinks
        [ -L "$dst" ] && [ "$status" = "current" ] && status="current (symlink)"
      fi

      printf "%-22s  %-30s  %s\n" "$ag" "$skill" "$status"
    done
  done
}
