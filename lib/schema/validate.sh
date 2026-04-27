#!/bin/bash
# lib/schema/validate.sh — Phase artifact schema validation (ADR-012)
#
# Validates that agent-generated Markdown artifacts have the required structure.
# JSON Schema files in schemas/ define the canonical contract for the target
# JSON artifact format (Gap 3). This module enforces structural Markdown
# requirements for the current format using grep/awk — no external deps.
#
# One-reprompt rule: symmetric with CI reprompt (ADR-014) and phase reprompt
# (ADR-013). Every reprompt trigger in the box allows exactly one reprompt.
#
# Exit codes (schema_validate):
#   0  artifact is structurally valid
#   1  artifact is invalid; SCHEMA_VALIDATE_ERROR describes the failure
#
# Public interface:
#   schema_validate <artifact_type> <artifact_file>
#   schema_humanize_error <artifact_type> <error_msg>
#   schema_validate_with_reprompt <feat_id> <wt_path> <task_dir>

SCHEMA_VALIDATE_ERROR=""

schema_validate() {
  local artifact_type="$1"
  local artifact_file="$2"
  SCHEMA_VALIDATE_ERROR=""

  # commit-summary is forward-looking (Gap 3 enforces it via ajv); skip all checks
  [ "$artifact_type" = "commit-summary" ] && return 0

  if [ ! -f "$artifact_file" ]; then
    SCHEMA_VALIDATE_ERROR="${artifact_type}: file not found: $artifact_file"
    return 1
  fi

  local size
  size=$(wc -c <"$artifact_file" 2>/dev/null || echo "0")
  if [ "$size" -lt 50 ]; then
    SCHEMA_VALIDATE_ERROR="${artifact_type}: artifact too short (${size} bytes); minimum 50 bytes"
    return 1
  fi

  case "$artifact_type" in
    prd) _schema_validate_prd "$artifact_file" ;;
    techspec) _schema_validate_techspec "$artifact_file" ;;
    tasks) _schema_validate_tasks "$artifact_file" ;;
    *)
      SCHEMA_VALIDATE_ERROR="unknown artifact type: $artifact_type"
      return 1
      ;;
  esac
}

_schema_validate_prd() {
  local file="$1"
  if ! grep -qiE "^#{2,3}[[:space:]]+(problem|overview|summary|background)" "$file"; then
    SCHEMA_VALIDATE_ERROR="prd.md: missing a problem/overview section heading (e.g. '## Problem Statement')"
    return 1
  fi
  if ! grep -qiE "^#{2,3}[[:space:]]+(success|acceptance|definition|criteria|goal)" "$file"; then
    SCHEMA_VALIDATE_ERROR="prd.md: missing a success criteria or acceptance criteria section heading"
    return 1
  fi
  return 0
}

