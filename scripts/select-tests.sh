#!/usr/bin/env bash
# scripts/select-tests.sh — compute the minimal BATS test set for a PR
#
# Usage:
#   scripts/select-tests.sh [--base <branch>] [--unit-only] [--integration-only]
#
# Reads test/test-map.json, diffs against <base> (default: origin/main),
# and prints a space-separated list of .bats files to stdout.
#
# Exit codes:
#   0  — list emitted (may be "ALL" when blast-radius file changed)
#   1  — test-map missing or invalid
#
# CI usage:
#   TESTS=$(scripts/select-tests.sh)
#   if [ "$TESTS" = "ALL" ]; then bats --jobs 4 test/unit/ test/integration/
#   else bats $TESTS; fi

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
MAP_FILE="$REPO_ROOT/test/test-map.json"

BASE_BRANCH="origin/main"
UNIT_ONLY=false
INTEGRATION_ONLY=false

while [[ $# -gt 0 ]]; do
  case "$1" in
    --base) BASE_BRANCH="$2"; shift 2 ;;
    --unit-only) UNIT_ONLY=true; shift ;;
    --integration-only) INTEGRATION_ONLY=true; shift ;;
    *) echo "unknown arg: $1" >&2; exit 1 ;;
  esac
done

if [ ! -f "$MAP_FILE" ]; then
  echo "select-tests: test-map not found at $MAP_FILE" >&2
  exit 1
fi

# Collect changed files relative to repo root
changed=$(git -C "$REPO_ROOT" diff --name-only "$BASE_BRANCH"...HEAD 2>/dev/null || \
          git -C "$REPO_ROOT" diff --name-only HEAD 2>/dev/null || true)

if [ -z "$changed" ]; then
  echo "select-tests: no changed files detected; running full suite" >&2
  echo "ALL"
  exit 0
fi

# Check blast-radius files first
blast=$(python3 - "$MAP_FILE" "$changed" <<'PYEOF'
import json, sys
map_file, changed_str = sys.argv[1], sys.argv[2]
data = json.loads(open(map_file).read())
blast = set(data.get("blast_radius", []))
for f in changed_str.strip().splitlines():
    if f.strip() in blast:
        print("BLAST")
        sys.exit(0)
PYEOF
)

if [ "${blast:-}" = "BLAST" ]; then
  echo "select-tests: blast-radius file changed — running full suite" >&2
  echo "ALL"
  exit 0
fi

# Resolve test files for all changed source files
selected=$(python3 - "$MAP_FILE" "$changed" "$UNIT_ONLY" "$INTEGRATION_ONLY" <<'PYEOF'
import json, sys
from pathlib import Path

map_file, changed_str, unit_only, int_only = sys.argv[1], sys.argv[2], sys.argv[3], sys.argv[4]
data = json.loads(open(map_file).read())
mapping = data.get("map", {})

selected = set()
for src in changed_str.strip().splitlines():
    src = src.strip()
    # exact match
    if src in mapping:
        selected.update(mapping[src])
        continue
    # prefix match for directory-level entries (e.g. skills/mz-create-prd/...)
    for key in mapping:
        if src.startswith(key + "/") or src.startswith(key):
            selected.update(mapping[key])
            break

# Filter by type flags
if unit_only == "true":
    selected = {t for t in selected if "/unit/" in t}
elif int_only == "true":
    selected = {t for t in selected if "/integration/" in t}

# Only emit tests that actually exist on disk
repo_root = Path(map_file).parent.parent
existing = [t for t in sorted(selected) if (repo_root / t).exists()]
print("\n".join(existing))
PYEOF
)

if [ -z "$selected" ]; then
  echo "select-tests: no tests map to the changed files; running full suite as safety net" >&2
  echo "ALL"
  exit 0
fi

echo "$selected"
