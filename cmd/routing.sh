#!/bin/bash
# cmd/routing.sh — routing subcommands (ADR-015, Gap 4)
# Sourced by orchestrate.sh; inherits SCRIPT_DIR, LIB_DIR, CMD_DIR,
# SCRIPTS_DIR, TEMPLATES_DIR, PROJECT_ROOT, ROOT_DIR, CONFIG_DIR,
# STATE_DIR, RESULTS_DIR, and all OPT_* variables.
#
# Subcommands:
#   monozukuri routing suggest [<phase>]   — data-threshold-gated adapter recommendation

_ROUTING_SUGGEST_THRESHOLD=4
_ROUTING_W_CI="0.6"
_ROUTING_W_COST="0.4"

sub_routing() {
  local action="${OPT_ROUTING_ACTION:-}"
  local phase_filter="${OPT_ROUTING_PHASE:-}"

  source "$LIB_DIR/core/modules.sh"
  modules_init "$LIB_DIR"
  module_require core/util
  module_require cli/output

  local data_root="${STATE_DIR}/routing-data"

  case "$action" in
    suggest) _routing_sub_suggest "$phase_filter" "$data_root" ;;
    *)
      err "Unknown routing subcommand: ${action:-<none>}"
      info "Usage: monozukuri routing suggest [<phase>]"
      exit 1
      ;;
  esac
}

# ── suggest ──────────────────────────────────────────────────────────────────

