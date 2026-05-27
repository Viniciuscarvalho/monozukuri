#!/usr/bin/env node
/* MEM-05: local-only Sufficiency Router experiment harness. */

const fs = require('fs');
const os = require('os');
const path = require('path');
const {spawnSync} = require('child_process');

const repoRoot = path.resolve(__dirname, '../..');
const defaultOutDir = path.join(repoRoot, 'docs/experiments/sufficiency-router');
const strategies = ['inject-full', 'summary', 'on-demand'];
const phases = ['prd', 'techspec', 'tasks'];
const agents = ['claude-code', 'codex', 'gemini'];
const fixedFeatureIds = [
  'feat-node-001',
  'feat-node-004',
  'feat-py-004',
  'feat-go-004',
  'feat-go-005'
];

function parseArgs(argv) {
  const opts = {
    live: false,
    outDir: defaultOutDir,
    agents,
    strategies,
    phases,
    maxFeatures: 0,
    fakeBehavior: 'normal',
    timeoutMs: 180000
  };
  for (let i = 0; i < argv.length; i += 1) {
    const arg = argv[i];
    if (arg === '--live') opts.live = true;
    else if (arg === '--fake') opts.live = false;
    else if (arg === '--out-dir') opts.outDir = path.resolve(argv[++i]);
    else if (arg === '--agents') opts.agents = argv[++i].split(',').filter(Boolean);
    else if (arg === '--strategies') opts.strategies = argv[++i].split(',').filter(Boolean);
    else if (arg === '--phases') opts.phases = argv[++i].split(',').filter(Boolean);
    else if (arg === '--max-features') opts.maxFeatures = Number(argv[++i]);
    else if (arg === '--fake-behavior') opts.fakeBehavior = argv[++i];
    else if (arg === '--timeout-ms') opts.timeoutMs = Number(argv[++i]);
    else if (arg === '-h' || arg === '--help') {
      usage();
      process.exit(0);
    } else {
      throw new Error(`unknown argument: ${arg}`);
    }
  }
  for (const agent of opts.agents) {
    if (!agents.includes(agent)) throw new Error(`unsupported agent: ${agent}`);
  }
  for (const strategy of opts.strategies) {
    if (!strategies.includes(strategy)) throw new Error(`unsupported strategy: ${strategy}`);
  }
  for (const phase of opts.phases) {
    if (!phases.includes(phase)) throw new Error(`unsupported phase: ${phase}`);
  }
  return opts;
}

function usage() {
  console.log(`Usage:
  node scripts/experiments/sufficiency-router.js [--fake|--live] [options]

Options:
  --live                         Invoke real claude/codex/gemini CLIs
  --fake                         Use deterministic fake agents (default)
  --out-dir DIR                  Output directory (default docs/experiments/sufficiency-router)
  --agents a,b                   Agent list: claude-code,codex,gemini
  --strategies a,b               Strategy list: inject-full,summary,on-demand
  --phases p,q                   Phase list: prd,techspec,tasks
  --max-features N               Limit selected fixture features for fast tests
  --fake-behavior MODE           normal|escalate|invalid-summary
  --timeout-ms N                  Per-agent-call timeout in milliseconds
`);
}

function ensureDir(dir) {
  fs.mkdirSync(dir, {recursive: true});
}

function resetOutDir(dir) {
  const resolved = path.resolve(dir);
  if (!resolved.endsWith(path.normalize('sufficiency-router'))) {
    throw new Error(`refusing to reset unexpected output directory: ${resolved}`);
  }
  fs.rmSync(resolved, {recursive: true, force: true});
  ensureDir(resolved);
}

function writeFile(file, content) {
  ensureDir(path.dirname(file));
  fs.writeFileSync(file, content);
}

function estimateTokens(text) {
  return Math.max(0, Math.ceil(Buffer.byteLength(String(text || ''), 'utf8') / 4));
}

