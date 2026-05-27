#!/bin/bash
# cmd/doctor.sh — Pre-flight dependency checks for Monozukuri
# Contains sub_doctor(); sourced by orchestrate.sh and dispatched.

set -euo pipefail

_doctor_pass() { printf "  %s✓%s %s\n" "${T_SUCCESS:-\033[0;32m}" "${T_RESET:-\033[0m}" "$1"; }
_doctor_fail() {
  printf "  %s✗%s %s\n    → %s\n" "${T_DANGER:-\033[0;31m}" "${T_RESET:-\033[0m}" "$1" "$2" >&2
}

_doctor_config_path() {
  if [ -n "${OPT_CONFIG:-}" ] && [ -f "${OPT_CONFIG}" ]; then
    printf '%s\n' "${OPT_CONFIG}"
  elif [ -f ".monozukuri/config.yaml" ]; then
    printf '%s\n' ".monozukuri/config.yaml"
  elif [ -f ".monozukuri/config.yml" ]; then
    printf '%s\n' ".monozukuri/config.yml"
  fi
}

_doctor_configured_agent() {
  if [ -n "${MONOZUKURI_AGENT:-}" ]; then
    printf '%s\n' "$MONOZUKURI_AGENT"
    return
  fi

  local cfg
  cfg="$(_doctor_config_path)"
  if [ -z "$cfg" ]; then
    return 0
  fi

  local agent
  agent="$(awk -F: '
    /^[[:space:]]*agent[[:space:]]*:/ {
      value=$2
      sub(/#.*/, "", value)
      gsub(/^[[:space:]"'\''"]+|[[:space:]"'\''"]+$/, "", value)
      print value
      exit
    }
  ' "$cfg" | xargs 2>/dev/null || true)"
  printf '%s\n' "${agent:-claude-code}"
}

_doctor_setup_agent_id() {
  case "$1" in
    gemini) echo "gemini-cli" ;;
    *)      echo "$1" ;;
  esac
}

_doctor_agent_display_name() {
  local setup_id
  setup_id="$(_doctor_setup_agent_id "$1")"
  if declare -f setup_agent_name &>/dev/null; then
    setup_agent_name "$setup_id"
  else
    case "$1" in
      claude-code) echo "Claude Code" ;;
      codex)       echo "OpenAI Codex CLI" ;;
      gemini)      echo "Google Gemini CLI" ;;
      kiro)        echo "Kiro" ;;
      aider)       echo "Aider" ;;
      *)           echo "$1" ;;
    esac
  fi
}

_doctor_agent_cli_bin() {
  case "$1" in
    claude-code) echo "claude" ;;
    codex)       echo "codex" ;;
    gemini)      echo "gemini" ;;
    kiro)        echo "kiro" ;;
    aider)       echo "aider" ;;
    *)           echo "$1" ;;
  esac
}

_doctor_agent_supports_native_skills() {
  case "$1" in
    claude-code) return 0 ;;
    *)           return 1 ;;
  esac
}

_doctor_check_active_agent() {
  local agent="$1"
  local adapter="${LIB_DIR}/agent/adapter-${agent}.sh"
  local bin
  bin="$(_doctor_agent_cli_bin "$agent")"
  if [ ! -f "$adapter" ]; then
    _doctor_fail "$agent adapter not found" "Choose one of: claude-code, codex, gemini, kiro, aider"
    return 1
  fi
  if command -v "$bin" >/dev/null 2>&1; then
    _doctor_pass "${agent} CLI installed"
  else
    _doctor_fail "${agent} CLI missing" "Install ${bin}; hint: source ${adapter} && agent_login_hint"
    return 1
  fi

  (
    # shellcheck source=/dev/null
    source "$adapter"
    agent_doctor >/dev/null 2>&1
  )
  local rc=$?
  if [ "$rc" -eq 0 ]; then
    _doctor_pass "${agent} auth OK"
    _doctor_pass "loop live validable: ${agent} ready"
  else
    _doctor_fail "${agent} auth not OK" "Authenticate ${bin}; hint: source ${adapter} && agent_login_hint"
    return 1
  fi
}

