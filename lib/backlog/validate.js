#!/usr/bin/env node
'use strict';

const fs = require('fs');

const args = process.argv.slice(2);

function usage(exitCode = 0) {
  const out = exitCode === 0 ? process.stdout : process.stderr;
  out.write(`Usage: monozukuri backlog validate [--strict] <id> [id...]

Validate selected backlog dependencies without writing to stdout.

Flags:
  --file path   Adapter JSON output file
  --ids a,b     Selected feature IDs
  --strict      Report warnings as errors and exit 1
  --help        Show this help
`);
  process.exit(exitCode);
}

let file = '';
let ids = [];
let strict = false;

for (let i = 0; i < args.length; i += 1) {
  const arg = args[i];
  switch (arg) {
    case '--file':
      file = args[++i] || '';
      break;
    case '--ids':
      ids = splitList(args[++i] || '');
      break;
    case '--strict':
      strict = true;
      break;
    case '--help':
    case '-h':
      usage(0);
      break;
    default:
      if (arg.startsWith('--')) {
        process.stderr.write(`Unknown argument: ${arg}\n`);
        usage(2);
      }
      ids.push(...splitList(arg));
      break;
  }
}

if (!file) {
  process.stderr.write('Missing --file\n');
  usage(2);
}

if (ids.length === 0) {
  process.stderr.write('Missing selected feature IDs\n');
  usage(2);
}

function splitList(value) {
  return String(value || '')
    .split(',')
    .map((item) => item.trim())
    .filter(Boolean);
}

function readItems(path) {
  const raw = fs.readFileSync(path, 'utf8');
  const parsed = JSON.parse(raw);
  if (!Array.isArray(parsed)) {
    throw new Error('backlog adapter output must be a JSON array');
  }
  return parsed;
}

function itemId(item) {
  return String(item.id || item.source_id || '').trim();
}

function rawStatus(item) {
  return String(item.status || '').toLowerCase();
}

function isDone(item) {
  return rawStatus(item) === 'done';
}

function dependencies(item) {
  return [
    item.dependencies,
    item.depends_on,
    item.dependsOn,
    item.metadata?.dependencies,
    item.metadata?.depends_on,
    item.metadata?.dependsOn,
  ].flatMap((value) => Array.isArray(value) ? value : splitList(value || ''));
}

function unique(values) {
  return [...new Set(values)];
}

function selectedItems(selectedIds, byId, warnings) {
  const result = [];
  for (const id of selectedIds) {
    const item = byId.get(id);
    if (!item) {
      warnings.push(`selected feature ${id} is not present in the backlog; suggestion: remove ${id} from the selection or add it to the backlog`);
      continue;
    }
    result.push(item);
  }
  return result;
}

function dependencyWarnings(items, selected, byId) {
  const warnings = [];

  for (const item of items) {
    const featureId = itemId(item);
    for (const dep of unique(dependencies(item))) {
      const depItem = byId.get(dep);
      if (!depItem) {
        warnings.push(`feature ${featureId} depends on missing ${dep}; suggestion: add ${dep} to the backlog or remove it from ${featureId}`);
        continue;
      }

      if (!isDone(depItem) && !selected.has(dep)) {
        warnings.push(`feature ${featureId} depends on unresolved ${dep}; suggestion: include ${dep} or mark as done`);
      }
    }
  }

  return warnings;
}

function cycleWarnings(items, selected) {
  const selectedIds = items.map(itemId);
  const indegree = new Map(selectedIds.map((id) => [id, 0]));
  const outgoing = new Map(selectedIds.map((id) => [id, []]));

  for (const item of items) {
    const featureId = itemId(item);
    for (const dep of unique(dependencies(item))) {
      if (!selected.has(dep)) continue;
      outgoing.get(dep).push(featureId);
      indegree.set(featureId, (indegree.get(featureId) || 0) + 1);
    }
  }

  const queue = selectedIds.filter((id) => indegree.get(id) === 0);
  const visited = [];

  while (queue.length > 0) {
    const id = queue.shift();
    visited.push(id);
    for (const next of outgoing.get(id) || []) {
      indegree.set(next, indegree.get(next) - 1);
      if (indegree.get(next) === 0) queue.push(next);
    }
  }

  if (visited.length === selectedIds.length) return [];

  const cycleIds = selectedIds.filter((id) => (indegree.get(id) || 0) > 0);
  return [`selection contains a dependency cycle involving ${cycleIds.join(', ')}; suggestion: remove one dependency edge or split the selection`];
}

try {
  const items = readItems(file);
  const byId = new Map();
  for (const item of items) {
    const id = itemId(item);
    if (id) byId.set(id, item);
  }

  const selected = new Set(unique(ids));
  const warnings = [];
  const itemsToValidate = selectedItems(selected, byId, warnings);
  warnings.push(...dependencyWarnings(itemsToValidate, selected, byId));
  warnings.push(...cycleWarnings(itemsToValidate, selected));

  if (warnings.length === 0) process.exit(0);

  const label = strict ? 'error' : 'warning';
  for (const warning of warnings) {
    process.stderr.write(`${label}: ${warning}\n`);
  }
  process.exit(strict ? 1 : 2);
} catch (error) {
  process.stderr.write(`backlog validate failed: ${error.message}\n`);
  process.exit(1);
}
