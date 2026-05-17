#!/usr/bin/env node
'use strict';

const fs = require('fs');

const args = process.argv.slice(2);

function usage(exitCode = 0) {
  const out = exitCode === 0 ? process.stdout : process.stderr;
  out.write(`Usage: monozukuri backlog list [--format table|json|csv] [--limit N]

List backlog items ranked by priority, then age.

Flags:
  --format table|json|csv   Output format (default: table)
  --limit N                 Maximum items to print (default: 50, max: 500)
  --help                    Show this help
`);
  process.exit(exitCode);
}

let file = '';
let format = 'table';
let limit = 50;

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
  return String(item.status || '-');
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

function csvEscape(value) {
  const s = String(value);
  if (!/[",\n]/.test(s)) return s;
  return `"${s.replace(/"/g, '""')}"`;
}

function printTable(rows) {
  if (rows.length === 0) {
    process.stdout.write('No backlog items found. Run `monozukuri init` to create a starter features.md.\n');
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
