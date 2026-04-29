#!/bin/bash
# lib/schema/validate.sh — Phase artifact schema validation (ADR-012)
#
# Validates agent-generated artifacts against structural rules. Heading
# alias patterns are read from skills/mz-*/references/*-validation.md (PR2);
# tasks.json is validated against its required JSON schema fields.
#
# One-reprompt rule: symmetric with CI reprompt (ADR-014) and phase reprompt
# (ADR-013). Every reprompt trigger allows exactly one reprompt.
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

# Locate the skills/ directory relative to MONOZUKURI_HOME or this script.
_validation_skills_dir() {
  local home="${MONOZUKURI_HOME:-}"
  if [ -n "$home" ] && [ -d "$home/skills" ]; then
    echo "$home/skills"
    return
  fi
  local script_dir
  script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" 2>/dev/null && pwd)"
  echo "${script_dir}/../../skills"
}

# _validation_aliases <vfile> <section_grep>
# Reads the alias table in a validation.md file and returns a pipe-separated
# ERE pattern (lowercased) for all aliases in the row matching <section_grep>.
# Returns empty string if the file is absent or the row is not found.
_validation_aliases() {
  local vfile="$1"
  local section_grep="$2"
  [ -f "$vfile" ] || return 0
  grep -i "^|.*${section_grep}" "$vfile" | head -1 | \
    awk -F'|' '{print $3}' | \
    sed 's/^ *//;s/ *$//;s/ *· */|/g' | \
    tr '[:upper:]' '[:lower:]' | \
    sed 's/ *(yaml key)//g;s/^|//;s/|$//'
}

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
  local vfile
  vfile="$(_validation_skills_dir)/mz-create-prd/references/prd-validation.md"

  local problem_pattern
  problem_pattern=$(_validation_aliases "$vfile" "Problem framing")
  [ -z "$problem_pattern" ] && problem_pattern="problem|overview|summary|background|motivation"

  local success_pattern
  success_pattern=$(_validation_aliases "$vfile" "Success criteria")
  [ -z "$success_pattern" ] && success_pattern="success|acceptance|definition|criteria|goal"

  if ! grep -qiE "^#{2,3}[[:space:]]+(${problem_pattern})" "$file"; then
    SCHEMA_VALIDATE_ERROR="prd.md: missing a problem/overview section heading (e.g. '## Problem Statement')"
    return 1
  fi
  if ! grep -qiE "^#{2,3}[[:space:]]+(${success_pattern})" "$file"; then
    SCHEMA_VALIDATE_ERROR="prd.md: missing a success criteria or acceptance criteria section heading"
    return 1
  fi
  return 0
}

_schema_validate_techspec() {
  local file="$1"
  local vfile
  vfile="$(_validation_skills_dir)/mz-create-techspec/references/techspec-validation.md"

  local approach_pattern
  approach_pattern=$(_validation_aliases "$vfile" "Technical approach")
  [ -z "$approach_pattern" ] && approach_pattern="technical|implementation|approach|architecture|design|solution"

  local files_pattern
  files_pattern=$(_validation_aliases "$vfile" "Files likely touched")
  [ -z "$files_pattern" ] && files_pattern="files likely touched|file change map|files touched|files to modify|file layout|files affected|implementation files"

  if ! grep -qiE "^#{2,3}[[:space:]]+(${approach_pattern})" "$file"; then
    SCHEMA_VALIDATE_ERROR="techspec.md: missing a technical approach section heading (e.g. '## Technical Approach')"
    return 1
  fi
  if ! grep -qiE "^#{2,3}[[:space:]]+(${files_pattern})|^files_likely_touched:" "$file"; then
    SCHEMA_VALIDATE_ERROR="techspec.md: missing 'files_likely_touched' section listing files the implementation will touch"
    return 1
  fi
  local has_entry
  has_entry=$(awk 'BEGIN{f=0}
    /^#{2,3}[[:space:]]/ {
      h = tolower($0)
      if (h ~ /files?.*(likely|touched|modify|change)/) { f=1; next }
      if (f) exit
    }
    /^files_likely_touched:/ { f=1; next }
    f && /^[[:space:]]*-/ { print "yes"; exit }
  ' "$file")
  if [ "$has_entry" != "yes" ]; then
    SCHEMA_VALIDATE_ERROR="techspec.md: files_likely_touched must list at least one file (e.g. '- src/lib/foo.sh')"
    return 1
  fi
  return 0
}

_schema_validate_tasks() {
  local file="$1"

  if command -v python3 &>/dev/null; then
    local py_result
    py_result=$(python3 - "$file" <<'PYEOF'
import json, sys
path = sys.argv[1]
try:
    with open(path) as f:
        data = json.load(f)
except json.JSONDecodeError as e:
    print("invalid JSON: {}".format(e))
    sys.exit(1)
if not isinstance(data, list) or len(data) == 0:
    print("must be a non-empty JSON array")
    sys.exit(1)
required = {"id", "title", "description", "files_touched", "acceptance_criteria"}
for i, task in enumerate(data):
    missing = required - set(task.keys())
    if missing:
        print("task {}: missing required field(s): {}".format(i + 1, ", ".join(sorted(missing))))
        sys.exit(1)
    if not isinstance(task["files_touched"], list) or len(task["files_touched"]) < 1:
        print("task {}: files_touched must be a non-empty array".format(i + 1))
        sys.exit(1)
    if not isinstance(task["acceptance_criteria"], list) or len(task["acceptance_criteria"]) < 1:
        print("task {}: acceptance_criteria must be a non-empty array".format(i + 1))
        sys.exit(1)
sys.exit(0)
PYEOF
    )
    if [ $? -ne 0 ]; then
      SCHEMA_VALIDATE_ERROR="tasks.json: ${py_result}"
      return 1
    fi
    return 0
  fi

  # Fallback when python3 is unavailable: structural grep on JSON keys
  if ! grep -qE '"id"[[:space:]]*:' "$file"; then
    SCHEMA_VALIDATE_ERROR="tasks.json: missing required field 'id' in task objects"
    return 1
  fi
  if ! grep -qE '"acceptance_criteria"[[:space:]]*:' "$file"; then
    SCHEMA_VALIDATE_ERROR="tasks.json: missing required field 'acceptance_criteria'"
    return 1
  fi
  return 0
}

schema_humanize_error() {
  local artifact_type="$1"
  local error_msg="$2"
  printf 'The %s artifact failed structural validation and must be regenerated.\n\nValidation error: %s\n\nPlease rewrite the %s as a complete, well-structured document with all required sections filled in. Do not truncate or omit any section.\n' \
    "$artifact_type" "$error_msg" "$artifact_type"
}

# schema_validate_with_reprompt <feat_id> <wt_path> <task_dir>
# Validates prd.md, techspec.md, tasks.json in order. On the first failure,
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
      tasks) artifact_file="$task_dir/tasks.json" ;;
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
      if declare -f learning_write &>/dev/null; then
        local learn_sig="${artifact_type}:${error_msg#*: }"
        learning_write "$feat_id" "schema-reprompt-exhausted: $learn_sig" \
          "Extend heading aliases in skills/mz-create-${artifact_type}/references/${artifact_type}-validation.md or ensure the artifact uses a recognized section heading"
      fi
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
