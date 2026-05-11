import React from 'react';
import { render } from 'ink-testing-library';
import { Header } from '../src/components/Header.js';
import { Footer } from '../src/components/Footer.js';
import { FeatureCard } from '../src/components/FeatureCard.js';
import { FeatureList } from '../src/components/FeatureList.js';
import { initialState } from '../src/reducer.js';
import type { Feature, Phase, PhaseStatus } from '../src/types.js';

// Day-5 plan: lock in the visual output of major TUI components via
// ink-testing-library's lastFrame(). These guard against unintended
// regressions when refactoring tokens / spacing / borders. To intentionally
// update a snapshot, eyeball the new frame first, then run with -u.

const pendingPhases: Record<Phase, PhaseStatus> = {
  prd: 'pending', techspec: 'pending', tasks: 'pending',
  code: 'pending', tests: 'pending', pr: 'pending',
};

const NOW = new Date('2026-05-11T10:00:30Z');

describe('snapshots — Header', () => {
  const baseState = {
    ...initialState(),
    runId: 'abc123def456',
    agent: 'claude-code',
    model: 'claude-sonnet-4-6',
    autonomy: 'checkpoint',
    source: 'markdown',
  };

  it('renders default header at width=80', () => {
    const { lastFrame } = render(<Header state={baseState} terminalWidth={80} />);
    expect(lastFrame()).toMatchSnapshot();
  });

  it('renders header at width=120 (wide terminal)', () => {
    const { lastFrame } = render(<Header state={baseState} terminalWidth={120} />);
    expect(lastFrame()).toMatchSnapshot();
  });
});

describe('snapshots — Footer', () => {
  it('renders minimal 3-key footer at width=80', () => {
    const { lastFrame } = render(<Footer terminalWidth={80} />);
    expect(lastFrame()).toMatchSnapshot();
  });

  it('does not include verbose keybindings (l/f/search) after Day 5 trim', () => {
    const { lastFrame } = render(<Footer terminalWidth={80} />);
    const frame = lastFrame() ?? '';
    expect(frame).toContain('q quit');
    expect(frame).toContain('p pause');
    expect(frame).toContain('? help');
    // Verbose keys deferred to a future help-overlay PR
    expect(frame).not.toContain('learnings');
    expect(frame).not.toContain('filter');
    expect(frame).not.toContain('search');
  });
});

describe('snapshots — FeatureCard', () => {
  it('renders waiting card when feature is null', () => {
    const { lastFrame } = render(<FeatureCard feature={null} spinner="" now={NOW} />);
    expect(lastFrame()).toMatchSnapshot();
  });

  it('renders active feature with tokensOut, rate, and activity tree', () => {
    const f: Feature = {
      id: 'feat-005',
      title: 'Add greeting API endpoint',
      status: 'active',
      phases: {
        ...pendingPhases,
        prd: 'done', techspec: 'done', tasks: 'done', code: 'in_progress',
      },
      currentPhase: 'code',
      tokensOut: 1840,
      tokenRate: 4200,
      estimatedTokens: 5000,
      startedAt: '2026-05-11T10:00:00Z',
      recentEvents: [
        { ts: new Date('2026-05-11T10:00:10Z').getTime(), tool: 'Read', target: 'src/index.ts' },
        { ts: new Date('2026-05-11T10:00:20Z').getTime(), tool: 'Edit', target: 'src/api.ts' },
        { ts: new Date('2026-05-11T10:00:28Z').getTime(), tool: 'Bash', target: 'npm test' },
      ],
    };
    const { lastFrame } = render(<FeatureCard feature={f} spinner="" now={NOW} />);
    expect(lastFrame()).toMatchSnapshot();
  });

  it('renders deferred feature without telemetry', () => {
    const f: Feature = {
      id: 'feat-009',
      title: 'Refactor auth module',
      status: 'deferred',
      phases: pendingPhases,
      error: 'size gate exceeded — 1200 LOC > 800 cap',
    };
    const { lastFrame } = render(<FeatureCard feature={f} spinner="" now={NOW} />);
    expect(lastFrame()).toMatchSnapshot();
  });
});

describe('snapshots — FeatureList', () => {
  it('renders a small backlog with mixed statuses', () => {
    const list: Feature[] = [
      { id: 'feat-001', title: 'Add error logging', status: 'done', phases: pendingPhases, costUsd: 0.42 },
      { id: 'feat-002', title: 'Add input validation', status: 'done', phases: pendingPhases, costUsd: 0.38 },
      { id: 'feat-003', title: 'Add greeting custom', status: 'active', phases: pendingPhases, costUsd: 1.84 },
      { id: 'feat-004', title: 'Add config loading',  status: 'queued', phases: pendingPhases },
    ];
    const features = Object.fromEntries(list.map((f) => [f.id, f]));
    const order = list.map((f) => f.id);
    const { lastFrame } = render(<FeatureList features={features} order={order} />);
    expect(lastFrame()).toMatchSnapshot();
  });
});
