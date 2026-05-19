#!/usr/bin/env node
'use strict';

const fs = require('fs');

const args = process.argv.slice(2);

function usage(exitCode = 0) {
  const out = exitCode === 0 ? process.stdout : process.stderr;
  out.write(`Usage:
  monozukuri backlog list [--format table|json|csv] [--limit N] [filters]
  monozukuri pick --json [--top N] [filters]

List or pick backlog items ranked by deterministic score.

Flags:
  --format table|json|csv   Output format (default: table)
  --limit N                 Maximum items to print (default: 50, max: 500)
  --pick                    Emit pick JSON objects with score
  --pick-card               Emit rich pick objects for the interactive TUI
  --top N                   Maximum picked items (default: 5, max: 50)
  --label foo,bar           Include items with any listed label
  --status ready|blocked|in-progress|done
                            Include items by status (default: ready)
  --exclude-blocked         Shortcut for --status ready
  --agent claude-code|codex|gemini
                            Include items explicitly compatible with an agent
  --score-explain id        Show the ranking score breakdown for one item
  --help                    Show this help
`);
  process.exit(exitCode);
}

let file = '';
let format = 'table';
let limit = null;
let pickMode = false;
let pickCardMode = false;
let top = null;
let labelFilter = [];
let statusFilter = 'ready';
let agentFilter = '';
let scoreExplainId = '';
let weights = {
  priority: numberFromEnv('MONOZUKURI_SCORING_PRIORITY_WEIGHT', 10),
  age: numberFromEnv('MONOZUKURI_SCORING_AGE_WEIGHT', 1),
  effort: numberFromEnv('MONOZUKURI_SCORING_EFFORT_WEIGHT', 2),
};
const nowMs = Date.parse(process.env.MONOZUKURI_SCORE_NOW || new Date().toISOString());

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
    case '--pick':
      pickMode = true;
      break;
    case '--pick-card':
      pickMode = true;
      pickCardMode = true;
      break;
    case '--top':
      top = Number(args[++i]);
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
    case '--score-explain':
      scoreExplainId = args[++i] || '';
      break;
    case '--priority-weight':
      weights.priority = Number(args[++i]);
      break;
    case '--age-weight':
      weights.age = Number(args[++i]);
      break;
    case '--effort-weight':
      weights.effort = Number(args[++i]);
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

if (top !== null && !pickMode) {
  process.stderr.write('Invalid --top: only supported by monozukuri pick\n');
  process.exit(2);
}

if (pickMode) {
  limit = top === null ? 5 : top;
  if (!Number.isInteger(limit) || limit < 1 || limit > 50) {
    process.stderr.write('Invalid --top: expected integer from 1 to 50\n');
    process.exit(2);
  }
} else {
  limit = limit === null ? 50 : limit;
  if (!Number.isInteger(limit) || limit < 1 || limit > 500) {
    process.stderr.write('Invalid --limit: expected integer from 1 to 500\n');
    process.exit(2);
  }
}

if (!['ready', 'blocked', 'in-progress', 'done'].includes(statusFilter)) {
  process.stderr.write(`Invalid --status: ${statusFilter || '(empty)'}\n`);
  process.exit(2);
}

if (agentFilter && !['claude-code', 'codex', 'gemini'].includes(agentFilter)) {
  process.stderr.write(`Invalid --agent: ${agentFilter}\n`);
  process.exit(2);
}

if (!Number.isFinite(weights.priority) || !Number.isFinite(weights.age) || !Number.isFinite(weights.effort)) {
  process.stderr.write('Invalid scoring weights: expected numeric priority, age, and effort weights\n');
  process.exit(2);
}

if (Number.isNaN(nowMs)) {
  process.stderr.write('Invalid MONOZUKURI_SCORE_NOW: expected parseable date\n');
  process.exit(2);
}

