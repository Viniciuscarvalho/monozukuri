#!/bin/bash
# lib/run/dep-check.sh — Explicit dependency validation for backlog ingestion (ADR-015, Gap 7)
#
# Validates all depends_on references in a backlog file against the full feature list.
# A bad reference fails loud with file:line rather than silently corrupting topo-sort.
#
# Public functions:
#   dep_check_explicit <backlog_file>  — validate all depends_on refs; exit 1 on error

# dep_check_explicit <backlog_file>
# Validates all depends_on references in the backlog.
# Returns 0 if all valid, 1 if any invalid (errors written to stderr).
dep_check_explicit() {
  local backlog_file="$1"

  if [ ! -f "$backlog_file" ]; then
    echo "error: backlog file not found: $backlog_file" >&2
    return 1
  fi

  # Extract all feature IDs from the backlog (both markdown and JSON formats)
  # Markdown: ## [PRIORITY] feat-NNN: Title
  # JSON: "id": "feat-NNN"
  local all_features
  all_features=$(grep -oE '(^##[[:space:]]*\[[^]]+\][[:space:]]*|"id":[[:space:]]*")feat-[0-9]+' "$backlog_file" | \
    grep -oE 'feat-[0-9]+' | sort -u)

  if [ -z "$all_features" ]; then
    echo "warning: no features found in $backlog_file" >&2
    return 0
  fi

  local feature_count
  feature_count=$(echo "$all_features" | wc -l | tr -d ' ')

  # Track errors and current feature context
  local error_count=0
  local line_num=0
  local current_feat=""

  # Read file line by line to get line numbers
  while IFS= read -r line || [ -n "$line" ]; do
    line_num=$((line_num + 1))

    # Track current feature from headers (## [PRIORITY] feat-NNN or "id": "feat-NNN")
    if echo "$line" | grep -qE '^##[[:space:]]*\[[^]]+\][[:space:]]*feat-[0-9]+'; then
      current_feat=$(echo "$line" | grep -oE 'feat-[0-9]+' | head -1)
    elif echo "$line" | grep -qE '"id":[[:space:]]*"feat-[0-9]+"'; then
      current_feat=$(echo "$line" | grep -oE 'feat-[0-9]+' | head -1)
    fi

    # Check for depends_on in this line (handles both formats)
    # Markdown: **depends_on:** feat-001, feat-002
    # JSON: "depends_on": ["feat-001", "feat-002"]
    if echo "$line" | grep -qE '(depends_on:|"depends_on")'; then
      # Extract feature IDs from depends_on
      local deps
      deps=$(echo "$line" | grep -oE 'feat-[0-9]+' || true)

      if [ -n "$deps" ]; then
        # Validate each dependency
        while IFS= read -r dep_id; do
          [ -z "$dep_id" ] && continue

          # Check for self-reference
          if [ -n "$current_feat" ] && [ "$dep_id" = "$current_feat" ]; then
            echo "error: $backlog_file:$line_num: feature $dep_id cannot depend on itself" >&2
            error_count=$((error_count + 1))
            continue
          fi

          # Check if dependency exists in feature list
          if ! echo "$all_features" | grep -qx "$dep_id"; then
            echo "error: $backlog_file:$line_num: depends_on references unknown feature \"$dep_id\"" >&2
            echo "       known features: $(echo "$all_features" | tr '\n' ',' | sed 's/,$//' | sed 's/,/, /g')" >&2
            error_count=$((error_count + 1))
          fi
        done <<< "$deps"
      fi
    fi
  done < "$backlog_file"

  if [ $error_count -gt 0 ]; then
    echo "error: dependency validation failed with $error_count error(s) — fix backlog and re-run" >&2
    return 1
  fi

  return 0
}
