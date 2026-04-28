#!/bin/bash
# .qa/lib/report.sh — JSON report builder for the release gate

_GATE_REPORT_FILE=""
_GATE_REPORT_LAYERS=""   # newline-separated JSON objects; joined at write time
_GATE_REPORT_FAILURE="null"
_GATE_REPORT_TOTAL_COST="0"
_GATE_STARTED_AT=""
_GATE_VERSION=""

report_init() {
  local version="$1" report_dir="$2"
  local date_slug
  date_slug=$(date -u +%Y%m%d)
  _GATE_REPORT_FILE="${report_dir}/${date_slug}-release-gate.json"
  mkdir -p "$report_dir"
  _GATE_REPORT_LAYERS=""
  _GATE_REPORT_FAILURE="null"
  _GATE_REPORT_TOTAL_COST="0"
  _GATE_STARTED_AT=$(date -u +%Y-%m-%dT%H:%M:%SZ)
  _GATE_VERSION="$version"
}

report_layer() {
  local id="$1" name="$2" status="$3" duration_s="$4" cost_usd="${5:-0}" skipped="${6:-false}"
  local skipped_bool="false"
  [ "$skipped" = "true" ] && skipped_bool="true"
  local entry
  entry=$(python3 -c "
import json
print(json.dumps({
  'id': $id,
  'name': '$name',
  'status': '$status',
  'duration_s': $duration_s,
  'cost_usd': $cost_usd,
  'skipped': '$skipped_bool' == 'true'
}))
")
  if [ -z "$_GATE_REPORT_LAYERS" ]; then
    _GATE_REPORT_LAYERS="$entry"
  else
    _GATE_REPORT_LAYERS="${_GATE_REPORT_LAYERS}
${entry}"
  fi
}

report_failure() {
  local layer="$1" assertion="$2" detail="${3:-}"
  _GATE_REPORT_FAILURE=$(python3 -c "
import json
print(json.dumps({'layer': $layer, 'assertion': '$assertion', 'detail': '$detail'}))
")
}

report_write() {
  local verdict="$1" total_s="$2"
  local finished_at
  finished_at=$(date -u +%Y-%m-%dT%H:%M:%SZ)

  # Build layers array from newline-separated JSON objects
  local layers_array
  layers_array=$(python3 -c "
import json, sys
lines = sys.stdin.read().strip().splitlines()
objs = [json.loads(l) for l in lines if l.strip()]
print(json.dumps(objs))
" <<< "$_GATE_REPORT_LAYERS")

  python3 -c "
import json
report = {
  'version': '$_GATE_VERSION',
  'verdict': '$verdict',
  'started_at': '$_GATE_STARTED_AT',
  'finished_at': '$finished_at',
  'total_seconds': $total_s,
  'total_cost_usd': $_GATE_REPORT_TOTAL_COST,
  'layers': json.loads('$layers_array'),
  'first_failure': json.loads('$_GATE_REPORT_FAILURE')
}
print(json.dumps(report, indent=2))
" > "$_GATE_REPORT_FILE"
  echo "$_GATE_REPORT_FILE"
}
