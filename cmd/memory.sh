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
  if (value === null) return true;
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
    errors.push(`${pathPrefix}.last_applied must be ISO8601 date-time or null`);
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

_memory_migrate() {
  node - \
    "$ROOT_DIR" \
    "$CONFIG_DIR" \
    "$HOME" \
    "${OPT_DRY_RUN:-false}" \
    "${OPT_MEMORY_MIGRATE_REVERSE:-false}" \
    "${OPT_MEMORY_FILES:-}" <<'JSEOF'
const fs = require('fs');
const path = require('path');

const [,, rootDir, configDir, homeDir, dryRunRaw, reverseRaw, filesCsv] = process.argv;
const dryRun = dryRunRaw === 'true';
const reverse = reverseRaw === 'true';

function rel(filePath) {
  const relative = path.relative(rootDir, filePath);
  return relative && !relative.startsWith('..') && !path.isAbsolute(relative)
    ? relative
    : filePath;
}

function readJsonArray(filePath) {
  try {
    const parsed = JSON.parse(fs.readFileSync(filePath, 'utf8'));
    return Array.isArray(parsed) ? parsed : [];
  } catch (error) {
    throw new Error(`${filePath}: ${error.message}`);
  }
}

function ensureDir(dir) {
  fs.mkdirSync(dir, {recursive: true});
}

function truncate(value, max) {
  const text = String(value || '');
  return text.length <= max ? text : text.slice(0, max - 3) + '...';
}

function datePart(value) {
  const date = new Date(value || 0);
  if (Number.isNaN(date.getTime())) return '1970-01-01';
  return date.toISOString().slice(0, 10);
}

function b64(value) {
  return Buffer.from(String(value ?? ''), 'utf8').toString('base64');
}

function unb64(value) {
  return Buffer.from(String(value || ''), 'base64').toString('utf8');
}

function tagValue(tags, key) {
  const prefix = `${key}:`;
  const found = (tags || []).find((tag) => String(tag).startsWith(prefix));
  return found ? String(found).slice(prefix.length) : undefined;
}

function boolValue(tags, key, fallback) {
  const value = tagValue(tags, key);
  if (value === undefined) return fallback;
  return value === 'true';
}

function numberValue(tags, key, fallback) {
  const value = tagValue(tags, key);
  if (value === undefined || value === '') return fallback;
  const parsed = Number(value);
  return Number.isFinite(parsed) ? parsed : fallback;
}

function sourceStores() {
  const stores = [];
  const projectPath = path.join(rootDir, '.claude/feature-state/learned.json');
  if (fs.existsSync(projectPath)) {
    stores.push({
      name: 'project',
      backupName: 'project.learned.json',
      scope: 'project',
      featureId: 'migrated-from-v1',
      artifact: rel(projectPath),
      path: projectPath
    });
  }

  const globalPath = path.join(homeDir, '.claude/monozukuri/learned/learned.json');
  if (fs.existsSync(globalPath)) {
    stores.push({
      name: 'global',
      backupName: 'global.learned.json',
      scope: 'global',
      featureId: 'migrated-from-v1',
      artifact: '.monozukuri/memory.v1.bak/global.learned.json',
      path: globalPath
    });
  }

  const stateDir = path.join(configDir, 'state');
  if (fs.existsSync(stateDir)) {
    for (const featureId of fs.readdirSync(stateDir).sort()) {
      const learnedPath = path.join(stateDir, featureId, 'learned.json');
      if (!fs.existsSync(learnedPath)) continue;
      stores.push({
        name: `feature:${featureId}`,
        backupName: `feature-${featureId}.learned.json`,
        scope: 'feature',
        featureId,
        artifact: rel(learnedPath),
        path: learnedPath
      });
    }
  }
  return stores;
}

function toV2(entry, store, index) {
  const legacyTier = ['feature', 'project', 'global'].includes(entry.tier) ? entry.tier : store.scope;
  const id = `lrn-${datePart(entry.created_at)}-${String(index + 1).padStart(3, '0')}`;
  const tags = [
    'migration:v1',
    `legacy-id:${String(entry.id || '')}`,
    `legacy-pattern-b64:${b64(entry.pattern)}`,
    `legacy-fix-b64:${b64(entry.fix)}`,
    `legacy-tier:${legacyTier}`,
    `legacy-created-at:${String(entry.created_at || '')}`,
    `legacy-last-seen:${String(entry.last_seen || '')}`,
    `legacy-hits:${String(entry.hits ?? 0)}`,
    `legacy-success-count:${String(entry.success_count ?? 0)}`,
    `legacy-failure-count:${String(entry.failure_count ?? 0)}`,
    `legacy-confidence:${String(entry.confidence ?? 0.5)}`,
    `legacy-ttl-days:${String(entry.ttl_days ?? 90)}`,
    `legacy-archived:${String(Boolean(entry.archived))}`,
    `legacy-promotion-candidate:${String(Boolean(entry.promotion_candidate))}`
  ];
  if (entry.promoted_at !== undefined) tags.push(`legacy-promoted-at:${String(entry.promoted_at)}`);
  if (entry.archived_at !== undefined) tags.push(`legacy-archived-at:${String(entry.archived_at)}`);

  return {
    id,
    scope: legacyTier,
    insight: truncate(entry.pattern, 200),
    rationale: truncate(entry.fix, 1000),
    source: {
      feature_id: store.featureId,
      phase: 'code',
      run_id: 'migrated-from-v1',
      artifact: store.artifact
    },
    applied_count: 0,
    last_applied: null,
    promoted_from: 'manual',
    agent_specific: null,
    tags
  };
}

function migrateForward() {
  const stores = sourceStores();
  const loadedStores = stores.map((store) => ({
    ...store,
    entries: readJsonArray(store.path)
  })).filter((store) => store.entries.length > 0);
  const count = loadedStores.reduce((sum, store) => sum + store.entries.length, 0);
  const outputPath = path.join(configDir, 'memory-v2.json');
  const backupDir = path.join(configDir, 'memory.v1.bak');

  if (count === 0) {
    console.log('No Memory v1 stores found. Nothing to migrate.');
    return;
  }

  if (dryRun) {
    console.log(`Would migrate ${count} v1 learning entries from ${loadedStores.length} stores to ${rel(outputPath)}`);
    console.log(`Would back up v1 stores to ${rel(backupDir)}/`);
    return;
  }

  ensureDir(configDir);
  ensureDir(backupDir);

  const migrated = [];
  let index = 0;
  for (const store of loadedStores) {
    fs.copyFileSync(store.path, path.join(backupDir, store.backupName));
    for (const entry of store.entries) {
      migrated.push(toV2(entry, store, index));
      index += 1;
    }
  }

  fs.writeFileSync(outputPath, JSON.stringify(migrated, null, 2) + '\n');
  console.log(`Migrated ${count} v1 learning entries to ${rel(outputPath)}`);
  console.log(`Backed up v1 stores to ${rel(backupDir)}/`);
}

function toV1(entry) {
  const tags = entry.tags || [];
  const id = tagValue(tags, 'legacy-id') || entry.id;
  const pattern = tagValue(tags, 'legacy-pattern-b64') !== undefined
    ? unb64(tagValue(tags, 'legacy-pattern-b64'))
    : String(entry.insight || '');
  const fix = tagValue(tags, 'legacy-fix-b64') !== undefined
    ? unb64(tagValue(tags, 'legacy-fix-b64'))
    : String(entry.rationale || '');
  const createdAt = tagValue(tags, 'legacy-created-at') || new Date(0).toISOString();
  const lastSeen = tagValue(tags, 'legacy-last-seen') || createdAt;
  const out = {
    id,
    pattern,
    fix,
    tier: tagValue(tags, 'legacy-tier') || entry.scope || 'project',
    created_at: createdAt,
    last_seen: lastSeen,
    hits: numberValue(tags, 'legacy-hits', 1),
    success_count: numberValue(tags, 'legacy-success-count', 0),
    failure_count: numberValue(tags, 'legacy-failure-count', 0),
    confidence: numberValue(tags, 'legacy-confidence', 0.5),
    ttl_days: numberValue(tags, 'legacy-ttl-days', 90),
    archived: boolValue(tags, 'legacy-archived', false),
    promotion_candidate: boolValue(tags, 'legacy-promotion-candidate', false)
  };
  const promotedAt = tagValue(tags, 'legacy-promoted-at');
  if (promotedAt) out.promoted_at = promotedAt;
  const archivedAt = tagValue(tags, 'legacy-archived-at');
  if (archivedAt) out.archived_at = archivedAt;
  return out;
}

function migrateReverse() {
  const source = filesCsv ? filesCsv.split(',').filter(Boolean)[0] : path.join(configDir, 'memory-v2.json');
  const outputPath = path.join(configDir, 'memory-v1.roundtrip.json');
  if (!source || !fs.existsSync(source)) {
    console.error(`${source || rel(path.join(configDir, 'memory-v2.json'))}: not found`);
    process.exit(1);
  }
  const data = readJsonArray(source);
  const roundtrip = data.map(toV1);
  if (dryRun) {
    console.log(`Would reverse ${roundtrip.length} v2 learning entries to ${rel(outputPath)}`);
    return;
  }
  ensureDir(configDir);
  fs.writeFileSync(outputPath, JSON.stringify(roundtrip, null, 2) + '\n');
  console.log(`Reversed ${roundtrip.length} v2 learning entries to ${rel(outputPath)}`);
}

try {
  if (reverse) {
    migrateReverse();
  } else {
    migrateForward();
  }
} catch (error) {
  console.error(error.message);
  process.exit(1);
}
JSEOF
}

