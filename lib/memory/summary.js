#!/usr/bin/env node
/* Memory v2 deterministic summary compactor. */

const crypto = require('crypto');
const fs = require('fs');
const path = require('path');

const DEFAULT_TOKEN_CAP = 500;
const TTL_MS = 7 * 24 * 60 * 60 * 1000;
const GROUP_ORDER = ['feature', 'project', 'global'];

function readStdin() {
  return fs.readFileSync(0, 'utf8');
}

function loadTokenizer() {
  try {
    // js-tiktoken mirrors OpenAI tiktoken encodings and avoids native builds.
    const {getEncoding} = require('js-tiktoken');
    const encoding = getEncoding('cl100k_base');
    return {
      name: 'cl100k_base',
      count(text) {
        return encoding.encode(String(text || '')).length;
      }
    };
  } catch (_) {
    return {
      name: 'byte-fallback',
      count(text) {
        return Math.ceil(Buffer.byteLength(String(text || ''), 'utf8') / 4);
      }
    };
  }
}

const tokenizer = loadTokenizer();

function tokenCount(text) {
  return tokenizer.count(text);
}

function stableJson(value) {
  if (Array.isArray(value)) return `[${value.map(stableJson).join(',')}]`;
  if (value && typeof value === 'object') {
    return `{${Object.keys(value).sort().map((key) => `${JSON.stringify(key)}:${stableJson(value[key])}`).join(',')}}`;
  }
  return JSON.stringify(value);
}

function hashFor(phase, featureId, learnings) {
  return crypto
    .createHash('sha256')
    .update(stableJson({phase, featureId, learnings}))
    .digest('hex');
}

function cachePath(cacheDir, phase, featureId, hash) {
  const safePhase = String(phase || 'unknown').replace(/[^A-Za-z0-9_.-]/g, '_');
  const safeFeature = String(featureId || 'unknown').replace(/[^A-Za-z0-9_.-]/g, '_');
  return path.join(cacheDir, `${safePhase}-${safeFeature}-${hash.slice(0, 16)}.json`);
}

function readCache(file) {
  try {
    const stat = fs.statSync(file);
    if ((Date.now() - stat.mtimeMs) > TTL_MS) return null;
    const parsed = JSON.parse(fs.readFileSync(file, 'utf8'));
    if (!parsed || typeof parsed.summary_text !== 'string') return null;
    return parsed;
  } catch (_) {
    return null;
  }
}

function writeCache(file, payload) {
  fs.mkdirSync(path.dirname(file), {recursive: true});
  const tmp = `${file}.tmp-${process.pid}`;
  fs.writeFileSync(tmp, JSON.stringify(payload, null, 2) + '\n');
  fs.renameSync(tmp, file);
}

function normalizeLearning(entry) {
  if (!entry || typeof entry !== 'object') return null;
  if (!entry.id || !entry.insight) return null;
  return {
    ...entry,
    scope: entry.scope || 'project',
    applied_count: Number.isInteger(entry.applied_count) ? entry.applied_count : 0,
    insight: String(entry.insight).replace(/\s+/g, ' ').trim()
  };
}

function sortAndSelect(learnings) {
  const normalized = learnings.map(normalizeLearning).filter(Boolean);
  const selected = [];
  const selectedIds = new Set();
  for (const scope of GROUP_ORDER) {
    normalized
      .filter((entry) => entry.scope === scope)
      .sort((a, b) =>
        b.applied_count - a.applied_count ||
        String(a.id).localeCompare(String(b.id))
      )
      .slice(0, 5)
      .forEach((entry) => {
        selected.push(entry);
        selectedIds.add(entry.id);
      });
  }
  const omitted = normalized.filter((entry) => !selectedIds.has(entry.id));
  return {selected, omitted};
}

function lineFor(entry) {
  return `<!-- learning: ${entry.id} --> [${entry.id}, applied ${entry.applied_count}x] ${entry.insight}`;
}