function numberFromEnv(name, fallback) {
  const value = process.env[name];
  if (value === undefined || value === '') return fallback;
  return Number(value);
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
  normal: 2,
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

function creationTimestamp(item) {
  const candidates = [
    item.created_at,
    item.createdAt,
    item.created,
    item.metadata?.created_at,
    item.metadata?.createdAt,
    item.metadata?.created,
  ].filter(Boolean);

  for (const value of candidates) {
    const ms = Date.parse(value);
    if (!Number.isNaN(ms)) return ms;
  }
  return null;
}

function ageValue(item, index) {
  const ms = creationTimestamp(item);
  if (ms !== null) return ms;
  return index;
}

function truncateTitle(title) {
  const text = String(title || '').replace(/\s+/g, ' ').trim();
  if (text.length <= 60) return text;
  return `${text.slice(0, 57)}...`;
}

function ranked(items, options = {}) {
  const includeScore = options.includeScore === true;
  const includeDetails = options.includeDetails === true;
  const byId = itemsById(items);
  return items
    .filter(matchesFilters)
    .map((item, index) => ({ item, index, age: ageValue(item, index), score: scoreBreakdown(item, byId).score }))
    .sort((a, b) => {
      const scoreDelta = b.score - a.score;
      if (scoreDelta !== 0) return scoreDelta;
      const priorityDelta =
        (priorityRank[normalizedPriority(b.item)] ?? 0) -
        (priorityRank[normalizedPriority(a.item)] ?? 0);
      if (priorityDelta !== 0) return priorityDelta;
      const ageDelta = a.age - b.age;
      if (ageDelta !== 0) return ageDelta;
      return a.index - b.index;
    })
    .slice(0, limit)
    .map(({ item, score }) => {
      const row = {
        id: String(item.id || item.source_id || '-'),
        priority: normalizedPriority(item),
        effort: effort(item),
        status: status(item),
        title: truncateTitle(item.title),
      };
      if (includeScore) {
        const scoredRow = {
          id: row.id,
          score,
          priority: row.priority,
          effort: row.effort,
          title: row.title,
        };
        if (includeDetails) {
          return {
            ...scoredRow,
            status: row.status,
            description: description(item),
            deps: unique(dependencies(item)).map(String),
          };
        }
        return scoredRow;
      }
      return row;
    });
}

function itemsById(items) {
  const byId = new Map();
  for (const item of items) {
    const id = String(item.id || item.source_id || '').trim();
    if (id) byId.set(id, item);
  }
  return byId;
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

function description(item) {
  return String(
    item.description ||
    item.body ||
    item.summary ||
    item.metadata?.description ||
    item.metadata?.body ||
    item.metadata?.summary ||
    ''
  ).trim();
}

function unique(values) {
  return [...new Set(values)];
}

function effortPoints(item) {
  const raw = effort(item).trim().toLowerCase();
  if (!raw || raw === '-') return 0;
  const numeric = Number(raw);
  if (Number.isFinite(numeric)) return numeric;

  const tshirt = {
    xs: 1,
    s: 1,
    small: 1,
    m: 3,
    medium: 3,
    l: 5,
    large: 5,
    xl: 8,
    xlarge: 8,
    xxl: 13,
  };
  return tshirt[raw] ?? 0;
}

function ageWeeks(item) {
  const createdMs = creationTimestamp(item);
  if (createdMs === null || createdMs > nowMs) return 0;
  return Math.floor((nowMs - createdMs) / (7 * 24 * 60 * 60 * 1000));
}

function dependencyPenalty(item, byId) {
  const unsatisfied = [];
  for (const dep of unique(dependencies(item))) {
    const depItem = byId.get(dep);
    if (!depItem || rawStatus(depItem) !== 'done') unsatisfied.push(dep);
  }
  return {
    value: unsatisfied.length > 0 ? -100 : 0,
    unsatisfied,
  };
}

function scoreBreakdown(item, byId) {
  const priorityValue = priorityRank[normalizedPriority(item)] ?? 0;
  const weeks = ageWeeks(item);
  const points = effortPoints(item);
  const depPenalty = dependencyPenalty(item, byId);
  const priorityContribution = weights.priority * priorityValue;
  const ageContribution = weights.age * weeks;
  const effortContribution = weights.effort * points;
  const score = priorityContribution + ageContribution - effortContribution + depPenalty.value;

  return {
    score,
    priority: {
      label: normalizedPriority(item),
      value: priorityValue,
      weight: weights.priority,
      contribution: priorityContribution,
    },
    age: {
      weeks,
      weight: weights.age,
      contribution: ageContribution,
    },
    effort: {
      raw: effort(item),
      points,
      weight: weights.effort,
      contribution: -effortContribution,
    },
    dependencies: {
      declared: unique(dependencies(item)),
      unsatisfied: depPenalty.unsatisfied,
      penalty: depPenalty.value,
    },
  };
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

function printScoreExplain(item, byId) {
  const id = String(item.id || item.source_id || '-');
  const title = String(item.title || '').replace(/\s+/g, ' ').trim();
  const breakdown = scoreBreakdown(item, byId);

  process.stdout.write(`ID: ${id}\n`);
  process.stdout.write(`Title: ${title}\n`);
  process.stdout.write(`Score: ${formatNumber(breakdown.score)}\n`);
  process.stdout.write(`Formula: (priority_weight * P) + (age_weight * A) - (effort_weight * E) + dependency_penalty\n`);
  process.stdout.write(
    `Priority: ${breakdown.priority.label} => P=${breakdown.priority.value}, weight=${formatNumber(breakdown.priority.weight)}, contribution=${formatNumber(breakdown.priority.contribution)}\n`
  );
  process.stdout.write(
    `Age: A=${breakdown.age.weeks} week(s), weight=${formatNumber(breakdown.age.weight)}, contribution=${formatNumber(breakdown.age.contribution)}\n`
  );
  process.stdout.write(
    `Effort: ${breakdown.effort.raw} => E=${formatNumber(breakdown.effort.points)}, weight=${formatNumber(breakdown.effort.weight)}, contribution=${formatNumber(breakdown.effort.contribution)}\n`
  );
  process.stdout.write(
    `Dependencies: declared=${breakdown.dependencies.declared.join(', ') || 'none'}, unsatisfied=${breakdown.dependencies.unsatisfied.join(', ') || 'none'}, penalty=${formatNumber(breakdown.dependencies.penalty)}\n`
  );
}

function formatNumber(value) {
  if (Number.isInteger(value)) return String(value);
  return String(Number(value.toFixed(3)));
}

try {
  const items = readItems(file);
  if (scoreExplainId) {
    const byId = itemsById(items);
    const item = byId.get(scoreExplainId);
    if (!item) {
      process.stderr.write(`No backlog item found for --score-explain ${scoreExplainId}\n`);
      process.exit(2);
    }
    printScoreExplain(item, byId);
    process.exit(0);
  }

  const rows = ranked(items, { includeScore: pickMode, includeDetails: pickCardMode });
  if (pickMode) printJson(rows);
  else if (format === 'json') printJson(rows);
  else if (format === 'csv') printCsv(rows);
  else printTable(rows);
} catch (error) {
  process.stderr.write(`backlog list failed: ${error.message}\n`);
  process.exit(1);
}