_memory_compact() {
  node - \
    "$ROOT_DIR" \
    "$CONFIG_DIR" \
    "${OPT_DRY_RUN:-false}" <<'JSEOF'
const fs = require('fs');
const path = require('path');

const [,, rootDir, configDir, dryRunRaw] = process.argv;
const dryRun = dryRunRaw === 'true';
const storePath = path.join(configDir, 'memory-v2.json');
const backupRoot = path.join(configDir, 'memory.compact.bak');
const SIMHASH_BITS = 64;
const SIMILARITY_THRESHOLD = 0.85;
const STALE_DAYS = 30;

function rel(filePath) {
  const relative = path.relative(rootDir, filePath);
  return relative && !relative.startsWith('..') && !path.isAbsolute(relative)
    ? relative
    : filePath;
}

function readStore(filePath) {
  if (!fs.existsSync(filePath)) {
    throw new Error(`Memory v2 store not found: ${rel(filePath)}`);
  }
  const parsed = JSON.parse(fs.readFileSync(filePath, 'utf8'));
  if (!Array.isArray(parsed)) {
    throw new Error(`Memory v2 store must be an array: ${rel(filePath)}`);
  }
  return parsed;
}

function atomicWriteJson(filePath, data) {
  fs.mkdirSync(path.dirname(filePath), {recursive: true});
  const tmp = `${filePath}.tmp-${process.pid}-${Date.now()}`;
  fs.writeFileSync(tmp, JSON.stringify(data, null, 2) + '\n');
  fs.renameSync(tmp, filePath);
}

function backupStore(filePath) {
  const stamp = new Date().toISOString().replace(/[:.]/g, '-');
  const dir = path.join(backupRoot, stamp);
  fs.mkdirSync(dir, {recursive: true});
  fs.copyFileSync(filePath, path.join(dir, path.basename(filePath)));
  return dir;
}

function normalizeText(entry) {
  return String(entry && entry.insight ? entry.insight : '')
    .toLowerCase()
    .normalize('NFKD')
    .replace(/[\u0300-\u036f]/g, '')
    .replace(/[^a-z0-9]+/g, ' ')
    .replace(/\s+/g, ' ')
    .trim();
}

function tokensFor(text) {
  const words = text.split(/\s+/).filter(Boolean);
  if (words.length === 0) return [];
  const tokens = [...words];
  for (let index = 0; index < words.length - 1; index += 1) {
    tokens.push(`${words[index]} ${words[index + 1]}`);
  }
  return tokens;
}

function fnv1a64(value) {
  let hash = 0xcbf29ce484222325n;
  const prime = 0x100000001b3n;
  for (const byte of Buffer.from(value, 'utf8')) {
    hash ^= BigInt(byte);
    hash = (hash * prime) & 0xffffffffffffffffn;
  }
  return hash;
}

function simhash(entry) {
  const vector = Array(SIMHASH_BITS).fill(0);
  const tokens = tokensFor(normalizeText(entry));
  for (const token of tokens) {
    const hash = fnv1a64(token);
    for (let bit = 0; bit < SIMHASH_BITS; bit += 1) {
      vector[bit] += ((hash >> BigInt(bit)) & 1n) === 1n ? 1 : -1;
    }
  }
  let out = 0n;
  for (let bit = 0; bit < SIMHASH_BITS; bit += 1) {
    if (vector[bit] >= 0) out |= 1n << BigInt(bit);
  }
  return out;
}

function hammingDistance(left, right) {
  let value = left ^ right;
  let distance = 0;
  while (value > 0n) {
    distance += Number(value & 1n);
    value >>= 1n;
  }
  return distance;
}

function similarity(left, right) {
  return 1 - (hammingDistance(left, right) / SIMHASH_BITS);
}

function lexicalSimilarity(left, right) {
  const leftTokens = new Set(normalizeText(left).split(/\s+/).filter(Boolean));
  const rightTokens = new Set(normalizeText(right).split(/\s+/).filter(Boolean));
  if (leftTokens.size === 0 || rightTokens.size === 0) return 0;
  let intersection = 0;
  for (const token of leftTokens) {
    if (rightTokens.has(token)) intersection += 1;
  }
  const union = new Set([...leftTokens, ...rightTokens]).size;
  return union === 0 ? 0 : intersection / union;
}

function createdAt(entry) {
  if (entry && entry.created_at && !Number.isNaN(Date.parse(entry.created_at))) {
    return new Date(entry.created_at);
  }
  const match = String(entry && entry.id || '').match(/^lrn-(\d{4}-\d{2}-\d{2})-\d{3}$/);
  if (!match) return null;
  return new Date(`${match[1]}T00:00:00.000Z`);
}

function isStale(entry, now) {
  if (Number(entry && entry.applied_count || 0) !== 0) return false;
  const created = createdAt(entry);
  if (!created) return false;
  return (now.getTime() - created.getTime()) > (STALE_DAYS * 24 * 60 * 60 * 1000);
}

function preferred(left, right, leftIndex, rightIndex) {
  const leftCount = Number(left.applied_count || 0);
  const rightCount = Number(right.applied_count || 0);
  if (rightCount !== leftCount) return rightCount > leftCount ? 'right' : 'left';
  const idOrder = String(left.id || '').localeCompare(String(right.id || ''));
  if (idOrder !== 0) return idOrder <= 0 ? 'left' : 'right';
  return leftIndex <= rightIndex ? 'left' : 'right';
}

function compact(entries) {
  const now = new Date();
  const staleIds = new Set();
  const stale = [];
  entries.forEach((entry) => {
    if (isStale(entry, now)) {
      staleIds.add(entry.id);
      stale.push(entry.id);
    }
  });

  const survivors = entries
    .map((entry, index) => ({entry: {...entry}, index, hash: simhash(entry)}))
    .filter((item) => !staleIds.has(item.entry.id));

  const removedDuplicateIds = [];
  for (let i = 0; i < survivors.length; i += 1) {
    const current = survivors[i];
    if (!current || current.removed) continue;
    for (let j = i + 1; j < survivors.length; j += 1) {
      const candidate = survivors[j];
      if (!candidate || candidate.removed) continue;
      if (similarity(current.hash, candidate.hash) < SIMILARITY_THRESHOLD) continue;
      if (lexicalSimilarity(current.entry, candidate.entry) < SIMILARITY_THRESHOLD) continue;

      const keepRight = preferred(current.entry, candidate.entry, current.index, candidate.index) === 'right';
      const keep = keepRight ? candidate : current;
      const drop = keepRight ? current : candidate;
      keep.entry.applied_count = Number(keep.entry.applied_count || 0) + Number(drop.entry.applied_count || 0);
      const keepLast = keep.entry.last_applied ? Date.parse(keep.entry.last_applied) : 0;
      const dropLast = drop.entry.last_applied ? Date.parse(drop.entry.last_applied) : 0;
      if (dropLast > keepLast) keep.entry.last_applied = drop.entry.last_applied;
      drop.removed = true;
      removedDuplicateIds.push(drop.entry.id);
      if (keepRight) break;
    }
  }

  const compacted = survivors
    .filter((item) => !item.removed)
    .sort((a, b) => a.index - b.index)
    .map((item) => item.entry);

  return {
    compacted,
    duplicateIds: removedDuplicateIds.sort(),
    staleIds: stale.sort()
  };
}

try {
  const entries = readStore(storePath);
  const result = compact(entries);
  const changed = result.duplicateIds.length > 0 || result.staleIds.length > 0;
  const action = dryRun ? 'Would compact' : 'Compacted';
  const mergeVerb = dryRun ? 'merge' : 'merged';
  const dropVerb = dryRun ? 'drop' : 'dropped';

  if (!changed) {
    console.log('Memory compact: no changes');
    process.exit(0);
  }

  console.log(`${action} ${entries.length} Memory v2 learning entries`);
  console.log(`${mergeVerb} ${result.duplicateIds.length} duplicate learning(s)`);
  console.log(`${dropVerb} ${result.staleIds.length} stale learning(s)`);
  console.log(`result: ${result.compacted.length} entries`);
  if (result.duplicateIds.length > 0) console.log(`duplicates: ${result.duplicateIds.join(', ')}`);
  if (result.staleIds.length > 0) console.log(`stale: ${result.staleIds.join(', ')}`);

  if (dryRun) process.exit(0);
  const backupDir = backupStore(storePath);
  atomicWriteJson(storePath, result.compacted);
  console.log(`backup: ${rel(backupDir)}`);
} catch (error) {
  console.error(error.message);
  process.exit(1);
}
JSEOF
}