function parseFeatureMarkdown(file, stack) {
  const content = fs.readFileSync(file, 'utf8');
  const lines = content.split(/\n/);
  const out = [];
  let current = null;
  for (const line of lines) {
    const match = line.match(/^##\s+([^:]+):\s+(.+)$/);
    if (match) {
      if (current) out.push(finalizeFeature(current));
      current = {
        id: match[1].trim(),
        title: match[2].trim(),
        descriptionLines: [],
        stack,
        source: path.relative(repoRoot, file)
      };
      continue;
    }
    if (!current) continue;
    if (/^Status:\s*/.test(line)) {
      current.status = line.replace(/^Status:\s*/, '').trim();
    } else {
      current.descriptionLines.push(line);
    }
  }
  if (current) out.push(finalizeFeature(current));
  return out;
}

function finalizeFeature(feature) {
  return {
    id: feature.id,
    title: feature.title,
    description: feature.descriptionLines.join('\n').trim(),
    status: feature.status || 'backlog',
    stack: feature.stack,
    source: feature.source
  };
}

function loadFeatures(opts) {
  const sources = [
    ['node', '.qa/fixtures/scale/node/features.md'],
    ['python', '.qa/fixtures/scale/python/features.md'],
    ['go', '.qa/fixtures/scale/go/features.md']
  ];
  const all = sources.flatMap(([stack, rel]) => parseFeatureMarkdown(path.join(repoRoot, rel), stack));
  let selected = fixedFeatureIds.map((id) => {
    const feature = all.find((candidate) => candidate.id === id);
    if (!feature) throw new Error(`fixed feature not found in fixtures: ${id}`);
    return feature;
  });
  if (opts.maxFeatures > 0) selected = selected.slice(0, opts.maxFeatures);
  return selected;
}

function memoryEntriesFor(feature) {
  const date = '2026-05-25';
  const stackTag = feature.stack;
  return [
    {
      id: `lrn-${date}-101`,
      scope: 'project',
      insight: 'Prefer public CLI behavior tests for orchestrator changes.',
      rationale: 'Bats through orchestrate.sh catches parser and dispatch regressions that unit tests miss.',
      source: {feature_id: 'MEM-04', phase: 'tests', run_id: 'manual', artifact: 'test/integration/memory_why.bats'},
      applied_count: 8,
      last_applied: '2026-05-24T21:00:00.000Z',
      promoted_from: 'manual',
      agent_specific: null,
      tags: ['testing', 'cli', stackTag]
    },
    {
      id: `lrn-${date}-102`,
      scope: 'project',
      insight: 'Keep live-agent experiments local-only and outside CI.',
      rationale: 'Monozukuri release gates must preserve the zero-cost CI contract.',
      source: {feature_id: 'ADR-019', phase: 'techspec', run_id: 'manual', artifact: 'docs/test-strategy.md'},
      applied_count: 5,
      last_applied: '2026-05-24T20:00:00.000Z',
      promoted_from: 'manual',
      agent_specific: null,
      tags: ['cost', 'ci', 'experiment']
    },
    {
      id: `lrn-${date}-103`,
      scope: 'global',
      insight: 'Use schema validation pass rate as the quality proxy for replay experiments.',
      rationale: 'The validator is deterministic and maps directly to whether the next phase can proceed.',
      source: {feature_id: 'MEM-05', phase: 'prd', run_id: 'manual', artifact: 'lib/schema/validate.sh'},
      applied_count: 3,
      last_applied: '2026-05-25T00:00:00.000Z',
      promoted_from: 'manual',
      agent_specific: null,
      tags: ['quality', 'schema', stackTag]
    },
    {
      id: `lrn-${date}-104`,
      scope: 'project',
      insight: `For ${feature.stack} features, keep file changes narrow and name likely entry points explicitly.`,
      rationale: 'Narrow file maps reduce over-editing in autonomous phases.',
      source: {feature_id: feature.id, phase: 'techspec', run_id: 'fixture', artifact: feature.source},
      applied_count: 2,
      last_applied: null,
      promoted_from: 'auto_detected',
      agent_specific: null,
      tags: [stackTag, 'file-map']
    },
    {
      id: `lrn-${date}-105`,
      scope: 'project',
      insight: 'Codex and Gemini need schemas inline because they do not receive worktree schema injection.',
      rationale: 'Rendered-prompt adapters cannot rely on Claude-style local schema files.',
      source: {feature_id: 'F1', phase: 'code', run_id: 'manual', artifact: 'lib/prompt/render.sh'},
      applied_count: 4,
      last_applied: null,
      promoted_from: 'manual',
      agent_specific: null,
      tags: ['codex', 'gemini', 'schema']
    }
  ];
}

function chooseRelevantForEscalation(entries, agent, limit = 3) {
  return [...entries]
    .sort((a, b) => {
      const agentA = a.agent_specific === agent ? 0 : 1;
      const agentB = b.agent_specific === agent ? 0 : 1;
      const scopeRank = {feature: 0, project: 1, global: 2};
      return agentA - agentB ||
        (scopeRank[a.scope] ?? 9) - (scopeRank[b.scope] ?? 9) ||
        (Number(b.applied_count) || 0) - (Number(a.applied_count) || 0) ||
        String(a.id).localeCompare(String(b.id));
    })
    .slice(0, limit);
}

function renderMemory(strategy, entries, agent, escalatedIds = []) {
  if (strategy === 'inject-full' || escalatedIds.length > 0) {
    const selected = escalatedIds.length > 0
      ? entries.filter((entry) => escalatedIds.includes(entry.id))
      : entries;
    return selected.map((entry) => [
      `- id: ${entry.id}`,
      `  insight: ${entry.insight}`,
      `  rationale: ${entry.rationale}`,
      `  scope: ${entry.scope}`,
      `  source: ${entry.source.artifact}#${entry.source.feature_id}/${entry.source.phase}`,
      `  agent_specific: ${entry.agent_specific || 'any'}`,
      `  tags: ${(entry.tags || []).join(',')}`
    ].join('\n')).join('\n');
  }

  const summary = entries.map((entry) => `- ${entry.id}: ${entry.insight}`).join('\n');
  if (strategy === 'on-demand') {
    return `${summary}

If this summary is insufficient, print exactly:
MEMORY_ESCALATE: <comma-separated-learning-ids>
Do not invent IDs. Continue only if the summary is enough.`;
  }
  return summary;
}

function phaseInstructions(phase) {
  if (phase === 'prd') {
    return `Return a PRD markdown artifact with these top-level headings:
## Problem
## Solution
## Success criteria
## Functional requirements
## Out of scope`;
  }
  if (phase === 'techspec') {
    return `Return a TechSpec markdown artifact with these top-level headings:
## Approach
## File change map
## Components
## Testing
The File change map section must contain at least one markdown list item.`;
  }
  return `Return only a JSON array of task objects. Each task must include:
id, title, description, files_touched, acceptance_criteria.`;
}

function renderPrompt({agent, strategy, phase, feature, entries, escalatedIds = []}) {
  const memoryBlock = renderMemory(strategy, entries, agent, escalatedIds);
  return `You are running the MEM-05 sufficiency-router experiment.

Agent under test: ${agent}
Strategy under test: ${strategy}
Feature: ${feature.id} - ${feature.title}
Stack: ${feature.stack}
Description:
${feature.description}

Memory context:
${memoryBlock}

${phaseInstructions(phase)}

Output only the requested artifact unless you need on-demand memory escalation.`;
}

function fakeOutput({phase, feature, behavior, strategy, attempt, entries}) {
  if (strategy === 'on-demand' && attempt === 1 && behavior === 'escalate') {
    return {
      stdout: `MEMORY_ESCALATE: ${entries[0].id},${entries[1].id}\n`,
      stderr: '',
      status: 0
    };
  }
  if (strategy === 'on-demand' && attempt === 1 && behavior === 'invalid-summary') {
    return {
      stdout: '## Partial\nMissing the required sections.\n',
      stderr: '',
      status: 0
    };
  }
  if (phase === 'prd') {
    return {
      stdout: `# PRD - ${feature.id}

## Problem

${feature.title} is not implemented yet, which blocks users from relying on this capability.

## Solution

Implement the smallest deterministic behavior that satisfies the feature request for ${feature.stack}.

## Success criteria

| Criterion | How verified |
| --- | --- |
| Feature works | Run the relevant project tests |

## Functional requirements

- The implementation covers ${feature.description.replace(/\n+/g, ' ')}

## Out of scope

- Unrelated refactors
`,
      stderr: '',
      status: 0
    };
  }
  if (phase === 'techspec') {
    return {
      stdout: `# TechSpec - ${feature.id}

## Approach

Follow existing ${feature.stack} entrypoints and keep the implementation narrow.

## File change map

- src/${feature.stack}/app

## Components

- Feature handler
- Tests

## Testing

- Run the project test command.
`,
      stderr: '',
      status: 0
    };
  }
  return {
    stdout: JSON.stringify([
      {
        id: 'task-001',
        title: `Implement ${feature.title}`,
        description: `Build the behavior requested by ${feature.id}.`,
        files_touched: [`src/${feature.stack}/app`],
        acceptance_criteria: ['The generated implementation passes the project tests.']
      }
    ], null, 2) + '\n',
    stderr: '',
    status: 0
  };
}

function liveCommand(agent) {
  if (agent === 'claude-code') return ['claude', ['--print']];
  if (agent === 'codex') return ['codex', ['exec', '--skip-git-repo-check', '--sandbox', 'workspace-write', '-']];
  if (agent === 'gemini') return ['gemini', ['--yolo', 'false', '-']];
  throw new Error(`unsupported live agent: ${agent}`);
}

function invokeAgent({agent, prompt, phase, feature, strategy, attempt, entries, opts}) {
  const start = Date.now();
  if (!opts.live) {
    const result = fakeOutput({phase, feature, behavior: opts.fakeBehavior, strategy, attempt, entries});
    return {...result, latency_ms: Math.max(1, Date.now() - start)};
  }

  const [bin, args] = liveCommand(agent);
  const cwd = fs.mkdtempSync(path.join(os.tmpdir(), `mz-sufficiency-${agent}-`));
  const result = spawnSync(bin, args, {
    input: prompt,
    cwd,
    encoding: 'utf8',
    timeout: Number(process.env.SUFFICIENCY_ROUTER_TIMEOUT_MS || opts.timeoutMs || 180000),
    maxBuffer: 1024 * 1024 * 20
  });
  fs.rmSync(cwd, {recursive: true, force: true});
  const latency = Math.max(1, Date.now() - start);
  if (result.error) {
    return {
      stdout: result.stdout || '',
      stderr: `${result.stderr || ''}\n${result.error.message}`,
      status: result.status || 1,
      latency_ms: latency
    };
  }
  return {
    stdout: result.stdout || '',
    stderr: result.stderr || '',
    status: result.status || 0,
    latency_ms: latency
  };
}

function artifactName(phase) {
  return phase === 'tasks' ? 'tasks.json' : `${phase}.md`;
}

function validateArtifact(phase, artifactPath) {
  const command = `source "${path.join(repoRoot, 'lib/schema/validate.sh')}"; schema_validate "${phase}" "${artifactPath}"`;
  const result = spawnSync('bash', ['-lc', command], {
    cwd: repoRoot,
    encoding: 'utf8',
    env: {...process.env, MONOZUKURI_HOME: repoRoot}
  });
  return {
    valid: result.status === 0,
    error: result.status === 0 ? '' : (result.stderr || result.stdout || '').trim()
  };
}

function parseEscalationIds(stdout) {
  const match = String(stdout || '').match(/MEMORY_ESCALATE:\s*([A-Za-z0-9_.:,\-\s]+)/);
  if (!match) return [];
  return match[1].split(/[,\s]+/).map((id) => id.trim()).filter(Boolean);
}

function writeAttemptFiles(baseDir, phase, label, prompt, result, artifactContent) {
  const prefix = label ? `${phase}.${label}` : phase;
  writeFile(path.join(baseDir, `${prefix}.prompt.md`), prompt);
  writeFile(path.join(baseDir, `${prefix}.stdout.txt`), result.stdout);
  writeFile(path.join(baseDir, `${prefix}.stderr.txt`), result.stderr);
  writeFile(path.join(baseDir, `${prefix}.artifact.${phase === 'tasks' ? 'json' : 'md'}`), artifactContent);
}

function runOne({agent, strategy, phase, feature, opts}) {
  const entries = memoryEntriesFor(feature);
  const rawDir = path.join(opts.outDir, 'raw', agent, strategy, feature.id);
  ensureDir(rawDir);

  let attempts = 1;
  let inputTokens = 0;
  let outputTokens = 0;
  let latency = 0;
  let escalated = false;
  let escalationReason = '';
  let prompt = renderPrompt({agent, strategy, phase, feature, entries});
  inputTokens += estimateTokens(prompt);
  let result = invokeAgent({agent, prompt, phase, feature, strategy, attempt: 1, entries, opts});
  outputTokens += estimateTokens(result.stdout);
  latency += result.latency_ms;
  let artifactContent = result.stdout;
  writeAttemptFiles(rawDir, phase, '', prompt, result, artifactContent);

  let artifactPath = path.join(rawDir, artifactName(phase));
  writeFile(artifactPath, artifactContent);
  let validation = validateArtifact(phase, artifactPath);

  if (strategy === 'on-demand') {
    let ids = parseEscalationIds(result.stdout);
    if (ids.length > 0 || !validation.valid) {
      escalated = true;
      escalationReason = ids.length > 0 ? 'requested_ids' : 'schema_invalid';
      if (ids.length === 0) ids = chooseRelevantForEscalation(entries, agent, 3).map((entry) => entry.id);
      attempts = 2;
      const escalatedPrompt = renderPrompt({agent, strategy, phase, feature, entries, escalatedIds: ids});
      inputTokens += estimateTokens(escalatedPrompt);
      const escalatedResult = invokeAgent({
        agent,
        prompt: escalatedPrompt,
        phase,
        feature,
        strategy,
        attempt: 2,
        entries,
        opts: {...opts, fakeBehavior: opts.fakeBehavior === 'invalid-summary' ? 'normal' : opts.fakeBehavior}
      });
      outputTokens += estimateTokens(escalatedResult.stdout);
      latency += escalatedResult.latency_ms;
      artifactContent = escalatedResult.stdout;
      writeAttemptFiles(rawDir, phase, 'escalated', escalatedPrompt, escalatedResult, artifactContent);
      writeFile(artifactPath, artifactContent);
      validation = validateArtifact(phase, artifactPath);
      result = escalatedResult;
    }
  }

  const record = {
    agent,
    strategy,
    feature_id: feature.id,
    phase,
    input_tokens: inputTokens,
    output_tokens_estimated: outputTokens,
    total_tokens_estimated: inputTokens + outputTokens,
    latency_ms: latency,
    schema_valid: validation.valid,
    schema_error: validation.error,
    escalated,
    escalation_reason: escalationReason,
    attempts,
    exit_code: result.status
  };
  writeFile(path.join(rawDir, `${phase}.metrics.json`), JSON.stringify(record, null, 2) + '\n');
  return record;
}

function aggregate(runs) {
  const out = {};
  for (const run of runs) {
    out[run.agent] ||= {};
    out[run.agent][run.strategy] ||= {
      runs: 0,
      schema_valid_count: 0,
      total_tokens_estimated: 0,
      latency_ms: 0,
      escalations: 0
    };
    const item = out[run.agent][run.strategy];
    item.runs += 1;
    item.schema_valid_count += run.schema_valid ? 1 : 0;
    item.total_tokens_estimated += run.total_tokens_estimated;
    item.latency_ms += run.latency_ms;
    item.escalations += run.escalated ? 1 : 0;
  }
  for (const agentName of Object.keys(out)) {
    for (const strategyName of Object.keys(out[agentName])) {
      const item = out[agentName][strategyName];
      item.schema_pass_rate = item.runs ? Number((item.schema_valid_count / item.runs).toFixed(4)) : 0;
      item.avg_total_tokens_estimated = item.runs ? Number((item.total_tokens_estimated / item.runs).toFixed(2)) : 0;
      item.avg_latency_ms = item.runs ? Number((item.latency_ms / item.runs).toFixed(2)) : 0;
    }
  }
  return out;
}

function decide(aggregates) {
  let cWinningAgents = 0;
  const agentDecisions = {};
  for (const agentName of Object.keys(aggregates)) {
    const perStrategy = aggregates[agentName];
    const c = perStrategy['on-demand'];
    if (!c) continue;
    const values = Object.values(perStrategy);
    const bestPass = Math.max(...values.map((item) => item.schema_pass_rate));
    const bestTokens = Math.min(...values.map((item) => item.avg_total_tokens_estimated));
    const bestLatency = Math.min(...values.map((item) => item.avg_latency_ms));
    const winningMetrics = [];
    if (c.schema_pass_rate === bestPass) winningMetrics.push('schema_pass_rate');
    if (c.avg_total_tokens_estimated === bestTokens) winningMetrics.push('total_tokens');
    if (c.avg_latency_ms === bestLatency) winningMetrics.push('latency');
    const wins = winningMetrics.length > 0;
    if (wins) cWinningAgents += 1;
    agentDecisions[agentName] = {wins, winning_metrics: winningMetrics};
  }
  return {
    strategy_c_winning_agents: cWinningAgents,
    proceed: cWinningAgents >= 2,
    agent_decisions: agentDecisions
  };
}

function writeCsv(outDir, runs) {
  const header = [
    'agent',
    'strategy',
    'feature_id',
    'phase',
    'input_tokens',
    'output_tokens_estimated',
    'total_tokens_estimated',
    'latency_ms',
    'schema_valid',
    'escalated',
    'attempts'
  ];
  const rows = runs.map((run) => header.map((key) => String(run[key] ?? '')).join(','));
  writeFile(path.join(outDir, 'results.csv'), `${header.join(',')}\n${rows.join('\n')}\n`);
}

function writeReadme(outDir, opts, decision) {
  writeFile(path.join(outDir, 'README.md'), `# Sufficiency Router Experiment

Generated by \`scripts/experiments/sufficiency-router.js\`.

## Method

The harness compares three Memory v2 injection strategies across Claude Code,
Codex, and Gemini using five fixed features from the existing scale fixtures.
It runs the PRD, TechSpec, and Tasks phases and validates artifacts with
\`lib/schema/validate.sh\`.

## Strategies

- \`inject-full\`: inject all eligible learning details.
- \`summary\`: inject compact learning summaries only.
- \`on-demand\`: start with summaries and escalate once when the agent requests
  \`MEMORY_ESCALATE:\` IDs or when schema validation fails.

## Commands

\`\`\`bash
node scripts/experiments/sufficiency-router.js --fake
node scripts/experiments/sufficiency-router.js --live --agents claude-code,codex,gemini
\`\`\`

Fake mode is deterministic and intended for CI-free review. Live mode is
local-only and may spend model tokens; CI must not run it. A full live replay
runs 3 agents x 3 strategies x 5 features x 3 phases, plus at most one
additional call for each on-demand escalation.

## Expected Cost

The harness estimates input and output tokens for every run and stores the
values in \`results.csv\` and \`results.json\`. Before running live replay,
inspect the planned matrix with \`--fake\` and narrow it with \`--agents\`,
\`--strategies\`, \`--phases\`, or \`--max-features\` when doing smoke checks.

## Interpretation

\`schema_valid\` is the quality proxy for MEM-05. Strategy C is considered a
candidate for production only when it wins or ties for best score in at least
one metric for at least two agents. The metrics are lower
\`total_tokens_estimated\`, lower \`latency_ms\`, and higher schema validation
pass rate.

## Decision Snapshot

- Mode: ${opts.live ? 'live' : 'fake'}
- C winning agents: ${decision.strategy_c_winning_agents}
- Proceed with production router: ${decision.proceed}
`);
}

function writeResults(outDir, opts, runs, final = false) {
  const aggregates = aggregate(runs);
  const decision = decide(aggregates);
  writeCsv(outDir, runs);
  writeFile(path.join(outDir, 'results.json'), JSON.stringify({
    generated_at: new Date().toISOString(),
    status: final ? 'complete' : 'partial',
    mode: opts.live ? 'live' : 'fake',
    agents: opts.agents,
    strategies: opts.strategies,
    phases: opts.phases,
    runs,
    aggregates,
    decision
  }, null, 2) + '\n');
  writeReadme(outDir, opts, decision);
  return decision;
}

function main() {
  const opts = parseArgs(process.argv.slice(2));
  resetOutDir(opts.outDir);
  const features = loadFeatures(opts);
  writeFile(path.join(opts.outDir, 'features.json'), JSON.stringify(features, null, 2) + '\n');

  const runs = [];
  const totalRuns = opts.agents.length * opts.strategies.length * features.length * opts.phases.length;
  let completedRuns = 0;
  for (const agent of opts.agents) {
    for (const strategy of opts.strategies) {
      for (const feature of features) {
        for (const phase of opts.phases) {
          completedRuns += 1;
          process.stderr.write(`[${completedRuns}/${totalRuns}] ${agent}/${strategy}/${feature.id}/${phase}\n`);
          runs.push(runOne({agent, strategy, phase, feature, opts}));
          writeResults(opts.outDir, opts, runs, false);
        }
      }
    }
  }

  const decision = writeResults(opts.outDir, opts, runs, true);

  console.log(`Wrote sufficiency-router experiment results to ${path.relative(repoRoot, opts.outDir) || opts.outDir}`);
  console.log(`C winning agents: ${decision.strategy_c_winning_agents}; proceed=${decision.proceed}`);
}

try {
  main();
} catch (error) {
  console.error(error.message);
  process.exit(1);
}
