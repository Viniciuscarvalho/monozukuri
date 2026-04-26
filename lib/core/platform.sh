#!/bin/bash
# lib/core/platform.sh — Centralized external CLI adapter
#
# All calls to claude, gh (GitHub/GitLab/Azure), and git that can block or fail
# route through this module. Callers stop knowing which platform is active, stop
# writing their own availability checks, and get op_timeout for free.
#
# Requires: lib/core/util.sh (op_timeout)

# ── platform_detect ──────────────────────────────────────────────────────────
# Detects the active git platform and caches the result in _PLATFORM_GIT_HOST.
# Detection order: ADAPTER env var → installed CLI override (glab > az > gh).
_PLATFORM_GIT_HOST=""

platform_detect() {
  [ -n "$_PLATFORM_GIT_HOST" ] && return 0
  case "${ADAPTER:-markdown}" in
    github|linear) _PLATFORM_GIT_HOST="github" ;;
    gitlab)        _PLATFORM_GIT_HOST="gitlab" ;;
    azure)         _PLATFORM_GIT_HOST="azure"  ;;
    *)             _PLATFORM_GIT_HOST="github" ;;
  esac
  # Installed CLI presence overrides adapter-derived default
  if command -v glab &>/dev/null; then
    _PLATFORM_GIT_HOST="gitlab"
  elif command -v az &>/dev/null; then
    _PLATFORM_GIT_HOST="azure"
  fi
}

# platform_host
# Prints the detected platform name: github | gitlab | azure.
platform_host() {
  platform_detect
  echo "$_PLATFORM_GIT_HOST"
}

# ── platform_gh ──────────────────────────────────────────────────────────────
# Usage: platform_gh [timeout_s] <gh_subcommand> [args...]
# Wraps gh with an availability check and op_timeout.
# timeout_s must be the first argument when it is an integer; defaults to 30.
# Returns 1 (with a logged message) if gh is not installed.
platform_gh() {
  local timeout_s=30
  if [[ "${1:-}" =~ ^[0-9]+$ ]]; then
    timeout_s="$1"; shift
  fi
  if ! command -v gh &>/dev/null; then
    info "platform_gh: gh CLI not available — skipping: gh $*" 2>/dev/null || true
    return 1
  fi
  if [ "$timeout_s" -gt 0 ]; then
    op_timeout "$timeout_s" gh "$@"
  else
    gh "$@"
  fi
}

# ── platform_claude ──────────────────────────────────────────────────────────
# Usage: platform_claude <timeout_s> [claude_args...]
# Wraps claude with an availability check and op_timeout.
# Returns 1 (with a logged message) if claude is not installed.
platform_claude() {
  local timeout_s="$1"; shift
  if ! command -v claude &>/dev/null; then
    info "platform_claude: claude CLI not available" 2>/dev/null || true
    return 1
  fi
  op_timeout "$timeout_s" claude "$@"
}

# ── platform_pr_merged ───────────────────────────────────────────────────────
# Usage: platform_pr_merged <pr_num>
# Returns 0 if the PR/MR is merged, 1 if not or if the check cannot be performed.
# Uses the platform detected by platform_detect.
platform_pr_merged() {
  local pr_num="$1"
  platform_detect

  case "$_PLATFORM_GIT_HOST" in
    github)
      local state
      state=$(platform_gh 30 pr view "$pr_num" --json state,mergedAt 2>/dev/null || echo '{}')
      echo "$state" | node -p "
        try {
          const d = JSON.parse(require('fs').readFileSync('/dev/stdin','utf-8'));
          (d.state === 'MERGED' || (d.mergedAt && d.mergedAt.length > 0)) ? 'true' : 'false';
        } catch(e) { 'false'; }
      " 2>/dev/null | grep -q "^true$"
      ;;
    azure)
      if ! command -v az &>/dev/null; then return 1; fi
      local state
      state=$(op_timeout 30 az repos pr show --id "$pr_num" 2>/dev/null || echo '{}')
      echo "$state" | node -p "
        try {
          const d = JSON.parse(require('fs').readFileSync('/dev/stdin','utf-8'));
          d.status === 'completed' ? 'true' : 'false';
        } catch(e) { 'false'; }
      " 2>/dev/null | grep -q "^true$"
      ;;
    gitlab)
      if ! command -v glab &>/dev/null; then return 1; fi
      local out
      out=$(op_timeout 30 glab mr view "$pr_num" 2>/dev/null || echo "state: open")
      echo "$out" | grep -qi "merged"
      ;;
    *)
      return 1
      ;;
  esac
}
