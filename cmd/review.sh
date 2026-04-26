#!/bin/bash
# cmd/review.sh — review subcommands (ADR-015, Gap 6)
# Sourced by orchestrate.sh; inherits SCRIPT_DIR, LIB_DIR, CMD_DIR,
# SCRIPTS_DIR, TEMPLATES_DIR, PROJECT_ROOT, ROOT_DIR, CONFIG_DIR,
# STATE_DIR, RESULTS_DIR, and all OPT_* variables.
#
# Subcommands:
#   monozukuri review export <run-id>  — generate static HTML bundle
#   monozukuri review open <run-id>    — generate and open bundle in browser
#   monozukuri review list             — list all runs with summaries

sub_review() {
  local action="${1:-}"
  local run_id="${2:-}"

  source "$LIB_DIR/core/modules.sh"
  modules_init "$LIB_DIR"
  module_require core/util
  module_require cli/output

  # Source review bundle generator
  if [ ! -f "$LIB_DIR/review/bundle.sh" ]; then
    err "Review bundle module not found"
    exit 1
  fi
  source "$LIB_DIR/review/bundle.sh"

  case "$action" in
    export) review_export "$run_id" ;;
    open)   review_open "$run_id" ;;
    list)   review_list ;;
    *)
      err "Unknown review subcommand: ${action:-<none>}"
      info "Usage: monozukuri review {export|open|list} [run-id]"
      exit 1
      ;;
  esac
}

# ── export ──────────────────────────────────────────────────────────────────

review_export() {
  local run_id="$1"

  if [ -z "$run_id" ]; then
    err "Usage: monozukuri review export <run-id>"
    exit 1
  fi

  info "Generating review bundle for run: $run_id"

  local bundle_path
  bundle_path=$(generate_bundle "$run_id")

  if [ $? -ne 0 ] || [ -z "$bundle_path" ]; then
    err "Failed to generate bundle"
    exit 1
  fi

  banner "Bundle generated successfully"
  echo ""
  echo "  Path: $bundle_path"
  echo ""
  echo "  Open with:"
  echo "    monozukuri review open $run_id"
  echo ""
  echo "  Or open manually:"
  echo "    open '$bundle_path'"
  echo ""
}

# ── open ────────────────────────────────────────────────────────────────────

review_open() {
  local run_id="$1"

  if [ -z "$run_id" ]; then
    err "Usage: monozukuri review open <run-id>"
    exit 1
  fi

  # Generate bundle first (idempotent)
  local bundle_path
  bundle_path=$(generate_bundle "$run_id" 2>&1)

  if [ $? -ne 0 ] || [ -z "$bundle_path" ]; then
    err "Failed to generate bundle"
    exit 1
  fi

  if [ ! -f "$bundle_path" ]; then
    err "Bundle not found: $bundle_path"
    exit 1
  fi

  info "Opening bundle in browser..."

  # Detect platform and use appropriate command
  local platform
  platform=$(uname)

  case "$platform" in
    Darwin)
      open "$bundle_path"
      ;;
    Linux)
      if command -v xdg-open &>/dev/null; then
        xdg-open "$bundle_path" &>/dev/null &
      else
        err "xdg-open not found. Please open manually: $bundle_path"
        exit 1
      fi
      ;;
    *)
      err "Unsupported platform: $platform"
      err "Please open manually: $bundle_path"
      exit 1
      ;;
  esac

  echo ""
  echo "  Bundle: $bundle_path"
  echo ""
}

# ── list ────────────────────────────────────────────────────────────────────

review_list() {
  local runs_dir="$CONFIG_DIR/runs"

  if [ ! -d "$runs_dir" ]; then
    info "No runs found. Directory does not exist: $runs_dir"
    return 0
  fi

  # Collect runs with report.json
  local -a run_ids=()
  local run_dir

  for run_dir in "$runs_dir"/*/; do
    [ -d "$run_dir" ] || continue
    local report_file="$run_dir/report.json"
    [ -f "$report_file" ] || continue

    local run_id
    run_id=$(basename "$run_dir")
    run_ids+=("$run_id")
  done

  if [ ${#run_ids[@]} -eq 0 ]; then
    info "No completed runs found with report.json"
    return 0
  fi

  # Sort by date (newest first) using reverse sort
  IFS=$'\n' run_ids=($(sort -r <<<"${run_ids[*]}"))
  unset IFS

  # Print header
  banner "Available Runs"
  echo ""
  printf "  %-24s %-20s %8s %10s %12s\n" "RUN ID" "DATE" "HEADLINE" "FEATURES" "DURATION"
  printf "  %-24s %-20s %8s %10s %12s\n" "------------------------" "--------------------" "--------" "----------" "------------"

  # Print each run
  local run_id
  for run_id in "${run_ids[@]}"; do
    local report_file="$runs_dir/$run_id/report.json"

    if [ ! -f "$report_file" ]; then
      continue
    fi

    # Extract metrics from report.json
    local started_at headline_pct completed_features total_features duration_seconds

    started_at=$(jq -r '.started_at // ""' "$report_file" 2>/dev/null)
    headline_pct=$(jq -r '.headline_pct // 0' "$report_file" 2>/dev/null)
    completed_features=$(jq -r '.completed_features // 0' "$report_file" 2>/dev/null)
    total_features=$(jq -r '.total_features // 0' "$report_file" 2>/dev/null)
    duration_seconds=$(jq -r '.duration_seconds // 0' "$report_file" 2>/dev/null)

    # Format date (extract date portion)
    local date_str
    date_str=$(echo "$started_at" | cut -d'T' -f1 2>/dev/null)
    [ -z "$date_str" ] && date_str="unknown"

    # Format duration
    local duration_str
    if [ "$duration_seconds" -lt 60 ]; then
      duration_str="${duration_seconds}s"
    elif [ "$duration_seconds" -lt 3600 ]; then
      local mins=$((duration_seconds / 60))
      local secs=$((duration_seconds % 60))
      duration_str="${mins}m ${secs}s"
    else
      local hours=$((duration_seconds / 3600))
      local mins=$(( (duration_seconds % 3600) / 60 ))
      duration_str="${hours}h ${mins}m"
    fi

    printf "  %-24s %-20s %7s%% %4s / %-4s %12s\n" \
      "$run_id" \
      "$date_str" \
      "$headline_pct" \
      "$completed_features" \
      "$total_features" \
      "$duration_str"
  done

  echo ""
  echo "  To view a run:"
  echo "    monozukuri review open <run-id>"
  echo ""
}
