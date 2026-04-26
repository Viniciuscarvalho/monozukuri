#!/bin/bash
# lib/run/calibrate.sh — Calibration command implementation (Gap 8)
#
# Reads last N cost.json files and canary-history.md, computes actual-vs-estimated
# ratios per (agent, model, phase), and updates config/pricing.yaml.
#
# Public API:
#   calibrate_run <sample_size>  — Execute calibration and update pricing.yaml

set -euo pipefail

# Helper functions (if not already defined)
warn() { echo "⚠ [calibrate] $*" >&2; }
info() { echo "  [calibrate] $*"; }
log() { echo "▶ [calibrate] $*"; }
err() { echo "✗ [calibrate] $*" >&2; }

# ── calibrate_run ─────────────────────────────────────────────────────
# Main calibration logic
# Usage: calibrate_run <sample_size>

calibrate_run() {
  local sample_size="${1:-20}"

  log "Calibration analysis (last $sample_size features)"

  # Load pricing module
  if ! command -v pricing_load &>/dev/null; then
    err "Pricing module not available — cannot run calibration"
    return 1
  fi

  pricing_load

  # Find pricing.yaml location
  local pricing_file=""
  if [ -f "$PROJECT_ROOT/config/pricing.yaml" ]; then
    pricing_file="$PROJECT_ROOT/config/pricing.yaml"
  elif [ -f "$SCRIPT_DIR/config/pricing.yaml" ]; then
    pricing_file="$SCRIPT_DIR/config/pricing.yaml"
  else
    err "pricing.yaml not found — cannot update calibration"
    return 1
  fi

  # Check yq availability
  if ! command -v yq &>/dev/null; then
    err "yq not installed — cannot update pricing.yaml"
    return 1
  fi

  # Find last N cost.json files (sorted by modification time)
  local -a cost_files=()
  while IFS= read -r file; do
    cost_files+=("$file")
  done < <(find "$STATE_DIR" -name "cost.json" -type f 2>/dev/null | xargs ls -t 2>/dev/null | head -n "$sample_size")

  local feature_count=${#cost_files[@]}
  if [ "$feature_count" -lt 5 ]; then
    warn "Insufficient data for calibration (found $feature_count features, need 5+)"
    info "Run more features before calibrating"
    return 0
  fi

  info "Analyzing $feature_count features..."

  # Aggregate actual-vs-estimated ratios per (agent, model, phase)
  local aggregated
  aggregated=$(node -e "
    const fs = require('fs');
    const costFiles = process.argv.slice(1);
    const data = {};

    for (const file of costFiles) {
      try {
        const cost = JSON.parse(fs.readFileSync(file, 'utf-8'));

        // Default to claude-code / claude-sonnet-4-6 (read from feature metadata when available)
        const agent = 'claude-code';
        const model = 'claude-sonnet-4-6';

        for (const phaseData of cost.phases || []) {
          const phase = phaseData.phase;
          const estimated = phaseData.estimated_tokens || 0;
          const actual = phaseData.actual_tokens || null;

          if (actual === null) continue;

          const key = \`\${agent}::\${model}::\${phase}\`;

          if (!data[key]) {
            data[key] = { sum_ratio: 0, count: 0, sum_est: 0, sum_act: 0 };
          }

          const ratio = estimated > 0 ? actual / estimated : 1.0;
          data[key].sum_ratio += ratio;
          data[key].sum_est += estimated;
          data[key].sum_act += actual;
          data[key].count += 1;
        }
      } catch (err) {
        // Skip invalid files
      }
    }

    console.log(JSON.stringify(data, null, 2));
  " "${cost_files[@]}" 2>/dev/null)

  # Check if we have any data
  if [ -z "$aggregated" ] || [ "$aggregated" = "{}" ]; then
    warn "No actual token data found in cost.json files"
    info "Features need to record actual_tokens to enable calibration"
    return 0
  fi

  # Display calibration report
  echo ""
  echo "Calibration Report (last $feature_count features):"
  echo "═══════════════════════════════════════════════════════════════"
  echo ""

  node -e "
    const data = JSON.parse(process.argv[1]);

    console.log('Agent: claude-code / Model: claude-sonnet-4-6');
    console.log('');
    console.log('Phase      Est tokens   Act tokens   Ratio   Guidance');
    console.log('─────────────────────────────────────────────────────────');

    const phases = ['prd', 'techspec', 'tasks', 'code', 'tests', 'pr'];
    let totalEst = 0;
    let totalAct = 0;

    for (const phase of phases) {
      const key = \`claude-code::claude-sonnet-4-6::\${phase}\`;
      const entry = data[key];

      if (!entry || entry.count === 0) {
        console.log(phase.padEnd(10) + ' ' + '—'.padStart(12) + ' ' + '—'.padStart(12) + ' ' + '—'.padStart(7) + ' —');
        continue;
      }

      const avgEst = Math.round(entry.sum_est / entry.count);
      const avgAct = Math.round(entry.sum_act / entry.count);
      const avgRatio = entry.sum_ratio / entry.count;

      totalEst += avgEst;
      totalAct += avgAct;

      let guidance = '✓ baseline accurate';
      if (avgRatio < 0.9) guidance = '↓ reduce baseline';
      else if (avgRatio > 1.1) guidance = '↑ raise baseline';

      console.log(phase.padEnd(10) + ' ' + avgEst.toLocaleString().padStart(12) + ' ' + avgAct.toLocaleString().padStart(12) + ' ' + avgRatio.toFixed(2).padStart(7) + ' ' + guidance);
    }

    console.log('');
    const avgUsdPerFeature = (totalAct / 1000000 * 3.0 * 0.7) + (totalAct / 1000000 * 15.0 * 0.3);
    console.log('Avg tokens/feature: ' + totalAct.toLocaleString() + ' (budget: varies)');
    console.log('Estimated avg USD/feature: \$' + avgUsdPerFeature.toFixed(2));
    console.log('');
  " "$aggregated" 2>/dev/null

  # Apply calibration updates via yq
  info "Updating calibration coefficients in pricing.yaml..."

  while read -r agent model phase coeff; do
    [ -z "$agent" ] && continue
    yq eval -i ".calibration.\"$agent\".\"$model\".\"$phase\" = $coeff" "$pricing_file" 2>/dev/null || {
      warn "Failed to update $agent / $model / $phase"
    }
  done < <(node -e "
    const data = JSON.parse(process.argv[1]);
    for (const [key, entry] of Object.entries(data)) {
      if (entry.count === 0) continue;
      const [agent, model, phase] = key.split('::');
      const avgRatio = entry.sum_ratio / entry.count;
      console.log(\`\${agent} \${model} \${phase} \${avgRatio.toFixed(2)}\`);
    }
  " "$aggregated" 2>/dev/null)

  # Update timestamp
  local now
  now=$(date -u +%Y-%m-%d)
  yq eval -i ".updated_at = \"$now\"" "$pricing_file" 2>/dev/null

  echo "✓ Updated calibration coefficients written to config/pricing.yaml"
  echo ""
}
