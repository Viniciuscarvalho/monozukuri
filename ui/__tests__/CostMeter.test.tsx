import React from 'react';
import { render } from 'ink-testing-library';
import { CostMeter } from '../src/components/CostMeter.js';

describe('CostMeter', () => {
  it('renders zero cost', () => {
    const { lastFrame } = render(
      <CostMeter completed={0} total={5} costUsd={0} budget={40} width={80} />
    );
    const frame = lastFrame() ?? '';
    expect(frame).toContain('0 / 5');
    expect(frame).toContain('$0.00 / $40.00 budget');
  });

  it('renders partial cost', () => {
    const { lastFrame } = render(
      <CostMeter completed={2} total={5} costUsd={8.5} budget={40} width={80} />
    );
    const frame = lastFrame() ?? '';
    expect(frame).toContain('2 / 5');
    expect(frame).toContain('$8.50');
  });

  it('renders over-budget state', () => {
    const { lastFrame } = render(
      <CostMeter completed={5} total={5} costUsd={50} budget={40} width={80} />
    );
    const frame = lastFrame() ?? '';
    expect(frame).toContain('5 / 5');
    expect(frame).toContain('$50.00 / $40.00 budget');
  });

  it('renders filled bar when complete', () => {
    const { lastFrame } = render(
      <CostMeter completed={3} total={3} costUsd={15} budget={40} width={80} />
    );
    const frame = lastFrame() ?? '';
    expect(frame).toContain('█');
    expect(frame).toContain('3 / 3');
  });

  it('renders empty bar when no progress', () => {
    const { lastFrame } = render(
      <CostMeter completed={0} total={10} costUsd={0} budget={40} width={80} />
    );
    const frame = lastFrame() ?? '';
    expect(frame).toContain('░');
  });
});
