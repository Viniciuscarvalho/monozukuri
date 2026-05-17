#!/usr/bin/env node
'use strict';

const fs = require('fs');

const args = process.argv.slice(2);

function usage(exitCode = 0) {
  const out = exitCode === 0 ? process.stdout : process.stderr;
  out.write(`Usage: monozukuri backlog list [--format table|json|csv] [--limit N] [filters]

List backlog items ranked by priority, then age.

Flags:
  --format table|json|csv   Output format (default: table)
  --limit N                 Maximum items to print (default: 50, max: 500)
  --label foo,bar           Include items with any listed label
  --status ready|blocked|in-progress|done
                            Include items by status (default: ready)
  --exclude-blocked         Shortcut for --status ready
  --agent claude-code|codex|gemini
                            Include items explicitly compatible with an agent
  --help                    Show this help
`);
  process.exit(exitCode);
}

let file = '';
let format = 'table';
let limit = 50;
let labelFilter = [];
let statusFilter = 'ready';
let agentFilter = '';

for (let i = 0; i < args.length; i += 1) {
  const arg = args[i];
  switch (arg) {
    case '--file':
      file = args[++i] || '';
      break;
    case '--format':
      format = args[++i] || '';
      break;
    case '--limit':
      limit = Number(args[++i]);
      break;
    case '--label':
      labelFilter = splitList(args[++i] || '');
      break;
    case '--status':
      statusFilter = args[++i] || '';
      break;
    case '--exclude-blocked':
      statusFilter = 'ready';
      break;
    case '--agent':
      agentFilter = args[++i] || '';
      break;
    case '--help':
    case '-h':
      usage(0);
      break;
    default:
      process.stderr.write(`Unknown argument: ${arg}\n`);
      usage(2);
  }
}

if (!file) {
  process.stderr.write('Missing --file\n');
  usage(2);
}

if (!['table', 'json', 'csv'].includes(format)) {
  process.stderr.write(`Invalid --format: ${format || '(empty)'}\n`);
  usage(2);
}

if (!Number.isInteger(limit) || limit < 1 || limit > 500) {
  process.stderr.write('Invalid --limit: expected integer from 1 to 500\n');
  process.exit(2);
}

if (!['ready', 'blocked', 'in-progress', 'done'].includes(statusFilter)) {
  process.stderr.write(`Invalid --status: ${statusFilter || '(empty)'}\n`);
  process.exit(2);
}

if (agentFilter && !['claude-code', 'codex', 'gemini'].includes(agentFilter)) {
  process.stderr.write(`Invalid --agent: ${agentFilter}\n`);
  process.exit(2);
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

const priorityRank = {
  high: 3,
  medium: 2,
  low: 1,
  none: 0,
};

function normalizedPriority(item) {
  return String(item.priority || 'none').toLowerCase();
}

function effort(item) {
  return String(item.effort || item.metadata?.effort || item.estimate || item.metadata?.estimate || '-');
}

function status(item) {
  const raw = rawStatus(item);
  return raw === 'backlog' ? 'ready' : raw;
}

function rawStatus(item) {
  return String(item.status || '-').toLowerCase();
}

function ageValue(item, index) {
  const candidates = [
    item.created_at,
    item.createdAt,
    item.created,
    item.updated_at,
    item.metadata?.created_at,
    item.metadata?.createdAt,
    item.metadata?.created,
  ].filter(Boolean);

  for (const value of candidates) {
    const ms = Date.parse(value);
    if (!Number.isNaN(ms)) return ms;
  }
  return index;
}

function truncateTitle(title) {
  const text = String(title || '').replace(/\s+/g, ' ').trim();
  if (text.length <= 60) return text;
  return `${text.slice(0, 57)}...`;
}

function ranked(items) {
  return items
    .filter(matchesFilters)
    .map((item, index) => ({ item, index, age: ageValue(item, index) }))
    .sort((a, b) => {
      const priorityDelta =
        (priorityRank[normalizedPriority(b.item)] ?? 0) -
        (priorityRank[normalizedPriority(a.item)] ?? 0);
      if (priorityDelta !== 0) return priorityDelta;
      const ageDelta = a.age - b.age;
      if (ageDelta !== 0) return ageDelta;
      return a.index - b.index;
    })
    .slice(0, limit)
    .map(({ item }) => ({
      id: String(item.id || item.source_id || '-'),
      priority: normalizedPriority(item),
      effort: effort(item),
      status: status(item),
      title: truncateTitle(item.title),
    }));
}

function labels(item) {
  const raw = Array.isArray(item.labels) ? item.labels : [];
  return raw.map((label) => String(label).toLowerCase());
}

function compatibleAgents(item) {
  const values = [
    item.agent,
    item.agents,
    item.compatible_agents,
    item.agent_compatibility,
    item.metadata?.agent,
    item.metadata?.agents,
    item.metadata?.compatible_agents,
    item.metadata?.agent_compatibility,
  ].flatMap((value) => Array.isArray(value) ? value : splitList(value || ''));

  return values.map((value) => String(value).trim().toLowerCase()).filter(Boolean);
}

function matchesStatus(item) {
  const raw = rawStatus(item);
  if (statusFilter === 'ready') return raw === 'ready' || raw === 'backlog';
  return raw === statusFilter;
}

function matchesFilters(item) {
  if (!matchesStatus(item)) return false;

  if (labelFilter.length > 0) {
    const wanted = labelFilter.map((label) => label.toLowerCase());
    const present = labels(item);
    if (!wanted.some((label) => present.includes(label))) return false;
  }

  if (agentFilter) {
    if (!compatibleAgents(item).includes(agentFilter)) return false;
  }

  return true;
}

function csvEscape(value) {
  const s = String(value);
  if (!/[",\n]/.test(s)) return s;
  return `"${s.replace(/"/g, '""')}"`;
}

function printTable(rows) {
  if (rows.length === 0) {
    const hasFilters = labelFilter.length > 0 || statusFilter !== 'ready' || agentFilter;
    if (hasFilters) {
      process.stdout.write('No backlog items match the selected filters. Try adjusting --label, --status, or --agent.\n');
    } else {
      process.stdout.write('No backlog items found. Run `monozukuri init` to create a starter features.md.\n');
    }
    return;
  }

  process.stdout.write(`${'ID'.padEnd(24)} ${'PRIORITY'.padEnd(8)} ${'EFFORT'.padEnd(6)} ${'STATUS'.padEnd(12)} TITLE\n`);
  for (const row of rows) {
    process.stdout.write(
      `${row.id.slice(0, 24).padEnd(24)} ` +
      `${row.priority.slice(0, 8).padEnd(8)} ` +
      `${row.effort.slice(0, 6).padEnd(6)} ` +
      `${row.status.slice(0, 12).padEnd(12)} ` +
      `${row.title}\n`
    );
  }
}

function printJson(rows) {
  process.stdout.write(`${JSON.stringify(rows, null, 2)}\n`);
}

function printCsv(rows) {
  process.stdout.write('id,priority,effort,status,title\n');
  for (const row of rows) {
    process.stdout.write([row.id, row.priority, row.effort, row.status, row.title].map(csvEscape).join(',') + '\n');
  }
}

try {
  const rows = ranked(readItems(file));
  if (format === 'json') printJson(rows);
  else if (format === 'csv') printCsv(rows);
  else printTable(rows);
} catch (error) {
  process.stderr.write(`backlog list failed: ${error.message}\n`);
  process.exit(1);
}