_memory_why() {
  node - \
    "$ROOT_DIR" \
    "$CONFIG_DIR" \
    "${OPT_MEMORY_ID:-}" \
    "${OPT_MEMORY_FORMAT:-text}" <<'JSEOF'
const fs = require('fs');
const path = require('path');

const [,, rootDir, configDir, requestedId, formatRaw] = process.argv;
const format = formatRaw || 'text';
const storePath = path.join(configDir, 'memory-v2.json');
const runsDir = path.join(configDir, 'runs');

function rel(filePath) {
  const relative = path.relative(rootDir, filePath);
  return relative && !relative.startsWith('..') && !path.isAbsolute(relative)
    ? relative
    : filePath;
}

function readMemoryStore() {
  if (!fs.existsSync(storePath)) return [];
  const parsed = JSON.parse(fs.readFileSync(storePath, 'utf8'));
  return Array.isArray(parsed) ? parsed : [parsed];
}

function walkFiles(dir, targetName, files = []) {
  if (!fs.existsSync(dir)) return files;
  for (const name of fs.readdirSync(dir).sort()) {
    const fullPath = path.join(dir, name);
    const stat = fs.statSync(fullPath);
    if (stat.isDirectory()) {
      walkFiles(fullPath, targetName, files);
    } else if (name === targetName) {
      files.push(fullPath);
    }
  }
  return files;
}

function applicationsFor(id) {
  const applications = [];
  for (const tracePath of walkFiles(runsDir, 'memory-injections.jsonl')) {
    const featureFromPath = path.basename(path.dirname(tracePath));
    const lines = fs.readFileSync(tracePath, 'utf8').split(/\n/).filter(Boolean);
    for (const line of lines) {
      let event;
      try {
        event = JSON.parse(line);
      } catch {
        continue;
      }
      if (!Array.isArray(event.learnings) || !event.learnings.includes(id)) continue;
      applications.push({
        run_id: event.run_id || event.runId || featureFromPath,
        feature_id: event.feature_id || event.featureId || featureFromPath,
        phase: event.phase || '',
        timestamp: event.timestamp || '',
        tokens: Number.isFinite(event.tokens) ? event.tokens : null
      });
    }
  }
  return applications
    .sort((a, b) => String(b.timestamp).localeCompare(String(a.timestamp)))
    .slice(0, 10);
}

function sourceLabel(entry) {
  const artifact = entry.source && entry.source.artifact ? entry.source.artifact : '';
  if (!artifact) return 'unknown';
  if (!process.stdout.isTTY) return artifact;
  const target = path.join(rootDir, artifact);
  return `\u001b]8;;file://${target}\u0007${artifact}\u001b]8;;\u0007`;
}

function suggestions(entries) {
  return [...entries]
    .sort((a, b) => {
      const countDiff = (Number(b.applied_count) || 0) - (Number(a.applied_count) || 0);
      return countDiff || String(a.id).localeCompare(String(b.id));
    })
    .slice(0, 10);
}

function emitJson(payload) {
  process.stdout.write(JSON.stringify(payload, null, 2) + '\n');
}

function printSuggestions(entries) {
  if (entries.length === 0) {
    console.log(`No Memory v2 store found at ${rel(storePath)}.`);
    console.log('Run monozukuri memory migrate or add .monozukuri/memory-v2.json.');
    return;
  }
  console.log('Most applied learnings:');
  for (const entry of suggestions(entries)) {
    console.log(`${entry.id} ${entry.applied_count || 0} ${entry.scope || 'unknown'} ${entry.insight || ''}`);
  }
}

function printEntry(entry, applications) {
  console.log(`ID: ${entry.id}`);
  console.log(`Insight: ${entry.insight || ''}`);
  console.log(`Scope: ${entry.scope || ''}`);
  console.log(`Source: ${sourceLabel(entry)}`);
  console.log(`Applied count: ${entry.applied_count || 0}`);
  console.log(`Last applied: ${entry.last_applied || 'never'}`);
  console.log('Applications:');
  if (applications.length === 0) {
    console.log('  none found in memory-injections.jsonl');
    return;
  }
  for (const app of applications) {
    const details = [
      `run_id=${app.run_id}`,
      `feature_id=${app.feature_id}`,
      app.phase ? `phase=${app.phase}` : '',
      app.timestamp ? `timestamp=${app.timestamp}` : ''
    ].filter(Boolean).join(' ');
    console.log(`  - ${details}`);
  }
}

try {
  const entries = readMemoryStore();
  if (format !== 'text' && format !== 'json') {
    console.error(`Unsupported memory why format: ${format}`);
    process.exit(1);
  }

  if (!requestedId) {
    const top = suggestions(entries);
    if (format === 'json') {
      emitJson({entries: top, applications: []});
    } else {
      printSuggestions(entries);
    }
    process.exit(0);
  }

  const entry = entries.find((candidate) => candidate.id === requestedId);
  if (!entry) {
    if (format === 'json') emitJson({error: 'learning_not_found', id: requestedId});
    else console.error(`Learning not found: ${requestedId}`);
    process.exit(1);
  }

  const applications = applicationsFor(requestedId);
  if (format === 'json') {
    emitJson({...entry, applications});
  } else {
    printEntry(entry, applications);
  }
} catch (error) {
  console.error(error.message);
  process.exit(1);
}
JSEOF
}

