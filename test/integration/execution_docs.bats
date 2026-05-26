#!/usr/bin/env bats
# test/integration/execution_docs.bats - execution documentation checks

REPO_ROOT="$(cd "$(dirname "$BATS_TEST_FILENAME")/../.." && pwd)"

@test "execution docs describe supervised mode gates and reference existing assets" {
  doc="$REPO_ROOT/docs/execution.md"

  [ -f "$doc" ]
  grep -q "## Supervised mode (Ink TUI)" "$doc"
  grep -q "Approve" "$doc"
  grep -q "Retry" "$doc"
  grep -q "Abort" "$doc"
  grep -q "state is written" "$doc"
  grep -q "monozukuri run --autonomy checkpoint" "$doc"

  while IFS= read -r image_path; do
    [ -f "$REPO_ROOT/docs/$image_path" ]
  done < <(grep -oE '!\[[^]]*\]\(([^)]+)\)' "$doc" | sed -E 's/.*\(([^)]+)\).*/\1/' | grep '^assets/')

  [ -f "$REPO_ROOT/docs/assets/hero.tape" ]
  ! grep -q "assets/supervised.cast" "$doc"
}
