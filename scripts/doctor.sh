#!/bin/bash
# scripts/doctor.sh — Pre-flight dependency checks for Monozukuri
# Usage: source this file and call sub_doctor, or exec directly.

set -euo pipefail

_doctor_pass() { printf "  \033[32m✓\033[0m %s\n" "$1"; }
_doctor_fail() {
  printf "  \033[31m✗\033[0m %s\n    → %s\n" "$1" "$2" >&2
}

sub_doctor() {
  local failed=0

  printf "\033[1mMonozukuri — pre-flight checks\033[0m\n\n"

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

  # claude CLI
  if command -v claude >/dev/null 2>&1; then
    _doctor_pass "claude CLI found"
  else
    _doctor_fail "claude not found" "Install Claude Code: https://claude.ai/code"
    failed=1
  fi

  # gum (optional — needed for interactive mode)
  if command -v gum >/dev/null 2>&1; then
    _doctor_pass "gum $(gum --version 2>/dev/null | head -1) (interactive mode enabled)"
  else
    printf "  \033[33m~\033[0m gum not found (optional — enables interactive prompts)\n"
    printf "    → brew install gum\n"
  fi

  echo ""
  if [ "$failed" -eq 0 ]; then
    printf "\033[32m✓ All checks passed — ready to run\033[0m\n"
    return 0
  else
    printf "\033[31m✗ One or more checks failed — fix the issues above and re-run\033[0m\n"
    exit 11
  fi
}

# Allow direct execution
(return 0 2>/dev/null) || sub_doctor "$@"
