#!/bin/bash
# lib/review/bundle.sh — Generate self-contained HTML review bundle (Gap 6)
#
# Reads manifest.json and report.json, inlines data into template,
# writes static HTML bundle to runs/<run-id>/review/index.html
#
# Public interface:
#   generate_bundle <run_id>              → returns bundle path on success

generate_bundle() {
  local run_id="$1"

  [ -z "$run_id" ] && { echo "generate_bundle: run_id required" >&2; return 1; }

  local run_dir="$CONFIG_DIR/runs/$run_id"
  local manifest_file="$run_dir/manifest.json"
  local report_file="$run_dir/report.json"
  local bundle_dir="$run_dir/review"
  local bundle_path="$bundle_dir/index.html"

  # Validate inputs
  if [ ! -d "$run_dir" ]; then
    echo "Run directory not found: $run_dir" >&2
    return 1
  fi

  if [ ! -f "$manifest_file" ]; then
    echo "No manifest.json found for run: $run_id" >&2
    return 1
  fi

  if [ ! -f "$report_file" ]; then
    echo "No report.json found for run: $run_id" >&2
    echo "Run 'monozukuri run' to completion or regenerate report" >&2
    return 1
  fi

  # Read data files
  local manifest_json report_json
  manifest_json=$(cat "$manifest_file")
  report_json=$(cat "$report_file")

  # Validate JSON
  if ! echo "$manifest_json" | jq empty 2>/dev/null; then
    echo "Invalid JSON in manifest.json" >&2
    return 1
  fi

  if ! echo "$report_json" | jq empty 2>/dev/null; then
    echo "Invalid JSON in report.json" >&2
    return 1
  fi

  # Create bundle directory
  mkdir -p "$bundle_dir"

  # Render template
  render_template "$manifest_json" "$report_json" > "$bundle_path"

  if [ $? -ne 0 ] || [ ! -f "$bundle_path" ]; then
    echo "Failed to generate bundle" >&2
    return 1
  fi

  echo "$bundle_path"
}

render_template() {
  local manifest="$1"
  local report="$2"

  local template="$MONOZUKURI_HOME/lib/review/template/index.html.tpl"

  if [ ! -f "$template" ]; then
    echo "Template not found: $template" >&2
    return 1
  fi

  # Escape data for safe embedding in JavaScript
  # jq -c outputs compact JSON suitable for inline embedding
  local manifest_escaped report_escaped
  manifest_escaped=$(echo "$manifest" | jq -c .)
  report_escaped=$(echo "$report" | jq -c .)

  # Replace placeholders in template
  # Use sed with different delimiters to avoid conflict with JSON
  sed "s|__MANIFEST_DATA__|${manifest_escaped}|g; s|__REPORT_DATA__|${report_escaped}|g" "$template"
}
