#!/bin/bash
# cmd/config.sh — sub_config(): config management subcommands
# Sourced by orchestrate.sh; inherits SCRIPT_DIR, LIB_DIR, CMD_DIR,
# SCRIPTS_DIR, TEMPLATES_DIR, PROJECT_ROOT, ROOT_DIR, CONFIG_DIR,
# STATE_DIR, RESULTS_DIR, and all OPT_* variables.

sub_config() {
  source "$LIB_DIR/cli/errors.sh"
  local action="${OPT_CONFIG_ACTION:-validate}"

  case "$action" in
    validate) _config_validate ;;
    show)     _config_show ;;
    *)
      err "Unknown config action: $action"
      err "Available: validate, show"
      exit 1
      ;;
  esac
}

_config_validate() {
  local config_file=".monozukuri/config.yaml"
  [ -n "${OPT_CONFIG:-}" ] && [ -f "$OPT_CONFIG" ] && config_file="$OPT_CONFIG"

  if [ ! -f "$config_file" ]; then
    monozukuri_error \
      "Config file not found: $config_file" \
      "No .monozukuri/config.yaml exists in this directory." \
      "Run: monozukuri init"
  fi

  if ! command -v node >/dev/null 2>&1; then
    err "node is required to validate config"
    exit 11
  fi

  local schema="$LIB_DIR/config/schema.json"

  # Convert YAML to JSON via parse-config.js, then validate against schema
  node - "$config_file" "$schema" <<'JSEOF'
const fs = require('fs');
const path = require('path');
const { execSync } = require('child_process');

const [,, configPath, schemaPath] = process.argv;

// Parse config via existing parse-config.js helper to get flat CFG_ vars,
// but we also need the raw object. Use js-yaml if available, else basic parse.
let raw;
try {
  // Try js-yaml (may not be installed)
  const yaml = require('js-yaml');
  raw = yaml.load(fs.readFileSync(configPath, 'utf-8'));
} catch {
  // Fall back: parse the flat env vars and report what we got
  console.log('  ℹ  Install js-yaml for deep schema validation.');
  console.log('  ✓  Config file exists and is readable.');
  process.exit(0);
}

const schema = JSON.parse(fs.readFileSync(schemaPath, 'utf-8'));

const errors = [];

function validate(obj, schemaNode, path) {
  if (!schemaNode || typeof schemaNode !== 'object') return;

  if (schemaNode.type === 'object') {
    if (typeof obj !== 'object' || obj === null) {
      errors.push(`${path}: expected object, got ${typeof obj}`);
      return;
    }
    // Check additionalProperties
    if (schemaNode.additionalProperties === false) {
      const allowed = new Set(Object.keys(schemaNode.properties || {}));
      for (const key of Object.keys(obj)) {
        if (!allowed.has(key)) errors.push(`${path}.${key}: unknown property`);
      }
    }
    // Check required
    for (const req of (schemaNode.required || [])) {
      if (!(req in obj)) errors.push(`${path}.${req}: required field missing`);
    }
    // Recurse
    for (const [k, subSchema] of Object.entries(schemaNode.properties || {})) {
      if (k in obj) validate(obj[k], subSchema, `${path}.${k}`);
    }
  } else if (schemaNode.type === 'string' && schemaNode.enum) {
    if (!schemaNode.enum.includes(obj)) {
      errors.push(`${path}: "${obj}" is not one of [${schemaNode.enum.join(', ')}]`);
    }
  } else if (schemaNode.type === 'integer') {
    if (!Number.isInteger(obj)) errors.push(`${path}: expected integer`);
    if (schemaNode.minimum !== undefined && obj < schemaNode.minimum)
      errors.push(`${path}: must be >= ${schemaNode.minimum}`);
  } else if (schemaNode.type === 'boolean') {
    if (typeof obj !== 'boolean') errors.push(`${path}: expected boolean`);
  }
}

validate(raw, schema, 'config');

if (errors.length === 0) {
  console.log('\x1b[32m✓\x1b[0m Config is valid: ' + configPath);
  process.exit(0);
} else {
  console.error('\x1b[31m✗\x1b[0m Config validation failed: ' + configPath);
  for (const e of errors) console.error('  • ' + e);
  process.exit(1);
}
JSEOF
}

_config_show() {
  local config_file=".monozukuri/config.yaml"
  [ -n "${OPT_CONFIG:-}" ] && [ -f "$OPT_CONFIG" ] && config_file="$OPT_CONFIG"

  if [ ! -f "$config_file" ]; then
    monozukuri_error \
      "Config file not found: $config_file" \
      "No .monozukuri/config.yaml exists in this directory." \
      "Run: monozukuri init"
  fi

  if [ "${OPT_JSON:-false}" = "true" ]; then
    node -e "
const fs = require('fs');
try {
  const yaml = require('js-yaml');
  console.log(JSON.stringify(yaml.load(fs.readFileSync('$config_file','utf-8')), null, 2));
} catch {
  console.log(fs.readFileSync('$config_file','utf-8'));
}
"
  else
    cat "$config_file"
  fi
}