sub_doctor() {
  local failed=0

  # Source semantic tokens if not already loaded
  [ -z "${T_RESET:-}" ] && [ -f "${LIB_DIR:-$(dirname "${BASH_SOURCE[0]}")/../lib}/cli/colors.sh" ] && \
    source "${LIB_DIR:-$(dirname "${BASH_SOURCE[0]}")/../lib}/cli/colors.sh"

  printf "%sMonozukuri — pre-flight checks%s\n\n" "${T_BOLD:-\033[1m}" "${T_RESET:-\033[0m}"

  # node >= 18
  if command -v node >/dev/null 2>&1; then
    local node_ver
    node_ver=$(node -e 'process.stdout.write(process.versions.node)' 2>/dev/null)
    local node_major
    node_major=$(echo "$node_ver" | cut -d. -f1)
    if [ "${node_major:-0}" -ge 18 ]; then
      _doctor_pass "node ${node_ver}"
    else
      _doctor_fail "node ${node_ver} — need ≥ 18" "brew upgrade node"
      failed=1
    fi
  else
    _doctor_fail "node not found" "brew install node  |  https://nodejs.org"
    failed=1
  fi

  # jq
  if command -v jq >/dev/null 2>&1; then
    _doctor_pass "jq $(jq --version 2>/dev/null | sed 's/jq-//')"
  else
    _doctor_fail "jq not found" "brew install jq  |  apt install jq"
    failed=1
  fi

  # gh installed + authenticated
  if command -v gh >/dev/null 2>&1; then
    if gh auth status >/dev/null 2>&1; then
      _doctor_pass "gh authenticated"
    else
      _doctor_fail "gh not authenticated" "gh auth login"
      failed=1
    fi
  else
    _doctor_fail "gh not found" "brew install gh  |  https://cli.github.com"
    failed=1
  fi

  # git worktree (must be inside a git repo when running a project command)
  if git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    _doctor_pass "git worktree available"
  else
    _doctor_fail "not inside a git repository" "Run monozukuri from the root of your project"
    failed=1
  fi

  # Active agent CLI/auth is blocking only when a project config or
  # MONOZUKURI_AGENT selects one. Otherwise, agent CLIs are advisory.
  local active_agent
  active_agent="$(_doctor_configured_agent)"
  if [ -n "$active_agent" ]; then
    _doctor_check_active_agent "$active_agent" || failed=1
  else
    printf "  %s~%s no .monozukuri config found; agent CLI checks are advisory\n" \
      "${T_WARNING:-\033[0;33m}" "${T_RESET:-\033[0m}"
  fi

  # gum (optional — needed for interactive mode)
  if command -v gum >/dev/null 2>&1; then
    _doctor_pass "gum $(gum --version 2>/dev/null | head -1) (interactive mode enabled)"
  else
    printf "  %s~%s gum not found (optional — enables interactive prompts)\n" "${T_WARNING:-\033[0;33m}" "${T_RESET:-\033[0m}"
    printf "    → brew install gum\n"
  fi

  # mz-* skills — check all installed agents have the full skill set
  if [ -n "${LIB_DIR:-}" ] && [ -f "${LIB_DIR}/setup/detect.sh" ] && [ -f "${LIB_DIR}/setup/install.sh" ]; then
    # shellcheck source=/dev/null
    source "${LIB_DIR}/setup/detect.sh"
    source "${LIB_DIR}/setup/install.sh"
    source "${LIB_DIR}/agent/skill-detect.sh"
    local detected_agents total_skills ag ok missing_list skill active_setup_agent
    detected_agents="$(setup_detected_agents)"
    total_skills="$(setup_skills_list | wc -l | tr -d ' ')"
    active_setup_agent="$(_doctor_setup_agent_id "${active_agent:-}")"
    if [ -z "$detected_agents" ]; then
      printf "  %s~%s mz-* skills: no agents detected\n" "${T_WARNING:-\033[0;33m}" "${T_RESET:-\033[0m}"
    else
      for ag in $detected_agents; do
        if ! _doctor_agent_supports_native_skills "$ag"; then
          _doctor_pass "$(setup_agent_name "$ag") uses rendered prompts; mz-* native skills not required"
          continue
        fi

        ok=0; missing_list=""
        while IFS= read -r skill; do
          if skill_installed "$ag" "$skill"; then
            ok=$((ok + 1))
          else
            missing_list="${missing_list:+$missing_list, }$skill"
          fi
        done < <(setup_skills_list)
        if [ -z "$missing_list" ]; then
          _doctor_pass "$(setup_agent_name "$ag") skills: ${ok}/${total_skills} installed"
        elif [ -n "$active_setup_agent" ] && [ "$ag" = "$active_setup_agent" ]; then
          _doctor_fail "$(setup_agent_name "$ag") skills: missing — $missing_list" \
                       "monozukuri setup --agent $ag"
          failed=1
        else
          printf "  %s~%s %s skills: missing — %s (optional; run monozukuri setup --agent %s)\n" \
            "${T_WARNING:-\033[0;33m}" "${T_RESET:-\033[0m}" \
            "$(setup_agent_name "$ag")" "$missing_list" "$ag"
        fi
      done
    fi
  else
    printf "  %s~%s mz-* skills: skipped (library path unavailable)\n" "${T_WARNING:-\033[0;33m}" "${T_RESET:-\033[0m}"
  fi

  # Optional adapter CLIs
  local _pair _cli _cli_bin
  for _pair in "claude-code:claude" "codex:codex" "gemini:gemini" "kiro:kiro" "aider:aider"; do
    _cli="${_pair%%:*}"; _cli_bin="${_pair##*:}"
    [ -n "${active_agent:-}" ] && [ "$_cli" = "$active_agent" ] && continue
    if command -v "$_cli_bin" >/dev/null 2>&1; then
      _doctor_pass "${_cli} CLI found"
    else
      printf "  %s-%s %s CLI not installed (optional)\n" "${T_DIM:-\033[2m}" "${T_RESET:-\033[0m}" "$_cli"
    fi
  done

  # Project-local agents (.claude/agents/)
  if [ -d ".claude/agents" ]; then
    local _agent_count=0 _f
    while IFS= read -r _f; do
      [ -n "$_f" ] && _agent_count=$((_agent_count + 1))
    done < <(find .claude/agents -maxdepth 1 \( -name '*.md' -o -name '*.yaml' -o -name '*.yml' \) 2>/dev/null | sort)
    if [ "$_agent_count" -gt 0 ]; then
      _doctor_pass ".claude/agents/: ${_agent_count} project-local agent(s)"
      find .claude/agents -maxdepth 1 \( -name '*.md' -o -name '*.yaml' -o -name '*.yml' \) 2>/dev/null | sort \
        | while IFS= read -r _f; do printf "    %s\n" "$(basename "$_f")"; done
    else
      printf "  %s~%s .claude/agents/ exists but no agent files found\n" "${T_WARNING:-\033[0;33m}" "${T_RESET:-\033[0m}"
    fi
  else
    printf "  %s-%s .claude/agents/ not present\n" "${T_DIM:-\033[2m}" "${T_RESET:-\033[0m}"
  fi

  # Project-local skills (.claude/skills/ — user-installed, beyond mz-*)
  if [ -d ".claude/skills" ]; then
    local _skill_count=0 _sd
    while IFS= read -r _sd; do
      [ -n "$_sd" ] && [ -f "$_sd/SKILL.md" ] && _skill_count=$((_skill_count + 1))
    done < <(find .claude/skills -maxdepth 1 -mindepth 1 -type d 2>/dev/null | sort)
    if [ "$_skill_count" -gt 0 ]; then
      _doctor_pass ".claude/skills/: ${_skill_count} project-local skill(s)"
      find .claude/skills -maxdepth 1 -mindepth 1 -type d 2>/dev/null | sort \
        | while IFS= read -r _sd; do
            [ -f "$_sd/SKILL.md" ] && printf "    %s\n" "$(basename "$_sd")"
          done
    else
      printf "  %s~%s .claude/skills/ exists but no SKILL.md files found\n" "${T_WARNING:-\033[0;33m}" "${T_RESET:-\033[0m}"
    fi
  else
    printf "  %s-%s .claude/skills/ not present\n" "${T_DIM:-\033[2m}" "${T_RESET:-\033[0m}"
  fi

  # Portable project-local skills (.agents/skills/ — rendered-prompt adapters)
  if [ -d ".agents/skills" ]; then
    local _agent_skill_count=0 _asd
    while IFS= read -r _asd; do
      [ -n "$_asd" ] && [ -f "$_asd/SKILL.md" ] && _agent_skill_count=$((_agent_skill_count + 1))
    done < <(find .agents/skills -maxdepth 1 -mindepth 1 -type d 2>/dev/null | sort)
    if [ "$_agent_skill_count" -gt 0 ]; then
      _doctor_pass ".agents/skills/: ${_agent_skill_count} portable project-local skill(s)"
      find .agents/skills -maxdepth 1 -mindepth 1 -type d 2>/dev/null | sort \
        | while IFS= read -r _asd; do
            [ -f "$_asd/SKILL.md" ] && printf "    %s\n" "$(basename "$_asd")"
          done
    else
      printf "  %s~%s .agents/skills/ exists but no SKILL.md files found\n" "${T_WARNING:-\033[0;33m}" "${T_RESET:-\033[0m}"
    fi
  else
    printf "  %s-%s .agents/skills/ not present\n" "${T_DIM:-\033[2m}" "${T_RESET:-\033[0m}"
  fi

  # Discovered skills manifest (written by `monozukuri run` via skill-discovery.sh)
  local _skills_manifest=".monozukuri/skills-manifest.json"
  if [ -f "$_skills_manifest" ] && command -v jq >/dev/null 2>&1; then
    local _total _proj _glob _injectable
    _total=$(jq '.skills | length' "$_skills_manifest" 2>/dev/null || echo 0)
    _proj=$(jq '[.skills[] | select(.scope == "project")] | length' "$_skills_manifest" 2>/dev/null || echo 0)
    _glob=$(jq '[.skills[] | select(.scope == "global")]  | length' "$_skills_manifest" 2>/dev/null || echo 0)
    _doctor_pass "skills-manifest.json: ${_total} skill(s) discovered (${_proj} project, ${_glob} global)"
    _doctor_pass "skills discovered: ${_total} (${_proj} project, ${_glob} global)"
    if [ -n "${active_agent:-}" ]; then
      _injectable=$(jq --arg agent "$active_agent" '
        def norm(a): if a == "gemini-cli" then "gemini" else a end;
        [.skills[] | select((.agent == null) or (.agent == "any") or (norm(.agent) == norm($agent)))] | length
      ' "$_skills_manifest" 2>/dev/null || echo 0)
      _doctor_pass "skills injectable for ${active_agent}: ${_injectable}"
    fi
  else
    printf "  %s-%s skills-manifest.json: not yet built (run \`monozukuri run\` to populate)\n" \
      "${T_DIM:-\033[2m}" "${T_RESET:-\033[0m}"
  fi

  # Known-incompatible skills — warn (non-blocking) when config routes a phase
  # to a skill that violates the monozukuri autonomy contract.
  local _ki_sh="${LIB_DIR}/agent/known-incompatible.sh"
  local _cfg=".monozukuri/config.yaml"
  if [ -f "$_ki_sh" ] && [ -f "$_cfg" ]; then
    # shellcheck source=../lib/agent/known-incompatible.sh
    source "$_ki_sh"
    # Extract phase → skill pairs from agents.claude-code.skills block.
    # grep targets lines of the form "  <phase>: <skill-name>" (2-space indent).
    local _ki_phase _ki_skill _ki_warned=0
    while IFS=': ' read -r _ki_phase _ki_skill; do
      _ki_phase="${_ki_phase##*( )}"   # strip leading spaces (bash 4 extglob)
      _ki_skill="${_ki_skill%%[[:space:]]*}" # strip trailing spaces / comments
      [ -z "$_ki_skill" ] && continue
      if is_skill_known_incompatible "$_ki_skill"; then
        local _ki_reason
        _ki_reason=$(known_incompatible_reason "$_ki_skill")
        printf "  %s~%s skill '%s' (phase '%s') is known incompatible: %s\n" \
          "${T_WARNING:-\033[0;33m}" "${T_RESET:-\033[0m}" \
          "$_ki_skill" "$_ki_phase" "$_ki_reason" >&2
        printf "    See: docs/adapter-contract.md#known-incompatible-skills\n" >&2
        _ki_warned=$((_ki_warned + 1))
      fi
    done < <(grep -E '^\s+(prd|techspec|tasks|code|tests|pr):\s+\S' "$_cfg" 2>/dev/null || true)
    if [ "$_ki_warned" -eq 0 ] && [ -f "$_cfg" ]; then
      _doctor_pass "skill compatibility: no known-incompatible skills configured"
    fi
  fi

  # ADR-017: multi-turn visibility (only printed when opted in)
  if [[ "${MONOZUKURI_MULTI_TURN:-0}" == "1" ]]; then
    local _mt_agent
    _mt_agent=$(grep -E '^\s*agent\s*:' ".monozukuri/config.yaml" 2>/dev/null | head -1 \
      | sed 's/.*:\s*//' | tr -d '"' | xargs 2>/dev/null || echo "claude-code")
    local _mt_adapter="${LIB_DIR}/agent/adapter-${_mt_agent}.sh"
    if [[ -f "$_mt_adapter" ]] && grep -q '"session_continuity":[[:space:]]*true' "$_mt_adapter" 2>/dev/null; then
      _doctor_pass "MONOZUKURI_MULTI_TURN=1 (${_mt_agent}: session_continuity active, mz-* skills bypassed)"
    else
      printf "  %s~%s MONOZUKURI_MULTI_TURN=1 but '%s' lacks session_continuity — cold-process fallback\n" \
        "${T_WARNING:-\033[0;33m}" "${T_RESET:-\033[0m}" "$_mt_agent"
    fi
  fi

  echo ""
  if [ "$failed" -eq 0 ]; then
    printf "%s✓ All checks passed — ready to run%s\n" "${T_SUCCESS:-\033[0;32m}" "${T_RESET:-\033[0m}"
    return 0
  else
    printf "%s✗ One or more checks failed — fix the issues above and re-run%s\n" "${T_DANGER:-\033[0;31m}" "${T_RESET:-\033[0m}"
    exit 11
  fi
}
