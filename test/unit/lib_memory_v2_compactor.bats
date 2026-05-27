#!/usr/bin/env bats
# test/unit/lib_memory_v2_compactor.bats — Memory v2 deterministic compactor

setup() {
  REPO_ROOT="$(cd "$(dirname "$BATS_TEST_FILENAME")/../.." && pwd)"
  TMPDIR_TEST="$(mktemp -d)"
  PROJECT_DIR="$TMPDIR_TEST/project"
  mkdir -p "$PROJECT_DIR/.monozukuri"
  export ROOT_DIR="$PROJECT_DIR"
  export CONFIG_DIR="$PROJECT_DIR/.monozukuri"
  export MONOZUKURI_RUN_DIR="$CONFIG_DIR/runs"
  export MONOZUKURI_MEMORY_SUMMARY_TOKEN_CAP=80
  source "$REPO_ROOT/lib/memory/v2.sh"
}

teardown() {
  rm -rf "$TMPDIR_TEST"
}

write_many_learnings() {
  cat > "$TMPDIR_TEST/learnings.json" <<'JSON'
[
  {
    "id": "lrn-feature-low",
    "scope": "feature",
    "insight": "Feature low-count learning should be ordered after the hotter feature learning.",
    "source": {"feature_id": "feat-123"},
    "applied_count": 1
  },
  {
    "id": "lrn-feature-hot",
    "scope": "feature",
    "insight": "Feature hot learning should be first inside the feature group.",
    "source": {"feature_id": "feat-123"},
    "applied_count": 9
  },
  {
    "id": "lrn-project-hot",
    "scope": "project",
    "insight": "Project hot learning should appear before colder project learnings.",
    "source": {"feature_id": "other"},
    "applied_count": 7
  },
  {
    "id": "lrn-global-hot",
    "scope": "global",
    "insight": "Global hot learning should appear after project entries by group order.",
    "source": {"feature_id": "other"},
    "applied_count": 6
  },
  {
    "id": "lrn-project-cold",
    "scope": "project",
    "insight": "Project cold learning may be omitted when the token cap is tight.",
    "source": {"feature_id": "other"},
    "applied_count": 2
  }
]
JSON
}

@test "summarize_for_phase groups by scope orders by applied_count and honors token cap" {
  write_many_learnings
  export MONOZUKURI_MEMORY_SUMMARY_TOKEN_CAP=160

  run summarize_for_phase prd feat-123 "$(cat "$TMPDIR_TEST/learnings.json")"

  [ "$status" -eq 0 ]
  [[ "$output" == *"[lrn-feature-hot, applied 9x]"* ]]
  [[ "$output" == *"[lrn-project-hot, applied 7x]"* ]]
  [[ "$output" == *"<!-- learning: lrn-feature-hot -->"* ]]

  feature_hot_line=$(grep -n "lrn-feature-hot" <<<"$output" | head -1 | cut -d: -f1)
  feature_low_line=$(grep -n "lrn-feature-low" <<<"$output" | head -1 | cut -d: -f1)
  project_hot_line=$(grep -n "lrn-project-hot" <<<"$output" | head -1 | cut -d: -f1)
  [ "$feature_hot_line" -lt "$feature_low_line" ]
  [ "$feature_low_line" -lt "$project_hot_line" ]

  run memory_v2_token_count "$output"
  [ "$status" -eq 0 ]
  [ "$output" -le "$MONOZUKURI_MEMORY_SUMMARY_TOKEN_CAP" ]
}

@test "memory_v2_context_entries reports omitted IDs as available_on_request" {
  write_many_learnings
  cp "$TMPDIR_TEST/learnings.json" "$CONFIG_DIR/memory-v2.json"
  export MONOZUKURI_MEMORY_SUMMARY_TOKEN_CAP=35
  export MONOZUKURI_RUN_ID="run-memory-summary"

  run memory_v2_context_entries feat-123

  [ "$status" -eq 0 ]
  run jq -e '
    any(.[]; (.summary // "") | contains("[lrn-feature-hot, applied 9x]")) and
    any(.[]; (.available_on_request // []) | index("lrn-project-cold"))
  ' <<<"$output"
  [ "$status" -eq 0 ]

  trace="$MONOZUKURI_RUN_DIR/$MONOZUKURI_RUN_ID/memory-trace.jsonl"
  [ -f "$trace" ]
  run jq -e '
    select(.event == "summarize") |
    .phase == "context" and
    .feature_id == "feat-123" and
    (.entered | index("lrn-feature-hot")) and
    (.included | index("lrn-feature-hot")) and
    (.omitted | index("lrn-project-cold")) and
    (.tokens | type == "number")
  ' "$trace"
  [ "$status" -eq 0 ]
}

@test "summarize_for_phase reuses cache for identical learning content" {
  write_many_learnings
  first="$(summarize_for_phase prd feat-123 "$(cat "$TMPDIR_TEST/learnings.json")")"
  [ -n "$first" ]

  cache_file="$(find "$CONFIG_DIR/cache/memory" -type f -name '*.json' | head -1)"
  [ -n "$cache_file" ]
  jq '.summary_text = "cached sentinel summary"' "$cache_file" > "$cache_file.tmp"
  mv "$cache_file.tmp" "$cache_file"

  run summarize_for_phase prd feat-123 "$(cat "$TMPDIR_TEST/learnings.json")"

  [ "$status" -eq 0 ]
  [ "$output" = "cached sentinel summary" ]
}

@test "summarize_for_phase cache misses when learning content changes" {
  write_many_learnings
  summarize_for_phase prd feat-123 "$(cat "$TMPDIR_TEST/learnings.json")" >/dev/null

  jq '.[0].insight = "Changed learning content invalidates the content hash cache."' \
    "$TMPDIR_TEST/learnings.json" > "$TMPDIR_TEST/changed.json"

  run summarize_for_phase prd feat-123 "$(cat "$TMPDIR_TEST/changed.json")"

  [ "$status" -eq 0 ]
  [[ "$output" == *"Changed learning content"* ]]
  [ "$(find "$CONFIG_DIR/cache/memory" -type f -name '*.json' | wc -l | tr -d ' ')" -eq 2 ]
}

@test "summarize_for_phase ignores cache entries older than seven days" {
  write_many_learnings
  summarize_for_phase prd feat-123 "$(cat "$TMPDIR_TEST/learnings.json")" >/dev/null

  cache_file="$(find "$CONFIG_DIR/cache/memory" -type f -name '*.json' | head -1)"
  jq '.summary_text = "stale sentinel summary"' "$cache_file" > "$cache_file.tmp"
  mv "$cache_file.tmp" "$cache_file"
  python3 - "$cache_file" <<'PY'
import os
import sys
stale = 8 * 24 * 60 * 60
ts = __import__("time").time() - stale
os.utime(sys.argv[1], (ts, ts))
PY

  run summarize_for_phase prd feat-123 "$(cat "$TMPDIR_TEST/learnings.json")"

  [ "$status" -eq 0 ]
  [[ "$output" != "stale sentinel summary" ]]
  [[ "$output" == *"[lrn-feature-hot, applied 9x]"* ]]
}
