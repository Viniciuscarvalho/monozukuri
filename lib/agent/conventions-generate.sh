#!/bin/bash
# lib/agent/conventions-generate.sh — Build the monozukuri-generated block for AGENTS.md.
#
# Reads non-archived entries from project and global learning tiers, plus any
# auto-detected stack commands, and prints the marker-wrapped block to stdout.
#
# Usage:
#   source "$LIB_DIR/agent/conventions-generate.sh"
#   conventions_generate_content REPO_ROOT
#
# Dependencies: jq (JSON), no writes — pure stdout.

_GENERATE_MARKER_START='<!-- monozukuri:generated-start v1 -->'
_GENERATE_MARKER_END='<!-- monozukuri:generated-end -->'

conventions_generate_content() {
  local repo_root="${1:?conventions_generate_content: REPO_ROOT required}"

  local project_path="$repo_root/.claude/feature-state/learned.json"
  local global_path="$HOME/.claude/monozukuri/learned/learned.json"

  local project_entries global_entries
  project_entries=$([ -f "$project_path" ] && cat "$project_path" || echo '[]')
  global_entries=$([ -f "$global_path" ] && cat "$global_path" || echo '[]')

  # Merge tiers, deduplicate by pattern (project wins), sort by confidence desc.
  local learnings
  learnings=$(jq -n \
    --argjson proj "$project_entries" \
    --argjson glob "$global_entries" \
    '($proj + $glob)
     | [.[] | select(.archived != true)]
     | group_by(.pattern)
     | [.[] | first]
     | sort_by(-.confidence)' 2>/dev/null || echo '[]')

  local count
  count=$(jq 'length' <<<"$learnings")

  printf '%s\n' "$_GENERATE_MARKER_START"
  printf '<!-- This section is maintained by monozukuri. Manual edits inside these markers will be overwritten on next generate. -->\n'

  local build_cmd="${PROJECT_BUILD_CMD:-}"
  local test_cmd="${PROJECT_TEST_CMD:-}"

  if [[ -n "$build_cmd" ]]; then
    printf '\n## Build\n\nRun: `%s`\n' "$build_cmd"
  fi

  if [[ -n "$test_cmd" ]]; then
    printf '\n## Test\n\nRun: `%s`\n' "$test_cmd"
  fi

  if [[ "$count" -gt 0 ]]; then
    printf '\n## Conventions\n\n'
    jq -r '.[] | "- `" + .pattern + "` → " + .fix' <<<"$learnings"
  fi

  printf '\n%s\n' "$_GENERATE_MARKER_END"
}
