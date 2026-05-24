#!/bin/bash
# cmd/memory.sh — Memory v2 operator commands.
# Sourced by orchestrate.sh; inherits SCRIPT_DIR, ROOT_DIR, CONFIG_DIR.

_memory_lint_files_from_defaults() {
  local candidates=(
    "$CONFIG_DIR/memory-v2.json"
    "$CONFIG_DIR/memory-v2.jsonl"
    "$CONFIG_DIR/memory-v2.yaml"
    "$CONFIG_DIR/state/memory-v2.json"
    "$CONFIG_DIR/state/memory-v2.jsonl"
    "$CONFIG_DIR/state/memory-v2.yaml"
  )
  local file found=""
  for file in "${candidates[@]}"; do
    [ -f "$file" ] || continue
    if [ -n "$found" ]; then
      found="${found},$file"
    else
      found="$file"
    fi
  done
  printf '%s\n' "$found"
}

_memory_lint_file() {
  local file="$1"
  node - "$file" "$SCRIPT_DIR/schemas/learning-v2.schema.json" <<'JSEOF'
const [,, file, schemaFile] = process.argv;
const fs = require('fs');
const path = require('path');

const schema = JSON.parse(fs.readFileSync(schemaFile, 'utf8'));
const entrySchema = schema.definitions.learning;

function parseScalar(raw) {
  const value = String(raw || '').trim();
  if (value === 'null') return null;
  if (/^-?[0-9]+$/.test(value)) return Number(value);
  if (value.startsWith('[') && value.endsWith(']')) {
    const body = value.slice(1, -1).trim();
    if (!body) return [];
    return body.split(',').map((part) => parseScalar(part));
  }
  return value.replace(/^["']|["']$/g, '');
}

function parseYaml(content) {
  const root = {};
  let section = root;
  let pendingListKey = '';
  for (const rawLine of content.split(/\n/)) {
    const line = rawLine.replace(/\s+#.*$/, '');
    if (!line.trim()) continue;
    if (/^\s*-\s+/.test(line)) {
      if (!pendingListKey) throw new Error('unsupported yaml list item');
      root[pendingListKey].push(parseScalar(line.replace(/^\s*-\s+/, '')));
      continue;
    }
    const match = line.match(/^(\s*)([A-Za-z0-9_]+):(?:\s*(.*))?$/);
    if (!match) throw new Error(`unsupported yaml line: ${rawLine}`);
    const indent = match[1].length;
    const key = match[2];
    const rawValue = match[3] || '';
    if (indent === 0) section = root;
    if (rawValue === '') {
      if (key === 'tags') {
        root[key] = [];
        pendingListKey = key;
        continue;
      }
      section[key] = {};
      section = section[key];
      pendingListKey = '';
      continue;
    }
    section[key] = parseScalar(rawValue);
    pendingListKey = '';
  }
  return root;
}

function parseDocument(filePath) {
  const content = fs.readFileSync(filePath, 'utf8');
  if (filePath.endsWith('.jsonl')) {
    return content.split(/\n/).filter(Boolean).map((line) => JSON.parse(line));
  }
  if (filePath.endsWith('.yaml') || filePath.endsWith('.yml')) {
    return parseYaml(content);
  }
  return JSON.parse(content);
}

function isIsoDateTime(value) {
  return typeof value === 'string' && !Number.isNaN(Date.parse(value)) && /T/.test(value);
}

function validateEntry(entry, pathPrefix) {
  const errors = [];
  const required = entrySchema.required || [];
  for (const field of required) {
    if (entry[field] === undefined) errors.push(`${pathPrefix}.${field} is required`);
  }
  for (const field of Object.keys(entry || {})) {
    if (!entrySchema.properties[field]) errors.push(`${pathPrefix}.${field} is not allowed`);
  }
  if (typeof entry.id !== 'string' || !/^lrn-[0-9]{4}-[0-9]{2}-[0-9]{2}-[0-9]{3}$/.test(entry.id || '')) {
    errors.push(`${pathPrefix}.id must match lrn-YYYY-MM-DD-NNN`);
  }
  if (!['feature', 'project', 'global'].includes(entry.scope)) {
    errors.push(`${pathPrefix}.scope must be feature, project, or global`);
  }
  if (typeof entry.insight !== 'string' || entry.insight.length < 1 || entry.insight.length > 200) {
    errors.push(`${pathPrefix}.insight must be 1-200 characters`);
  }
  if (entry.rationale !== undefined && (typeof entry.rationale !== 'string' || entry.rationale.length > 1000)) {
    errors.push(`${pathPrefix}.rationale must be at most 1000 characters`);
  }
  if (!entry.source || typeof entry.source !== 'object' || Array.isArray(entry.source)) {
    errors.push(`${pathPrefix}.source must be an object`);
  } else {
    const sourceRequired = entrySchema.properties.source.required || [];
    const sourceProps = entrySchema.properties.source.properties;
    for (const field of sourceRequired) {
      if (entry.source[field] === undefined) errors.push(`${pathPrefix}.source.${field} is required`);
    }
    for (const field of Object.keys(entry.source)) {
      if (!sourceProps[field]) errors.push(`${pathPrefix}.source.${field} is not allowed`);
    }
    if (typeof entry.source.feature_id !== 'string' || entry.source.feature_id.length < 1) {
      errors.push(`${pathPrefix}.source.feature_id must be a non-empty string`);
    }
    if (!['prd', 'techspec', 'tasks', 'code', 'tests', 'pr'].includes(entry.source.phase)) {
      errors.push(`${pathPrefix}.source.phase is invalid`);
    }
    if (typeof entry.source.run_id !== 'string' || entry.source.run_id.length < 1) {
      errors.push(`${pathPrefix}.source.run_id must be a non-empty string`);
    }
    if (typeof entry.source.artifact !== 'string' || entry.source.artifact.length < 1 || path.isAbsolute(entry.source.artifact)) {
      errors.push(`${pathPrefix}.source.artifact must be a relative path`);
    }
    if (entry.source.line_range !== undefined) {
      const range = entry.source.line_range;
      if (!Array.isArray(range) || range.length !== 2 || !range.every((n) => Number.isInteger(n) && n >= 1) || range[0] > range[1]) {
        errors.push(`${pathPrefix}.source.line_range must be [start, end] with start <= end`);
      }
    }
  }
  if (!Number.isInteger(entry.applied_count) || entry.applied_count < 0) {
    errors.push(`${pathPrefix}.applied_count must be a non-negative integer`);
  }
  if (!isIsoDateTime(entry.last_applied)) {
    errors.push(`${pathPrefix}.last_applied must be ISO8601 date-time`);
  }
  if (!['feature', 'user_correction', 'manual', 'auto_detected'].includes(entry.promoted_from)) {
    errors.push(`${pathPrefix}.promoted_from is invalid`);
  }
  if (!(entry.agent_specific === null || ['claude-code', 'codex', 'gemini'].includes(entry.agent_specific))) {
    errors.push(`${pathPrefix}.agent_specific must be claude-code, codex, gemini, or null`);
  }
  if (!Array.isArray(entry.tags) || !entry.tags.every((tag) => typeof tag === 'string' && tag.length > 0)) {
    errors.push(`${pathPrefix}.tags must be a list of non-empty strings`);
  }
  return errors;
}

let data;
try {
  data = parseDocument(file);
} catch (error) {
  console.error(`${file}: parse error: ${error.message}`);
  process.exit(1);
}
const entries = Array.isArray(data) ? data : [data];
let errors = [];
entries.forEach((entry, index) => {
  errors = errors.concat(validateEntry(entry, Array.isArray(data) ? `$[${index}]` : '$'));
});
if (errors.length > 0) {
  for (const error of errors) console.error(`${file}: ${error}`);
  process.exit(1);
}
console.log(`${file}: ok`);
JSEOF
}

_memory_lint() {
  local files_csv="${OPT_MEMORY_FILES:-}"
  if [ -z "$files_csv" ]; then
    files_csv=$(_memory_lint_files_from_defaults)
  fi
  if [ -z "$files_csv" ]; then
    printf 'No Memory v2 stores found. Pass files explicitly or create .monozukuri/memory-v2.json.\n'
    return 0
  fi

  local IFS_ORIG="$IFS" file rc=0
  IFS=","
  for file in $files_csv; do
    [ -n "$file" ] || continue
    if [ ! -f "$file" ]; then
      printf '%s: not found\n' "$file" >&2
      rc=1
      continue
    fi
    _memory_lint_file "$file" || rc=1
  done
  IFS="$IFS_ORIG"
  return "$rc"
}

sub_memory() {
  case "${OPT_MEMORY_ACTION:-}" in
    lint)
      _memory_lint
      ;;
    ""|--help|-h)
      echo "Usage:"
      echo "  monozukuri memory lint [file...]"
      echo ""
      echo "Validate Memory v2 learning entries."
      ;;
    *)
      err "Unknown memory action: $OPT_MEMORY_ACTION"
      err "Available: lint"
      return 1
      ;;
  esac
}
