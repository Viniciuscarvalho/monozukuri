#!/usr/bin/env node

// scripts/parse-config.js
// Simple YAML config parser — outputs flat KEY=value pairs for shell consumption
// Supports up to 4 levels of nesting: section.subsection.sub2.key
// Hyphens in keys are normalized to underscores in variable names.
// Usage: eval "$(node scripts/parse-config.js orchestrator/config.yml)"

const fs = require('fs');
const path = require('path');

const configPath = process.argv[2] || path.join(__dirname, '..', 'orchestrator', 'config.yml');

if (!fs.existsSync(configPath)) {
  console.error(`# Config not found: ${configPath}`);
  process.exit(1);
}

// Normalize a YAML key to a shell-safe uppercase variable segment.
function norm(k) { return k.replace(/-/g, '_').toUpperCase(); }

const content = fs.readFileSync(configPath, 'utf-8');
const config = {};
let section = '';      // 0-indent section
let subsection = '';   // 2-indent subsection
let sub2section = '';  // 4-indent sub-subsection

for (const line of content.split('\n')) {
  if (/^\s*#/.test(line) || /^\s*$/.test(line)) continue;

  // Measure indent
  const indent = line.match(/^(\s*)/)[1].length;

  // Top-level key (indent 0)
  if (indent === 0) {
    const m = line.match(/^([\w][\w_-]*)\s*:\s*(.*)/);
    if (!m) continue;
    const [, key, rawVal] = m;
    const val = rawVal.replace(/#.*$/, '').trim();
    if (val && val !== '[]' && val !== '{}') {
      section = '';
      subsection = '';
      sub2section = '';
      config[`CFG_${norm(key)}`] = val;
    } else {
      section = key;
      subsection = '';
      sub2section = '';
      if (val === '[]') config[`CFG_${norm(key)}`] = '';
    }
    continue;
  }

  // Level 1 nested (indent 2-3)
  if (indent >= 2 && indent <= 3 && section) {
    const m = line.match(/^\s{2,3}([\w][\w_-]*)\s*:\s*(.*)/);
    if (!m) continue;
    const [, key, rawVal] = m;
    const val = rawVal.replace(/#.*$/, '').trim();
    if (val && val !== '[]' && val !== '{}') {
      subsection = '';
      sub2section = '';
      config[`CFG_${norm(section)}_${norm(key)}`] = val;
    } else {
      subsection = key;
      sub2section = '';
      if (val === '[]') config[`CFG_${norm(section)}_${norm(key)}`] = '';
    }
    continue;
  }

  // Level 2 nested (indent 4-5)
  if (indent >= 4 && indent <= 5 && section && subsection) {
    const m = line.match(/^\s{4,5}([\w][\w_-]*)\s*:\s*(.*)/);
    if (!m) continue;
    const [, key, rawVal] = m;
    const val = rawVal.replace(/#.*$/, '').trim();
    if (val && val !== '[]' && val !== '{}') {
      sub2section = '';
      config[`CFG_${norm(section)}_${norm(subsection)}_${norm(key)}`] = val;
    } else {
      sub2section = key;
      if (val === '[]') config[`CFG_${norm(section)}_${norm(subsection)}_${norm(key)}`] = '';
    }
    continue;
  }

  // Level 3 nested (indent 6+)
  if (indent >= 6 && section && subsection && sub2section) {
    const m = line.match(/^\s{6,}([\w][\w_-]*)\s*:\s*(.+)/);
    if (!m) continue;
    const [, key, rawVal] = m;
    const val = rawVal.replace(/#.*$/, '').trim();
    config[`CFG_${norm(section)}_${norm(subsection)}_${norm(sub2section)}_${norm(key)}`] = val;
  }
}

for (const [key, val] of Object.entries(config)) {
  const safe = val.replace(/'/g, "'\\''");
  console.log(`${key}='${safe}'`);
}
