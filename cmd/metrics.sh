#!/bin/bash
# cmd/metrics.sh — metrics subcommand (Gap 5)
# Invoked via: monozukuri metrics
#
# Displays recent canary benchmark metrics and performance trends.

set -euo pipefail

# Sourced by orchestrate.sh; inherits SCRIPT_DIR, LIB_DIR, CMD_DIR,
# PROJECT_ROOT, ROOT_DIR, CONFIG_DIR, STATE_DIR, and all OPT_* variables.

sub_metrics() {
  source "$LIB_DIR/core/modules.sh"
  modules_init "$LIB_DIR"
  module_require core/util
  module_require memory/metrics

  local history_file="${PROJECT_ROOT}/docs/canary-history.md"

  if [ ! -f "$history_file" ]; then
    err "No canary history found. Run canary benchmarks to collect data."
    exit 1
  fi

  metrics_display "$history_file"
}
