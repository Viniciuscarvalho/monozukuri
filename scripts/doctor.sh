#!/bin/bash
# scripts/doctor.sh — Pre-flight dependency checks for Monozukuri
# Usage: source this file and call sub_doctor, or exec directly.

set -euo pipefail

_doctor_pass() { printf "  \033[32m✓\033[0m %s\n" "$1"; }
_doctor_fail() { printf "  \033[31m✗\033[0m %s\n" "$1" >&2; }

sub_doctor() {
  local failed=0

  printf "\033[1mMonozukuri — pre-flight checks\033[0m\n\n"

  # node ≥ 18
  if command -v node >/dev/null 2>&1; then
    local node_ver
    node_ver=$(node -e 'process.stdout.write(process.versions.node)' 2>/dev/null)
    local node_major
    node_major=$(echo "$node_ver" | cut -d. -f1)
    if [ "${node_major:-0}" -ge 18 ]; then
      _doctor_pass "node ${node_ver}"
    else
      _doctor_fail "node ${node_ver} — need ≥ 18   Fix: brew upgrade node"
      failed=1
    fi
  else
    _doctor_fail "node not found              Fix: brew install node"
    failed=1
  fi

  # jq
  if command -v jq >/dev/null 2>&1; then
    _doctor_pass "jq $(jq --version 2>/dev/null | sed 's/jq-//')"
  else
    _doctor_fail "jq not found               Fix: brew install jq"
    failed=1
  fi

  # gh authenticated
  if command -v gh >/dev/null 2>&1; then
    if gh auth status >/dev/null 2>&1; then
      _doctor_pass "gh authenticated"
    else
      _doctor_fail "gh not authenticated       Fix: gh auth login"
      failed=1
    fi
  else
    _doctor_fail "gh not found               Fix: brew install gh"
    failed=1
  fi

  # claude CLI
  if command -v claude >/dev/null 2>&1; then
    _doctor_pass "claude CLI found"
  else
    _doctor_fail "claude not found           Fix: install Claude Code from https://claude.ai/code"
    failed=1
  fi

  echo ""
  if [ "$failed" -eq 0 ]; then
    printf "\033[32m✓ All checks passed — ready to run\033[0m\n"
    return 0
  else
    printf "\033[31m✗ One or more checks failed — fix the issues above and re-run\033[0m\n"
    return 1
  fi
}

# Allow direct execution
(return 0 2>/dev/null) || sub_doctor "$@"