function truncateToTokenCap(text, cap) {
  if (tokenCount(text) <= cap) return text;
  let lo = 0;
  let hi = text.length;
  let best = '';
  while (lo <= hi) {
    const mid = Math.floor((lo + hi) / 2);
    const candidate = `${text.slice(0, mid).trimEnd()}...`;
    if (tokenCount(candidate) <= cap) {
      best = candidate;
      lo = mid + 1;
    } else {
      hi = mid - 1;
    }
  }
  return best;
}

function compactLines(lines, cap) {
  const kept = [];
  const omitted = [];
  for (const item of lines) {
    const candidate = kept.concat(item.line).join('\n');
    if (tokenCount(candidate) <= cap) {
      kept.push(item.line);
    } else {
      omitted.push(item.id);
    }
  }
  if (kept.length === 0 && lines.length > 0) {
    kept.push(truncateToTokenCap(lines[0].line, cap));
    omitted.push(...lines.slice(1).map((item) => item.id));
  }
  return {summaryText: kept.join('\n'), omittedIds: omitted};
}

function summarize({phase, featureId, learnings, cacheDir, cap}) {
  const parsedCap = Number(cap);
  const tokenCap = Number.isFinite(parsedCap) && parsedCap > 0 ? Math.floor(parsedCap) : DEFAULT_TOKEN_CAP;
  const hash = hashFor(phase, featureId, learnings);
  const file = cachePath(cacheDir, phase, featureId, hash);
  const cached = readCache(file);
  if (cached) return {...cached, cache_hit: true, cache_path: file};

  const {selected, omitted} = sortAndSelect(learnings);
  const lines = selected.map((entry) => ({id: entry.id, line: lineFor(entry)}));
  const compacted = compactLines(lines, tokenCap);
  const payload = {
    phase,
    feature_id: featureId,
    tokenizer: tokenizer.name,
    token_cap: tokenCap,
    learning_hash: hash,
    summary_text: compacted.summaryText,
    available_on_request: [...compacted.omittedIds, ...omitted.map((entry) => entry.id)],
    generated_at: new Date().toISOString()
  };
  writeCache(file, payload);
  return {...payload, cache_hit: false, cache_path: file};
}

function relevantEntries(entries, featureId, agent) {
  if (!Array.isArray(entries)) return [];
  return entries.filter((entry) => {
    if (!entry || typeof entry !== 'object') return false;
    if (!entry.id || !entry.insight) return false;
    if (entry.agent_specific && entry.agent_specific !== agent) return false;
    if (entry.scope === 'feature') {
      return entry.source && entry.source.feature_id === featureId;
    }
    return entry.scope === 'project' || entry.scope === 'global';
  });
}

function contextEntries({phase, featureId, agent, learnings, cacheDir, cap}) {
  const relevant = relevantEntries(learnings, featureId, agent);
  const result = summarize({phase, featureId, learnings: relevant, cacheDir, cap});
  const out = [];
  for (const line of result.summary_text.split(/\n/).filter(Boolean)) {
    const match = line.match(/<!--\s*learning:\s*([A-Za-z0-9_.:-]+)\s*-->/);
    out.push({id: match ? match[1] : null, summary: line});
  }
  if (result.available_on_request.length > 0) {
    out.push({
      summary: `available_on_request: ${result.available_on_request.join(', ')}`,
      available_on_request: result.available_on_request
    });
  }
  return out;
}

function main() {
  const mode = process.argv[2];
  if (mode === 'count') {
    process.stdout.write(String(tokenCount(process.argv.slice(3).join(' '))));
    return;
  }

  const phase = process.argv[3];
  const featureId = process.argv[4];
  const cacheDir = process.argv[5];
  const cap = process.argv[6];
  let learnings = [];
  try {
    const input = readStdin().trim();
    learnings = input ? JSON.parse(input) : [];
  } catch (_) {
    learnings = [];
  }

  if (mode === 'summarize') {
    const result = summarize({phase, featureId, learnings, cacheDir, cap});
    process.stdout.write(result.summary_text);
    return;
  }

  if (mode === 'context') {
    const agent = process.argv[7] || '';
    const result = contextEntries({phase, featureId, agent, learnings, cacheDir, cap});
    process.stdout.write(JSON.stringify(result));
    return;
  }

  console.error('usage: summary.js <count|summarize|context> ...');
  process.exit(2);
}

if (require.main === module) {
  main();
}
