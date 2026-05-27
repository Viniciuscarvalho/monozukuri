#!/usr/bin/env bash
# scripts/select-tests.sh - compute the risk-tiered Bats test set for a PR.
#
# Usage:
#   scripts/select-tests.sh [--base <branch>] [--tier <name>] [--scope]
#   scripts/select-tests.sh [--base <branch>] [--unit-only|--integration-only]
#
# Tiers are declared in test/test-map.json:
#   unit, integration-fast, integration-extended, nightly, release
#
# Exit codes:
#   0 - list emitted, scope emitted, or no tests in the requested tier
#   1 - test-map missing/invalid or unknown argument

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
MAP_FILE="$REPO_ROOT/test/test-map.json"

BASE_BRANCH="origin/main"
TIER=""
SCOPE_ONLY=false

while [ $# -gt 0 ]; do
  case "$1" in
    --base)
      BASE_BRANCH="$2"
      shift 2
      ;;
    --tier)
      TIER="$2"
      shift 2
      ;;
    --unit-only)
      TIER="unit"
      shift
      ;;
    --integration-only)
      TIER="integration-fast"
      shift
      ;;
    --scope)
      SCOPE_ONLY=true
      shift
      ;;
    *)
      echo "unknown arg: $1" >&2
      exit 1
      ;;
  esac
done

if [ ! -f "$MAP_FILE" ]; then
  echo "select-tests: test-map not found at $MAP_FILE" >&2
  exit 1
fi

changed=$(git -C "$REPO_ROOT" diff --name-only "$BASE_BRANCH"...HEAD 2>/dev/null ||
  git -C "$REPO_ROOT" diff --name-only HEAD 2>/dev/null || true)

python3 - "$MAP_FILE" "$REPO_ROOT" "$changed" "$TIER" "$SCOPE_ONLY" <<'PYEOF'
import json
import sys
from pathlib import Path

map_file, repo_root_raw, changed_raw, tier, scope_only_raw = sys.argv[1:6]
repo_root = Path(repo_root_raw)
scope_only = scope_only_raw == "true"

try:
    data = json.loads(Path(map_file).read_text())
except Exception as exc:
    print(f"select-tests: invalid test-map: {exc}", file=sys.stderr)
    sys.exit(1)

mapping = data.get("map", {})
blast_radius = set(data.get("blast_radius", []))
tiers = data.get("tiers", {})
changed = [line.strip() for line in changed_raw.splitlines() if line.strip()]

if tier and tier not in tiers:
    print(f"select-tests: unknown tier: {tier}", file=sys.stderr)
    sys.exit(1)

def normalized_spec(name):
    spec = tiers.get(name, {})
    if isinstance(spec, list):
        return {"include": spec, "exclude": []}
    return {
        "include": spec.get("include", []),
        "exclude": spec.get("exclude", []),
    }

def path_matches(path, patterns):
    return any(path == pattern or path.startswith(pattern.rstrip("/") + "/") for pattern in patterns)

def in_tier(path, name):
    if not name:
        return True
    spec = normalized_spec(name)
    includes = spec["include"]
    excludes = spec["exclude"]
    return path_matches(path, includes) and not path_matches(path, excludes)

def existing_test(path):
    return path.endswith(".bats") and (repo_root / path).exists()

def all_tests_for_tier(name):
    if not name:
        return ["ALL"]
    spec = normalized_spec(name)
    selected = set()
    for pattern in spec["include"]:
        candidate = repo_root / pattern
        if candidate.is_dir():
            selected.update(str(path.relative_to(repo_root)) for path in candidate.rglob("*.bats"))
        elif candidate.is_file() and pattern.endswith(".bats"):
            selected.add(pattern)
    return sorted(path for path in selected if in_tier(path, name) and existing_test(path))

def mapped_tests_for_change(src):
    if src in mapping:
        return list(mapping[src]), True
    for key, tests in mapping.items():
        if src.startswith(key.rstrip("/") + "/") or src.startswith(key):
            return list(tests), True
    return [], False

fallback = False
selected = set()
unmapped = []

if not changed:
    fallback = True

for src in changed:
    if src in blast_radius:
        fallback = True
        continue
    tests, matched = mapped_tests_for_change(src)
    if matched:
        selected.update(tests)
    else:
        unmapped.append(src)
        fallback = True

if scope_only:
    print("fallback" if fallback else "targeted")
    sys.exit(0)

if fallback:
    if not tier:
        print("ALL")
        sys.exit(0)
    print("\n".join(all_tests_for_tier(tier)))
    sys.exit(0)

existing = sorted(path for path in selected if in_tier(path, tier) and existing_test(path))
print("\n".join(existing))
PYEOF
