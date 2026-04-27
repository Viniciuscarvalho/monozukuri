#!/bin/bash
# lib/memory/metrics.sh — Metrics calculation and storage for canary runs (Gap 5)
#
# Public API:
#   metrics_display <history_file>  — Display last 4 weeks of canary data
#   metrics_append <history_file> <run_id> <headline_%> <tokens_avg> <completion_%> <stack_json>
#
# Private functions:
#   _metrics_validate_schema <history_file>
#   _metrics_extract_recent <history_file> <n>
#   _metrics_parse_row <row>
#   _metrics_calculate_trailing_average <rows>
#   _metrics_format_row <row>

set -euo pipefail

# ── Schema Validation ─────────────────────────────────────────────────────────

# Validate canary-history.md schema
# Returns: 0 if valid, 2 if invalid
_metrics_validate_schema() {
  local history_file="$1"

  [ ! -f "$history_file" ] && return 0

  local line_num=0
  local data_started=false

  while IFS= read -r line; do
    line_num=$((line_num + 1))
    [[ -z "$line" || "$line" =~ ^[[:space:]]*$ ]] && continue
    [[ "$line" =~ ^# ]] && continue

    if [[ "$line" =~ date.*run_id.*headline ]]; then
      data_started=true
      continue
    fi

    [[ "$line" =~ ^[[:space:]]*[\|]*[[:space:]]*-+[[:space:]]*\| ]] && continue
    [ "$data_started" = false ] && continue

    line=$(echo "$line" | sed -e 's/^[[:space:]]*|[[:space:]]*//' -e 's/[[:space:]]*|[[:space:]]*$//')

    local col_count
    col_count=$(echo "$line" | grep -o '|' | wc -l | tr -d ' ')

    if [ "$col_count" -ne 5 ]; then
      echo "Invalid schema at line $line_num: expected 6 columns (5 pipes), found $col_count pipes" >&2
      return 2
    fi

    local date_field
    date_field=$(echo "$line" | cut -d'|' -f1 | xargs)

    if ! [[ "$date_field" =~ ^[0-9]{4}-[0-9]{2}-[0-9]{2}$ ]]; then
      echo "invalid date format at line $line_num: expected YYYY-MM-DD, got '$date_field'" >&2
      return 2
    fi
  done < "$history_file"

  return 0
}

# ── Row Parsing and Extraction ───────────────────────────────────────────────

# Extract last N data rows from history file
# Usage: _metrics_extract_recent <history_file> <n>
_metrics_extract_recent() {
  local history_file="$1"
  local n="$2"

  [ ! -f "$history_file" ] && return 0

  local data_started=false
  local -a rows=()

  while IFS= read -r line; do
    [[ -z "$line" || "$line" =~ ^[[:space:]]*$ ]] && continue
    [[ "$line" =~ ^# ]] && continue

    if [[ "$line" =~ date.*run_id.*headline ]]; then
      data_started=true
      continue
    fi

    [[ "$line" =~ ^[[:space:]]*[\|]*[[:space:]]*-+[[:space:]]*\| ]] && continue
    [ "$data_started" = false ] && continue

    line=$(echo "$line" | sed -e 's/^[[:space:]]*|[[:space:]]*//' -e 's/[[:space:]]*|[[:space:]]*$//')
    rows+=("$line")
  done < "$history_file"

  local total=${#rows[@]}
  local start=$((total > n ? total - n : 0))

  local i=$start
  while [ "$i" -lt "$total" ]; do
    echo "${rows[$i]}"
    i=$((i + 1))
  done
}

# Parse a pipe-delimited row into variables
# Usage: _metrics_parse_row <row>
# Sets: row_date, row_run_id, row_headline, row_tokens, row_completion, row_stack_json
_metrics_parse_row() {
  local row="$1"

  row_date=$(echo "$row" | cut -d'|' -f1 | xargs)
  row_run_id=$(echo "$row" | cut -d'|' -f2 | xargs)
  row_headline=$(echo "$row" | cut -d'|' -f3 | xargs)
  row_tokens=$(echo "$row" | cut -d'|' -f4 | xargs)
  row_completion=$(echo "$row" | cut -d'|' -f5 | xargs)
  row_stack_json=$(echo "$row" | cut -d'|' -f6 | xargs)
}

# ── Trailing Average Calculation ─────────────────────────────────────────────

# Calculate trailing average of headline_% from rows
# Usage: _metrics_calculate_trailing_average <rows>
_metrics_calculate_trailing_average() {
  local rows="$1"

  [ -z "$rows" ] && echo "0.0" && return

  local sum=0
  local count=0

  while IFS= read -r row; do
    local headline
    headline=$(echo "$row" | cut -d'|' -f3 | xargs)

    # Skip non-numeric values
    if [[ "$headline" =~ ^[0-9]+(\.[0-9]+)?$ ]]; then
      sum=$(awk -v s="$sum" -v h="$headline" 'BEGIN {printf "%.2f", s + h}')
      count=$((count + 1))
    fi
  done <<< "$rows"

  if [ "$count" -eq 0 ]; then
    echo "0.0"
  else
    awk -v s="$sum" -v c="$count" 'BEGIN {printf "%.1f", s / c}'
  fi
}

# ── Display Formatting ────────────────────────────────────────────────────────

# Format a row for display
# Usage: _metrics_format_row <row>
_metrics_format_row() {
  local row="$1"

  _metrics_parse_row "$row"

  printf '%-12s | %-18s | %10s | %12s | %12s\n' \
    "$row_date" "$row_run_id" "$row_headline" "$row_tokens" "$row_completion"
}

# ── Public API ────────────────────────────────────────────────────────────────

# Display last 4 weeks of canary data and trailing average
# Usage: metrics_display <history_file>
metrics_display() {
  local history_file="$1"

  # Validate schema first
  if ! _metrics_validate_schema "$history_file"; then
    return 2
  fi

  # Extract last 4 weeks (or fewer)
  local rows
  rows=$(_metrics_extract_recent "$history_file" 4)

  if [ -z "$rows" ]; then
    echo ""
    echo "No canary runs recorded yet."
    echo ""
    return 0
  fi

  # Display table header
  echo ""
  printf '%-12s | %-18s | %-10s | %-12s | %-12s\n' \
    "Date" "Run ID" "Headline %" "Tokens Avg" "Completion %"
  printf '%s\n' "-------------|--------------------|-----------|--------------|--------------"

  # Display rows
  while IFS= read -r row; do
    _metrics_format_row "$row"
  done <<< "$rows"

  # Calculate and display trailing average
  local avg
  avg=$(_metrics_calculate_trailing_average "$rows")
  printf '\n4-week trailing average: %s%%\n\n' "$avg"
}

# Append new canary run results to history file
# Usage: metrics_append <history_file> <run_id> <headline_%> <tokens_avg> <completion_%> <stack_json>
metrics_append() {
  local history_file="$1"
  local run_id="$2"
  local headline="$3"
  local tokens="$4"
  local completion="$5"
  local stack_json="$6"

  # Generate current date
  local date
  date=$(date -u +%Y-%m-%d)

  # Ensure file exists with header
  if [ ! -f "$history_file" ]; then
    local dir
    dir=$(dirname "$history_file")
    mkdir -p "$dir"

    cat > "$history_file" <<'EOF'
# Canary Run History

This file records the results of weekly canary benchmark runs. Each row represents one run against the fixed benchmark suite.

## Schema

| Column | Type | Description |
|--------|------|-------------|
| date | YYYY-MM-DD | Date of canary run |
| run_id | string | Unique identifier (e.g., run-20260426-123456) |
| headline_% | number | CI-pass-rate-on-first-PR (0-100) |
| tokens_avg | number | Average tokens per feature |
| completion_% | number | Feature completion rate (0-100) |
| stack_breakdown_json | JSON | Per-stack metrics as JSON object |

## History

date | run_id | headline_% | tokens_avg | completion_% | stack_breakdown_json
-----|--------|------------|------------|--------------|---------------------
EOF
  fi

  # Append row
  printf '%s | %s | %s | %s | %s | %s\n' \
    "$date" "$run_id" "$headline" "$tokens" "$completion" "$stack_json" \
    >> "$history_file"
}