_memory_trace() {
  node - \
    "$ROOT_DIR" \
    "$CONFIG_DIR" \
    "${OPT_MEMORY_ID:-}" <<'JSEOF'
const fs = require('fs');
const path = require('path');

const [,, rootDir, configDir, runId] = process.argv;

if (!runId) {
  console.error('memory trace requires a run id');
  process.exit(2);
}

const tracePath = path.join(configDir, 'runs', runId, 'memory-trace.jsonl');
if (!fs.existsSync(tracePath)) {
  console.error(`memory trace not found: ${runId}`);
  process.exit(1);
}

function parseEvents(filePath) {
  return fs.readFileSync(filePath, 'utf8')
    .split(/\n/)
    .filter(Boolean)
    .map((line) => {
      try {
        return JSON.parse(line);
      } catch {
        return null;
      }
    })
    .filter(Boolean);
}

function ids(value) {
  return Array.isArray(value) ? value.filter(Boolean) : [];
}

function printSummary(event) {
  const included = ids(event.included);
  const omitted = ids(event.omitted);
  const phase = event.phase || 'unknown';
  const feature = event.feature_id || event.featureId || 'unknown';
  const tokens = Number.isFinite(event.tokens) ? event.tokens : 0;
  console.log(`  - ${phase} ${feature}: included=${included.length} omitted=${omitted.length} tokens=${tokens}`);
  if (included.length > 0) console.log(`    included: ${included.join(', ')}`);
  if (omitted.length > 0) console.log(`    omitted: ${omitted.join(', ')}`);
}

function printEscalation(event) {
  const phase = event.phase || 'unknown';
  const attempt = Number.isFinite(event.attempt) ? event.attempt : 0;
  const id = event.learning_id || event.id || 'unknown';
  if (event.event === 'escalation_requested') {
    console.log(`  - requested ${phase} attempt=${attempt} id=${id}`);
  } else if (event.event === 'escalation_granted') {
    const tokens = Number.isFinite(event.tokens) ? event.tokens : 0;
    console.log(`  - granted ${phase} attempt=${attempt} id=${id} tokens=${tokens}`);
  } else if (event.event === 'escalation_denied') {
    console.log(`  - denied ${phase} attempt=${attempt} id=${id} reason=${event.reason || 'unknown'}`);
  }
}

const events = parseEvents(tracePath);
const summaries = events.filter((event) => event.event === 'summarize');
const escalations = events.filter((event) =>
  event.event === 'escalation_requested' ||
  event.event === 'escalation_granted' ||
  event.event === 'escalation_denied'
);

console.log(`Memory trace: ${runId}`);
console.log('Summaries:');
if (summaries.length === 0) console.log('  none');
for (const event of summaries) printSummary(event);
console.log('Escalations:');
if (escalations.length === 0) console.log('  none');
for (const event of escalations) printEscalation(event);
JSEOF
}

sub_memory() {
  case "${OPT_MEMORY_ACTION:-}" in
    lint)
      _memory_lint
      ;;
    migrate)
      _memory_migrate
      ;;
    compact)
      _memory_compact
      ;;
    why)
      _memory_why
      ;;
    trace)
      _memory_trace
      ;;
    ""|--help|-h)
      echo "Usage:"
      echo "  monozukuri memory lint [file...]"
      echo "  monozukuri memory migrate [--dry-run] [--reverse]"
      echo "  monozukuri memory compact [--dry-run]"
      echo "  monozukuri memory why [lrn-id] [--format json]"
      echo "  monozukuri memory trace <run-id>"
      echo ""
      echo "Validate, migrate, or inspect Memory learning entries."
      ;;
    *)
      err "Unknown memory action: $OPT_MEMORY_ACTION"
      err "Available: lint, migrate, compact, why, trace"
      return 1
      ;;
  esac
}
