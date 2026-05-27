#!/usr/bin/env bats
# test/integration/v2_docs.bats - v2 documentation and release-readiness checks

REPO_ROOT="$(cd "$(dirname "$BATS_TEST_FILENAME")/../.." && pwd)"

line_no() {
  grep -n -m 1 "$1" "$2" | cut -d: -f1
}

@test "v2 migration guide covers upgrade workflow and troubleshooting" {
  doc="$REPO_ROOT/docs/v2-migration.md"

  [ -f "$doc" ]
  grep -q "^# Monozukuri v2 Migration Guide" "$doc"
  grep -q "^## Breaking changes" "$doc"
  grep -q "^## New commands" "$doc"
  grep -q "monozukuri memory migrate" "$doc"
  grep -q "^## Reading the Memory v2 schema" "$doc"
  grep -q "^## Troubleshooting" "$doc"

  issue_count="$(grep -c '^### [0-9][0-9]*\.' "$doc")"
  [ "$issue_count" -ge 10 ]
}

@test "README stays concise and points to v2 documentation" {
  readme="$REPO_ROOT/README.md"

  [ -f "$REPO_ROOT/docs/assets/pick-loop.gif" ]
  grep -q "docs/assets/pick-loop.gif" "$readme"
  grep -q "the art and science of making things" "$readme"
  grep -q "Created and maintained by Vinicius Carvalho" "$readme"
  grep -q "MIT © \\[Vinicius Carvalho\\]" "$readme"
  grep -q "^## Quick start" "$readme"
  grep -q "^## What Monozukuri does" "$readme"
  grep -q "^## Pick & Loop" "$readme"
  grep -q "^## Memory v2" "$readme"
  grep -q "^## Documentation" "$readme"
  grep -q "^## Architecture decisions" "$readme"
  grep -q "^## License" "$readme"
  grep -q "docs/v2-migration.md" "$readme"
  grep -q "docs/execution.md" "$readme"
  grep -q "docs/schemas/memory-v2.md" "$readme"
  grep -q "docs/adr/027-sufficiency-router.md" "$readme"

  quick_start="$(line_no '^## Quick start' "$readme")"
  what_it_does="$(line_no '^## What Monozukuri does' "$readme")"
  pick_loop="$(line_no '^## Pick & Loop' "$readme")"
  memory="$(line_no '^## Memory v2' "$readme")"
  docs="$(line_no '^## Documentation' "$readme")"
  license="$(line_no '^## License' "$readme")"

  [ "$quick_start" -lt "$what_it_does" ]
  [ "$what_it_does" -lt "$pick_loop" ]
  [ "$pick_loop" -lt "$memory" ]
  [ "$memory" -lt "$docs" ]
  [ "$docs" -lt "$license" ]

  line_count="$(wc -l < "$readme" | tr -d ' ')"
  [ "$line_count" -le 100 ]
}

@test "sufficiency router ADR records MEM-05 data and production marker" {
  adr="$REPO_ROOT/docs/adr/027-sufficiency-router.md"
  results="$REPO_ROOT/docs/experiments/sufficiency-router/results.json"

  [ -f "$adr" ]
  grep -q "Status: Accepted" "$adr"
  grep -q "Inject full" "$adr"
  grep -q "Always summary" "$adr"
  grep -q "Summary + on-demand escalation" "$adr"
  grep -q "schema pass rate" "$adr"
  grep -q "avg_total_tokens_estimated" "$adr"
  grep -q '<request-memory id="lrn-xxx"/>' "$adr"

  run jq -e '
    . as $root |
    .decision.proceed == true and
    .decision.strategy_c_winning_agents >= 2 and
    all(["claude-code","codex","gemini"][]; . as $agent | $root.aggregates[$agent]["on-demand"].schema_pass_rate == 1)
  ' "$results"
  [ "$status" -eq 0 ]
}

@test "agent instruction files document memory request marker without large growth" {
  marker='<request-memory id="lrn-xxx"/>'

  grep -q "$marker" "$REPO_ROOT/AGENTS.md"
  grep -q "$marker" "$REPO_ROOT/CLAUDE.md"
  grep -q "$marker" "$REPO_ROOT/GEMINI.md"

  base_size="$(git -C "$REPO_ROOT" show origin/main:AGENTS.md 2>/dev/null | wc -c | tr -d ' ')"
  if [ "$base_size" -eq 0 ]; then
    base_size="$(git -C "$REPO_ROOT" show HEAD^1:AGENTS.md 2>/dev/null | wc -c | tr -d ' ')"
  fi

  current_size="$(wc -c < "$REPO_ROOT/AGENTS.md" | tr -d ' ')"
  if [ "$base_size" -eq 0 ]; then
    base_size="$current_size"
  fi
  [ "$base_size" -gt 0 ]

  limit=$((base_size * 120 / 100))
  [ "$current_size" -le "$limit" ]
}

@test "v2 alpha release guide documents branch sync and gated publish steps" {
  doc="$REPO_ROOT/docs/release/v2-alpha.md"

  [ -f "$doc" ]
  grep -q "git fetch origin --prune" "$doc"
  grep -q "Branches not synced with main" "$doc"
  grep -q "release/v2.0.0-alpha" "$doc"
  grep -q "v2.0.0-alpha.1" "$doc"
  grep -q "npm.*next" "$doc"
  grep -q "brew.*next" "$doc"
  grep -q "release gate" "$doc"
  grep -q "early testers" "$doc"
}
