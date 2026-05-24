#!/usr/bin/env bats
# test/integration/cli_help.bats
#
# Verifies that all dispatched subcommands appear in --help output.
# Previously, stop/summary/ui/telemetry were wired but invisible.

REPO_ROOT="$(cd "$(dirname "$BATS_TEST_FILENAME")/../.." && pwd)"
ORCHESTRATE="$REPO_ROOT/orchestrate.sh"

setup() {
  # orchestrate.sh requires MONOZUKURI_HOME for some sourced libs;
  # point it at the repo root so no real install is needed.
  export MONOZUKURI_HOME="$REPO_ROOT"
}

@test "--help lists the 'stop' command" {
  run "$ORCHESTRATE" --help
  echo "$output" | grep -qE '^\s+stop\b'
}

@test "--help lists the 'summary' command" {
  run "$ORCHESTRATE" --help
  echo "$output" | grep -qE '^\s+summary\b'
}

@test "--help lists the 'ui' command" {
  run "$ORCHESTRATE" --help
  echo "$output" | grep -qE '^\s+ui\b'
}

@test "--help lists the 'telemetry' command" {
  run "$ORCHESTRATE" --help
  echo "$output" | grep -qE '^\s+telemetry\b'
}

@test "--help lists the 'backlog list' command" {
  run "$ORCHESTRATE" --help
  echo "$output" | grep -qE '^\s+backlog list\b'
}

@test "--help lists the 'backlog validate' command" {
  run "$ORCHESTRATE" --help
  echo "$output" | grep -qE '^\s+backlog validate\b'
}

@test "--help lists the 'pick' command" {
  run "$ORCHESTRATE" --help
  echo "$output" | grep -qE '^\s+pick\b'
}

@test "--help lists the 'memory lint' command" {
  run "$ORCHESTRATE" --help
  echo "$output" | grep -qE '^\s+memory lint\b'
}

@test "--help lists the 'memory migrate' command" {
  run "$ORCHESTRATE" --help
  echo "$output" | grep -qE '^\s+memory migrate\b'
}

@test "--help: all four previously-hidden commands appear" {
  run "$ORCHESTRATE" --help
  for cmd in stop summary ui telemetry; do
    echo "$output" | grep -qE "^\s+${cmd}\b" || {
      echo "Missing in --help: $cmd" >&2
      return 1
    }
  done
}
