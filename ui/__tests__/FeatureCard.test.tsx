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