_schema_validate_techspec() {
  local file="$1"
  if ! grep -qiE "^#{2,3}[[:space:]]+(technical|implementation|approach|architecture|design|solution)" "$file"; then
    SCHEMA_VALIDATE_ERROR="techspec.md: missing a technical approach section heading (e.g. '## Technical Approach')"
    return 1
  fi
  if ! grep -qiE "^#{2,3} [Ff]iles.*(likely|touched)|^files_likely_touched:" "$file"; then
    SCHEMA_VALIDATE_ERROR="techspec.md: missing 'files_likely_touched' section listing files the implementation will touch"
    return 1
  fi
  local has_entry
  has_entry=$(awk 'BEGIN{f=0}
    /[Ff]iles/ && (/likely/ || /touched/ || /Likely/ || /Touched/) { f=1; next }
    /^files_likely_touched:/ { f=1; next }
    f && /^[[:space:]]*-/ { print "yes"; exit }
    f && /^#/ { exit }
  ' "$file")
  if [ "$has_entry" != "yes" ]; then
    SCHEMA_VALIDATE_ERROR="techspec.md: files_likely_touched must list at least one file (e.g. '- src/lib/foo.sh')"
    return 1
  fi
  return 0
}

_schema_validate_tasks() {
  local file="$1"
  if ! grep -qE "^[[:space:]]*-[[:space:]]\[[ xX]\]" "$file"; then
    SCHEMA_VALIDATE_ERROR="tasks.md: must contain at least one task checkbox (e.g. '- [ ] implement feature')"
    return 1
  fi
  return 0
}

schema_humanize_error() {
  local artifact_type="$1"
  local error_msg="$2"
  printf 'The %s artifact failed structural validation and must be regenerated.\n\nValidation error: %s\n\nPlease rewrite the %s as a complete, well-structured Markdown document with all required sections filled in. Do not truncate or omit any section.\n' \
    "$artifact_type" "$error_msg" "$artifact_type"
}

# schema_validate_with_reprompt <feat_id> <wt_path> <task_dir>
# Validates prd.md, techspec.md, tasks.md in order. On the first failure,
# reprompts the agent up to MONOZUKURI_SCHEMA_MAX_REPROMPTS times (default 1,
# ADR-012 §3). Returns:
#   0 — all artifacts valid
#   1 — still invalid; caller should transition the feature to error state
#   2 — still invalid but MONOZUKURI_SCHEMA_ESCALATE_TO_HUMAN=true fired;
#       feature is already paused — caller must NOT overwrite with error state
schema_validate_with_reprompt() {
  local feat_id="$1"
  local wt_path="$2"
  local task_dir="$3"

  local max_reprompts="${MONOZUKURI_SCHEMA_MAX_REPROMPTS:-1}"

  local model_flag=""
  local _fix_model="${MODEL_DEFAULT:-}"
  [ "$_fix_model" = "opusplan" ] && _fix_model="opus"
  [ -n "$_fix_model" ] && model_flag="--model $_fix_model"

  local fix_perm_flag=""
  [ "${AUTONOMY:-}" = "full_auto" ] && fix_perm_flag="--permission-mode bypassPermissions"

  local artifact_type artifact_file
  for artifact_type in prd techspec tasks; do
    case "$artifact_type" in
      prd) artifact_file="$task_dir/prd.md" ;;
      techspec) artifact_file="$task_dir/techspec.md" ;;
      tasks) artifact_file="$task_dir/tasks.md" ;;
    esac

    if schema_validate "$artifact_type" "$artifact_file"; then
      continue
    fi

    local error_msg="$SCHEMA_VALIDATE_ERROR"
    warn "Schema validation failed ($feat_id/$artifact_type): $error_msg"

    local attempt=0 validated=false
    while [ "$attempt" -lt "$max_reprompts" ]; do
      attempt=$((attempt + 1))
      info "Schema: reprompting agent for $feat_id/$artifact_type (attempt $attempt/$max_reprompts, ADR-012)..."
      local fix_prompt
      fix_prompt=$(schema_humanize_error "$artifact_type" "$error_msg")
      (cd "$wt_path" && printf '%b' "$fix_prompt" |
        platform_claude "${SKILL_TIMEOUT_SECONDS:-1800}" $model_flag $fix_perm_flag --print) \
        2>/dev/null || true

      if schema_validate "$artifact_type" "$artifact_file"; then
        info "Schema: $artifact_type valid after reprompt (attempt $attempt)"
        validated=true
        break
      fi
      error_msg="$SCHEMA_VALIDATE_ERROR"
      warn "Schema: $artifact_type still invalid after reprompt $attempt — $error_msg"
    done

    if [ "$validated" = "false" ]; then
      if [ "${MONOZUKURI_SCHEMA_ESCALATE_TO_HUMAN:-false}" = "true" ]; then
        if declare -f fstate_transition &>/dev/null && declare -f fstate_record_pause &>/dev/null; then
          fstate_transition "$feat_id" "paused" "schema-needs-review"
          fstate_record_pause "$feat_id" "human" "schema-needs-review"
          info "Schema: escalating $feat_id to human review after $max_reprompts reprompt(s)"
        fi
        return 2
      fi
      return 1
    fi
  done

  return 0
}
