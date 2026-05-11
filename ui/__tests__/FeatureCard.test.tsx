import React from 'react';
import { render } from 'ink-testing-library';
import { FeatureCard } from '../src/components/FeatureCard.js';
import type { Feature, Phase, PhaseStatus } from '../src/types.js';

const pendingPhases: Record<Phase, PhaseStatus> = {
  prd: 'pending', techspec: 'pending', tasks: 'pending',
  code: 'pending', tests: 'pending', pr: 'pending',
};

const activeFeature: Feature = {
  id: 'feat-001',
  title: 'Add login page',
  status: 'active',
  phases: { ...pendingPhases, prd: 'done', techspec: 'in_progress' },
  currentPhase: 'techspec',
  tokens: 1500,
  estimatedTokens: 4000,
  startedAt: '2026-04-27T10:00:00Z',
};

const deferredFeature: Feature = {
  id: 'feat-002',
  title: 'Refactor auth',
  status: 'deferred',
  phases: pendingPhases,
  error: 'size gate exceeded',
};

describe('FeatureCard', () => {
  const now = new Date('2026-04-27T10:01:30Z');

  it('renders waiting state for null feature', () => {
    const { lastFrame } = render(<FeatureCard feature={null} spinner="" now={now} />);
    expect(lastFrame() ?? '').toContain('waiting');
  });

  it('renders active feature title and id', () => {
    const { lastFrame } = render(<FeatureCard feature={activeFeature} spinner="" now={now} />);
    const frame = lastFrame() ?? '';
    expect(frame).toContain('feat-001');
    expect(frame).toContain('Add login page');
  });

  it('renders elapsed time for active feature', () => {
    const { lastFrame } = render(<FeatureCard feature={activeFeature} spinner="" now={now} />);
    expect(lastFrame() ?? '').toContain('elapsed:');
  });

  it('renders token count', () => {
    const { lastFrame } = render(<FeatureCard feature={activeFeature} spinner="" now={now} />);
    expect(lastFrame() ?? '').toContain('tokens:');
    // formatTokens rounds 1500 → 2k
    expect(lastFrame() ?? '').toContain('2k');
  });

  it('renders phase timeline', () => {
    const { lastFrame } = render(<FeatureCard feature={activeFeature} spinner="" now={now} />);
    expect(lastFrame() ?? '').toContain('◐');
  });

  it('renders deferred feature with reason', () => {
    const { lastFrame } = render(<FeatureCard feature={deferredFeature} spinner="" now={now} />);
    const frame = lastFrame() ?? '';
    expect(frame).toContain('feat-002');
    expect(frame).toContain('deferred');
    expect(frame).toContain('size gate exceeded');
  });

  it('renders spinner text when provided', () => {
    const { lastFrame } = render(
      <FeatureCard feature={activeFeature} spinner="Implementing src/auth.ts" now={now} />
    );
    expect(lastFrame() ?? '').toContain('Implementing');
  });
});

describe('FeatureCard — Day 4 telemetry', () => {
  const now = new Date('2026-05-11T10:00:30Z');

  const featureWithTelemetry: Feature = {
    id: 'feat-001',
    title: 'API endpoint',
    status: 'active',
    phases: { ...pendingPhases, code: 'in_progress' },
    currentPhase: 'code',
    tokensOut: 1840,
    tokenRate: 4200,
    estimatedTokens: 5000,
    startedAt: '2026-05-11T10:00:00Z',
    recentEvents: [
      { ts: new Date('2026-05-11T10:00:10Z').getTime(), tool: 'Read',  target: 'src/index.ts' },
      { ts: new Date('2026-05-11T10:00:20Z').getTime(), tool: 'Edit',  target: 'src/api.ts' },
      { ts: new Date('2026-05-11T10:00:28Z').getTime(), tool: 'Bash',  target: 'npm test' },
    ],
  };

  it('renders live tokensOut from phase.token_update', () => {
    const { lastFrame } = render(<FeatureCard feature={featureWithTelemetry} spinner="" now={now} />);
    const frame = lastFrame() ?? '';
    // formatTokens(1840) → "2k"
    expect(frame).toContain('2k');
  });

  it('renders tokens/min rate when tokenRate is set', () => {
    const { lastFrame } = render(<FeatureCard feature={featureWithTelemetry} spinner="" now={now} />);
    // formatRate(4200) → "4.2k/min"
    expect(lastFrame() ?? '').toContain('4.2k/min');
  });

  it('omits rate when tokenRate is undefined', () => {
    const f = { ...featureWithTelemetry, tokenRate: undefined };
    const { lastFrame } = render(<FeatureCard feature={f} spinner="" now={now} />);
    expect(lastFrame() ?? '').not.toContain('/min');
  });

  it('renders recent activity tree with last 3 events', () => {
    const { lastFrame } = render(<FeatureCard feature={featureWithTelemetry} spinner="" now={now} />);
    const frame = lastFrame() ?? '';
    expect(frame).toContain('recent activity');
    expect(frame).toContain('Read');
    expect(frame).toContain('Edit');
    expect(frame).toContain('Bash');
    expect(frame).toContain('└─'); // last tree branch
    expect(frame).toContain('├─'); // intermediate branches
  });

  it('omits recent activity section when no events present', () => {
    const f = { ...featureWithTelemetry, recentEvents: [] };
    const { lastFrame } = render(<FeatureCard feature={f} spinner="" now={now} />);
    expect(lastFrame() ?? '').not.toContain('recent activity');
  });

  it('falls back to legacy tokens field when tokensOut absent', () => {
    const f: Feature = {
      ...featureWithTelemetry,
      tokensOut: undefined,
      tokens: 1500, // legacy field
    };
    const { lastFrame } = render(<FeatureCard feature={f} spinner="" now={now} />);
    expect(lastFrame() ?? '').toContain('2k'); // formatTokens(1500) → 2k
  });
});
