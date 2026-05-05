#!/bin/bash
# lib/ops/budget.sh — Global daily USD cost ceiling for multi-project runs.
#
# Budget file: ~/.monozukuri/budget.json
# Shape:
#   {
#     "daily_ceiling_usd": 50,
#     "current_spend_usd": 0.0,
#     "reset_at": "<ISO8601 local midnight>"
#   }
#
# Public API:
#   budget_init                — ensure file exists; auto-reset past midnight
#   budget_check [est_usd]     — exit 0 if ok; exit 1 if ceiling exceeded
#   budget_record <cost_usd>   — atomically add cost_usd to current_spend_usd
#   budget_status              — print current spend / ceiling
#
# Env overrides (take precedence over budget.json):
#   MONOZUKURI_DAILY_CEILING_USD   (default: 50)

_BUDGET_FILE="${_BUDGET_FILE:-${HOME}/.monozukuri/budget.json}"
_BUDGET_LOCK="${_BUDGET_LOCK:-${HOME}/.monozukuri/budget.lock}"

_budget_acquire_lock() {
  local attempts=0
  while ! mkdir "$_BUDGET_LOCK" 2>/dev/null; do
    attempts=$((attempts + 1))
    if [ "$attempts" -ge 100 ]; then
      rmdir "$_BUDGET_LOCK" 2>/dev/null || true
      mkdir "$_BUDGET_LOCK" 2>/dev/null || true
      break
    fi
    sleep 0.1
  done
}

_budget_release_lock() {
  rmdir "$_BUDGET_LOCK" 2>/dev/null || true
}

_budget_midnight_iso() {
  # Prints the ISO8601 timestamp for tonight's local midnight.
  # Uses date arithmetic available on both macOS (BSD) and Linux (GNU).
  if date --date="tomorrow 00:00:00" +%Y-%m-%dT%H:%M:%S 2>/dev/null | grep -q T; then
    date --date="tomorrow 00:00:00" +%Y-%m-%dT%H:%M:%S
  else
    # macOS / BSD date
    date -v+1d -v0H -v0M -v0S +%Y-%m-%dT%H:%M:%S
  fi
}

budget_init() {
  mkdir -p "$(dirname "$_BUDGET_FILE")"
  local ceiling="${MONOZUKURI_DAILY_CEILING_USD:-50}"

  if [ ! -f "$_BUDGET_FILE" ]; then
    local reset_at
    reset_at=$(_budget_midnight_iso)
    node -e "
      const fs = require('fs');
      fs.writeFileSync('$_BUDGET_FILE', JSON.stringify({
        daily_ceiling_usd: $ceiling,
        current_spend_usd: 0.0,
        reset_at: '$reset_at'
      }, null, 2));
    " 2>/dev/null || true
    return 0
  fi

  # Auto-reset if past reset_at
  local needs_reset
  needs_reset=$(node -p "
    try {
      const d = JSON.parse(require('fs').readFileSync('$_BUDGET_FILE','utf-8'));
      new Date(d.reset_at) <= new Date() ? 'yes' : 'no';
    } catch(e) { 'yes'; }
  " 2>/dev/null || echo "yes")

  if [ "$needs_reset" = "yes" ]; then
    _budget_acquire_lock
    local reset_at
    reset_at=$(_budget_midnight_iso)
    node -e "
      const fs = require('fs');
      let d;
      try { d = JSON.parse(fs.readFileSync('$_BUDGET_FILE','utf-8')); } catch(e) { d = {}; }
      d.current_spend_usd = 0.0;
      d.daily_ceiling_usd = d.daily_ceiling_usd || $ceiling;
      d.reset_at = '$reset_at';
      fs.writeFileSync('$_BUDGET_FILE', JSON.stringify(d, null, 2));
    " 2>/dev/null || true
    _budget_release_lock
  fi
}

# budget_check [estimated_feature_cost_usd]
# Returns 0 (ok) or 1 (ceiling exceeded).
# When codex/gemini report 0.00 cost, est_usd defaults to 0 — check still
# catches the case where claude-code runs already pushed spend past ceiling.
budget_check() {
  local est_usd="${1:-0}"
  [ ! -f "$_BUDGET_FILE" ] && return 1  # fail-open: no file = no ceiling exceeded

  local env_ceiling="${MONOZUKURI_DAILY_CEILING_USD:-}"
  local result
  result=$(node -p "
    try {
      const d = JSON.parse(require('fs').readFileSync('$_BUDGET_FILE','utf-8'));
      const envCeil = '$env_ceiling';
      const ceil = (envCeil && !isNaN(+envCeil)) ? +envCeil : (d.daily_ceiling_usd || 50);
      const spend = (d.current_spend_usd || 0) + ($est_usd || 0);
      spend >= ceil ? 'exceeded' : 'ok';
    } catch(e) { 'ok'; }
  " 2>/dev/null || echo "ok")

  [ "$result" = "exceeded" ]
}

# budget_record <cost_usd>
# Atomically adds cost_usd to current_spend_usd. No-op when cost is 0 or
# non-numeric (e.g., codex/gemini return "0.00" — still written for accuracy).
budget_record() {
  local cost_usd="${1:-0}"
  [ ! -f "$_BUDGET_FILE" ] && return 0

  _budget_acquire_lock
  node -e "
    const fs = require('fs');
    const tmp = '$_BUDGET_FILE.tmp.' + process.pid;
    try {
      const d = JSON.parse(fs.readFileSync('$_BUDGET_FILE','utf-8'));
      d.current_spend_usd = Math.round(((d.current_spend_usd || 0) + ($cost_usd || 0)) * 10000) / 10000;
      fs.writeFileSync(tmp, JSON.stringify(d, null, 2));
      fs.renameSync(tmp, '$_BUDGET_FILE');
    } catch(e) { try { fs.unlinkSync(tmp); } catch(_) {} }
  " 2>/dev/null || true
  _budget_release_lock
}

budget_status() {
  [ ! -f "$_BUDGET_FILE" ] && printf 'Budget: not initialised\n' && return
  node -e "
    const d = JSON.parse(require('fs').readFileSync('$_BUDGET_FILE','utf-8'));
    const ceil = d.daily_ceiling_usd || 50;
    const spend = (d.current_spend_usd || 0).toFixed(2);
    const pct = Math.round((d.current_spend_usd || 0) / ceil * 100);
    console.log('Budget: \$' + spend + ' / \$' + ceil + ' (' + pct + '%)  resets: ' + d.reset_at);
  " 2>/dev/null || true
}
