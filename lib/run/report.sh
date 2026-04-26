#!/bin/bash
# lib/run/report.sh — Generate run report at completion (Gap 6)
#
# Aggregates manifest.json and feature checkpoints into report.json
# for consumption by the review bundle generator.
#
# Public interface:
#   generate_run_report <run_id>

generate_run_report() {
  local run_id="$1"

  [ -z "$run_id" ] && { warn "generate_run_report: run_id required"; return 1; }

  local run_dir="$CONFIG_DIR/runs/$run_id"
  local manifest_file="$run_dir/manifest.json"
  local report_path="$run_dir/report.json"

  # Validate manifest exists
  if [ ! -f "$manifest_file" ]; then
    warn "generate_run_report: manifest not found for run $run_id"
    return 1
  fi

  # Read manifest data
  local manifest_json
  manifest_json=$(cat "$manifest_file")

  local started_at
  started_at=$(echo "$manifest_json" | node -p "JSON.parse(require('fs').readFileSync('/dev/stdin','utf-8')).started_at")

  local features_json
  features_json=$(echo "$manifest_json" | node -p "JSON.stringify(JSON.parse(require('fs').readFileSync('/dev/stdin','utf-8')).features || [])")

  # Calculate metrics
  local finished_at
  finished_at=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

  local duration=0
  if [ -n "$started_at" ]; then
    local start_epoch finish_epoch
    start_epoch=$(date -j -f "%Y-%m-%dT%H:%M:%SZ" "$started_at" +%s 2>/dev/null || date -d "$started_at" +%s 2>/dev/null || echo 0)
    finish_epoch=$(date -j -f "%Y-%m-%dT%H:%M:%SZ" "$finished_at" +%s 2>/dev/null || date -d "$finished_at" +%s 2>/dev/null || echo 0)
    duration=$((finish_epoch - start_epoch))
  fi

  # Count feature statuses from manifest
  local total_features completed_features failed_features
  total_features=$(echo "$features_json" | node -p "JSON.parse(require('fs').readFileSync('/dev/stdin','utf-8')).length")
  completed_features=$(echo "$features_json" | node -p "JSON.parse(require('fs').readFileSync('/dev/stdin','utf-8')).filter(f => f.status === 'done' || f.status === 'pr-created').length")
  failed_features=$((total_features - completed_features))

  # Calculate headline percentage
  local headline_pct=0
  if [ "$total_features" -gt 0 ]; then
    headline_pct=$(( (completed_features * 100) / total_features ))
  fi

  # Aggregate costs and tokens from feature checkpoints
  local total_tokens=0
  local total_cost=0

  for dir in "$STATE_DIR"/*/; do
    [ -d "$dir" ] || continue
    local fid
    fid=$(basename "$dir")

    # Read cost from feature checkpoint if available
    local cost_file="$dir/cost.json"
    if [ -f "$cost_file" ]; then
      local tokens
      tokens=$(jq -r '.total_tokens // 0' "$cost_file" 2>/dev/null || echo 0)
      local cost
      cost=$(jq -r '.total_cost // 0' "$cost_file" 2>/dev/null || echo 0)

      total_tokens=$((total_tokens + tokens))
      # Use bc for floating point addition
      total_cost=$(echo "$total_cost + $cost" | bc 2>/dev/null || echo "$total_cost")
    fi
  done

  # Enrich features with checkpoint data
  local enriched_features
  enriched_features=$(node - "$features_json" "$STATE_DIR" <<'JSEOF' 2>/dev/null
const [,, features_json, state_dir] = process.argv;
const fs = require('fs');
const path = require('path');

const features = JSON.parse(features_json);
const enriched = features.map(f => {
  const feat_dir = path.join(state_dir, f.feat_id);
  const cost_file = path.join(feat_dir, 'cost.json');
  const status_file = path.join(feat_dir, 'status.json');

  let tokens = 0;
  let cost_usd = 0;
  if (fs.existsSync(cost_file)) {
    try {
      const cost_data = JSON.parse(fs.readFileSync(cost_file, 'utf-8'));
      tokens = cost_data.total_tokens || 0;
      cost_usd = parseFloat(cost_data.total_cost || 0);
    } catch (e) {}
  }

  let title = f.title || '';
  let stack = '';
  let phases_completed = 0;
  let phase_retries = 0;
  let failure_reason = null;

  if (fs.existsSync(status_file)) {
    try {
      const status_data = JSON.parse(fs.readFileSync(status_file, 'utf-8'));
      title = status_data.title || title;
      stack = status_data.stack || '';
      phases_completed = status_data.phases_completed || 0;
      phase_retries = status_data.phase_retries || 0;
      failure_reason = status_data.failure_reason || null;
    } catch (e) {}
  }

  return {
    id: f.feat_id,
    title: title,
    stack: stack,
    status: f.status || 'unknown',
    pr_url: f.pr_url || null,
    tokens: tokens,
    cost_usd: cost_usd,
    phases_completed: phases_completed,
    phase_retries: phase_retries,
    failure_reason: failure_reason
  };
});

console.log(JSON.stringify(enriched));
JSEOF
)

  # Fallback if node enrichment fails
  if [ -z "$enriched_features" ] || [ "$enriched_features" = "null" ]; then
    enriched_features='[]'
  fi

  # Write report.json
  local tmp_file
  tmp_file=$(mktemp "$run_dir/report.XXXXXX")

  node - "$run_id" "$started_at" "$finished_at" "$duration" "$headline_pct" \
    "$total_features" "$completed_features" "$failed_features" \
    "$total_tokens" "$total_cost" "$enriched_features" "$tmp_file" <<'JSEOF' 2>/dev/null
const [,, run_id, started, finished, duration, headline, total, completed, failed, tokens, cost, features_json, tmp_file] = process.argv;
const fs = require('fs');

const report = {
  run_id,
  started_at: started,
  finished_at: finished,
  duration_seconds: parseInt(duration, 10),
  headline_pct: parseInt(headline, 10),
  total_features: parseInt(total, 10),
  completed_features: parseInt(completed, 10),
  failed_features: parseInt(failed, 10),
  total_tokens: parseInt(tokens, 10),
  total_cost_usd: parseFloat(cost),
  features: JSON.parse(features_json)
};

fs.writeFileSync(tmp_file, JSON.stringify(report, null, 2));
JSEOF

  mv "$tmp_file" "$report_path"
  info "Report: generated $report_path"
}
