#!/bin/bash
# scripts/orchestrate.sh — compatibility shim for Homebrew v1.0.0 installs
#
# The real entry point is the top-level orchestrate.sh.
# This shim is present so that existing $MONOZUKURI_HOME=scripts/ paths
# (set by Homebrew formula v1.0.0) continue to work transparently.
#
# NOTE: The Homebrew CELLAR copy of this file keeps the full logic for
# installed v1.0.0 builds. Only the DEV REPO's scripts/orchestrate.sh
# becomes this shim.

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
if [ -f "$REPO_ROOT/orchestrate.sh" ]; then
  exec bash "$REPO_ROOT/orchestrate.sh" "$@"
fi
echo "Cannot find orchestrate.sh in $REPO_ROOT" >&2
exit 1