_routing_sub_suggest() {
  local phase_filter="$1" data_root="$2"

  if [ ! -d "$data_root" ]; then
    printf 'routing suggest: no routing data found. Run canary benchmarks to collect data.\n'
    return 0
  fi

  # Build list of phases to evaluate
  local -a phases=()
  if [ -n "$phase_filter" ]; then
    phases=("$phase_filter")
  else
    local seen=""
    local jsonl
    for jsonl in "$data_root"/*/*.jsonl; do
      [ -f "$jsonl" ] || continue
      local ph
      ph="$(basename "$jsonl" .jsonl)"
      [[ "$seen" == *"|$ph|"* ]] || { phases+=("$ph"); seen+="|$ph|"; }
    done
  fi

  if [ ${#phases[@]} -eq 0 ]; then
    printf 'routing suggest: no routing data found. Run canary benchmarks to collect data.\n'
    return 0
  fi

  local phase
  for phase in "${phases[@]}"; do
    _routing_suggest_phase "$phase" "$data_root"
  done
}

_routing_suggest_phase() {
  local phase="$1" data_root="$2"

  # Discover adapters that have data for this phase
  local -a adapters=()
  local adapter_dir
  for adapter_dir in "$data_root"/*/; do
    [ -d "$adapter_dir" ] || continue
    local adapter
    adapter="$(basename "$adapter_dir")"
    [ -f "$adapter_dir/${phase}.jsonl" ] && adapters+=("$adapter")
  done

  [ ${#adapters[@]} -eq 0 ] && return 0

  printf '\n── Phase: %s ──\n' "$phase"

  # Count runs per adapter; collect below-threshold adapters
  local -a below_threshold=()
  declare -A run_counts=()
  local adapter
  for adapter in "${adapters[@]}"; do
    local jsonl="$data_root/$adapter/${phase}.jsonl"
    local count
    count="$(grep -c '' "$jsonl" 2>/dev/null || printf '0')"
    run_counts["$adapter"]="$count"
    [ "$count" -lt "$_ROUTING_SUGGEST_THRESHOLD" ] && below_threshold+=("$adapter")
  done

  if [ ${#below_threshold[@]} -gt 0 ]; then
    printf 'routing suggest: insufficient data for %s phase.\n' "$phase"
    for adapter in "${adapters[@]}"; do
      printf '  %s: %d runs' "$adapter" "${run_counts[$adapter]:-0}"
      [ "${run_counts[$adapter]:-0}" -lt "$_ROUTING_SUGGEST_THRESHOLD" ] && \
        printf ' · need ≥ %d' "$_ROUTING_SUGGEST_THRESHOLD"
      printf '\n'
    done
    printf 'run more canaries or wait for next scheduled run.\n'
    return 0
  fi

  # Gather all cost values across all adapters for cross-adapter percentile
  local costs_tmp
  costs_tmp="$(mktemp /tmp/mzk-routing-costs.XXXXXX)"

  for adapter in "${adapters[@]}"; do
    grep -o '"cost_usd":[0-9.]*' "$data_root/$adapter/${phase}.jsonl" \
      | cut -d: -f2 >> "$costs_tmp"
  done

  local sorted_costs_tmp
  sorted_costs_tmp="$(mktemp /tmp/mzk-routing-sorted.XXXXXX)"
  sort -n "$costs_tmp" > "$sorted_costs_tmp"
  local total_costs
  total_costs="$(grep -c '' "$sorted_costs_tmp" 2>/dev/null || printf '0')"

  # Compute per-adapter score and find the best
  local best_adapter="" best_score="-1"
  local stats_tmp
  stats_tmp="$(mktemp /tmp/mzk-routing-stats.XXXXXX)"

  for adapter in "${adapters[@]}"; do
    local jsonl="$data_root/$adapter/${phase}.jsonl"
    local runs="${run_counts[$adapter]}"

    # ci_pass_rate (0.0–1.0)
    local ci_rate
    ci_rate="$(grep -o '"ci_pass":[0-9]*' "$jsonl" \
      | cut -d: -f2 \
      | awk -v n="$runs" '{s+=$1} END {printf "%.6f", (n>0)?s/n:0}')"

    # median cost for this adapter
    local adapter_costs_tmp
    adapter_costs_tmp="$(mktemp /tmp/mzk-routing-ac.XXXXXX)"
    grep -o '"cost_usd":[0-9.]*' "$jsonl" | cut -d: -f2 | sort -n > "$adapter_costs_tmp"
    local median_idx
    median_idx="$(( $(grep -c '' "$adapter_costs_tmp") / 2 ))"
    local median_cost
    median_cost="$(sed -n "$((median_idx + 1))p" "$adapter_costs_tmp")"
    rm -f "$adapter_costs_tmp"

    # cost_percentile: fraction of all costs ≤ median (0.0–1.0)
    local cost_pct
    cost_pct="$(awk -v med="${median_cost:-0}" -v tot="$total_costs" \
      'NR>0 && $1+0 <= med+0 {r++} END {printf "%.6f", (tot>0)?r/tot:0}' \
      "$sorted_costs_tmp")"

    # score = 0.6 × ci_pass_rate + 0.4 × (1 − cost_percentile)
    local score
    score="$(awk -v ci="$ci_rate" -v cp="$cost_pct" -v wci="$_ROUTING_W_CI" -v wco="$_ROUTING_W_COST" \
      'BEGIN {printf "%.3f", wci * ci + wco * (1 - cp)}')"

    local ci_pct cost_p_pct
    ci_pct="$(awk -v r="$ci_rate" 'BEGIN {printf "%.0f", r*100}')"
    cost_p_pct="$(awk -v r="$cost_pct" 'BEGIN {printf "%.0f", r*100}')"

    printf '  %s: ci_pass_rate=%s%% cost_p%s%% score=%s (runs=%s)\n' \
      "$adapter" "$ci_pct" "$cost_p_pct" "$score" "$runs"

    printf '%s %s\n' "$adapter" "$score" >> "$stats_tmp"

    if awk -v s="$score" -v b="$best_score" 'BEGIN {exit (s+0 > b+0) ? 0 : 1}'; then
      best_score="$score"
      best_adapter="$adapter"
    fi
  done

  rm -f "$costs_tmp" "$sorted_costs_tmp" "$stats_tmp"

  if [ -n "$best_adapter" ]; then
    printf '\nrecommendation: %s (score=%s)\n' "$best_adapter" "$best_score"
    printf 'to apply, add to .monozukuri/routing.yaml:\n'
    printf '  phases:\n    %s: %s\n' "$phase" "$best_adapter"
  fi
}
